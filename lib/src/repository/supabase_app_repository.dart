import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../birthday.dart';
import '../friend_stats_profile.dart';
import '../models.dart';
import '../time_zone_provider.dart';
import 'app_repository.dart';

// AppRepository backed by Supabase (Postgres + Auth + Storage + Realtime +
// Edge Functions). Business logic that must be trusted/consistent (friend
// graph mutations, cheers, feed assembly) is pushed into Postgres RPCs
// rather than done client-side, so it stays correct under concurrent
// clients and enforced by RLS instead of duplicated/trusted here.
class SupabaseAppRepository implements AppRepository {
  SupabaseAppRepository(
    this._client, {
    Uuid? uuid,
    TimeZoneProvider? timeZoneProvider,
  }) : _uuid = uuid ?? const Uuid(),
       _timeZoneProvider = timeZoneProvider ?? const PlatformTimeZoneProvider();

  static const _mediaBucket = 'user-media';

  final SupabaseClient _client;
  final Uuid _uuid;
  final TimeZoneProvider _timeZoneProvider;

  // Shared/constant stack trace for realtime subscription errors: there is
  // no meaningful call stack to report for an async channel-status callback,
  // and using a fixed empty trace makes these errors easy to assert on in
  // tests without generating a real stack.
  @visibleForTesting
  static const notificationSubscriptionErrorStackTrace = StackTrace.empty;

  @override
  String get backendLabel => 'Supabase';

  @override
  bool get usesRemoteBackend => true;

  @override
  Future<AppUser?> restoreSession({bool forceRefresh = false}) async {
    try {
      final authUser = await _restoreAuthUser(forceRefresh: forceRefresh);
      if (authUser == null) {
        return null;
      }
      return await _ensureProfile(authUser);
    } on AuthException catch (error) {
      // Only swallow "no/invalid session" as a normal signed-out result
      // when the caller explicitly asked to force a refresh — a refresh
      // failing because the session is gone just means the user isn't
      // signed in anymore, not an error to surface.
      if (forceRefresh && _isMissingOrInvalidSession(error)) {
        return null;
      }
      throw AppException(error.message);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) async {
    try {
      final trimmedProfileImagePath = profileImagePath?.trim();
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'display_name': displayName.trim(),
          if (birthday != null) 'birthday': _toDateString(birthday),
          // Local file paths/data URIs can't be stored in auth metadata
          // (only meaningful once uploaded to Storage below), so only a
          // path that's already a remote URL is worth persisting here.
          if (_shouldPersistAuthMetadataImagePath(trimmedProfileImagePath))
            'profile_image_path': trimmedProfileImagePath,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AppException('Sign-up did not return a user.');
      }

      // With email confirmation enabled, Supabase returns a user but no
      // session until the email link is clicked — surface that distinctly
      // so the UI can prompt to check email instead of treating this as a
      // generic sign-up failure.
      if (response.session == null) {
        throw const AppException(
          'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.',
        );
      }

      var profile = await _ensureProfile(
        user,
        preferredDisplayName: displayName.trim(),
        preferredBirthday: birthday,
        preferredProfileImagePath: trimmedProfileImagePath,
      );
      // If a local image was supplied, it still needs to be uploaded to
      // Storage via updateProfile (which _ensureProfile can't do, since it
      // only writes DB rows) — only do this extra round trip when the image
      // actually needs uploading or didn't already match what was saved.
      if (trimmedProfileImagePath != null &&
          trimmedProfileImagePath.isNotEmpty &&
          (_looksLikeLocalFile(trimmedProfileImagePath) ||
              trimmedProfileImagePath != profile.profileImagePath)) {
        profile = await updateProfile(
          profile.copyWith(profileImagePath: trimmedProfileImagePath),
        );
      }
      return profile;
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppException('The email or password is incorrect.');
      }
      return _ensureProfile(user);
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> changePassword({
    required AppUser user,
    required String currentPassword,
    required String newPassword,
  }) async {
    // Supabase's updateUser doesn't require re-authentication, so the
    // current password is verified explicitly via a fresh sign-in first —
    // otherwise anyone with a live session (e.g. an unlocked device) could
    // change the password without knowing the old one.
    try {
      final response = await _client.auth.signInWithPassword(
        email: user.email.trim(),
        password: currentPassword,
      );
      if (response.user == null) {
        throw const AppException('The current password is incorrect.');
      }
    } on AuthException catch (error) {
      if (_isInvalidLoginCredentials(error)) {
        throw const AppException('The current password is incorrect.');
      }
      throw AppException(error.message);
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    try {
      // Captured before overwriting so the old image can be cleaned up
      // afterwards — but only once the new profile row has been committed,
      // so a failure partway through never leaves the profile pointing at
      // an image that was already deleted.
      final previousProfile = await _loadProfile(
        user.id,
        fallbackEmail: user.email,
      );
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: user.profileImagePath,
        folder: 'profiles',
      );

      // Auth metadata is updated in addition to the profiles table so that
      // display name/image are available immediately from the JWT/session
      // (e.g. right after sign-up, before a profiles row read) without an
      // extra DB round trip.
      await _client.auth.updateUser(
        UserAttributes(
          data: <String, dynamic>{
            'display_name': user.displayName,
            'birthday': user.birthday == null
                ? null
                : _toDateString(user.birthday!),
            'profile_image_path': finalImagePath,
          },
        ),
      );

      final row = await _client
          .from('profiles')
          .upsert(<String, dynamic>{
            'id': user.id,
            'email': user.email,
            'display_name': user.displayName,
            'birthday': user.birthday == null
                ? null
                : _toDateString(user.birthday!),
            'profile_image_path': finalImagePath,
          }, onConflict: 'id')
          .select()
          .single();

      final updatedProfile = _profileToUser(
        Map<String, dynamic>.from(row),
        userId: user.id,
        email: user.email,
      );
      // Delete the old image only after the new profile is durably saved,
      // and only if it actually changed — deleting eagerly could orphan the
      // profile pointing at a missing image if the upsert above had failed.
      if (previousProfile?.profileImagePath != finalImagePath) {
        await _deleteMediaPathIfOwned(
          previousProfile?.profileImagePath,
          user.id,
        );
      }
      return updatedProfile;
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> deleteAccount(AppUser user) async {
    // Account deletion (auth user + all owned rows/storage) requires the
    // service role, which the client can never hold, so it's delegated to
    // a server-side Edge Function instead of being expressed as client
    // calls here.
    try {
      await _client.functions.invoke('delete-account', method: HttpMethod.post);
    } on FunctionException catch (error) {
      throw AppException(
        error.reasonPhrase ?? 'The account could not be deleted.',
      );
    }

    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      // The Edge Function likely already invalidated the session as part of
      // deleting the account, so signOut failing is expected/harmless in
      // that case; only treat it as a real error if a session is still
      // present (meaning something else went wrong).
      if (_client.auth.currentSession != null) {
        throw AppException(error.message);
      }
    }
  }

  @override
  Future<List<FriendConnection>> loadFriendConnections(
    String userId, {
    bool forceRefresh = false,
  }) async {
    // An RPC (not a direct table select) because each relationship row must
    // be joined against whichever side ISN'T the caller and have its
    // direction (incoming/outgoing) computed relative to the caller — logic
    // that's awkward/unsafe to express as a client-side filtered select
    // under RLS, so it's centralized in Postgres.
    try {
      final rows = await _client.rpc('load_friend_connections');
      return (rows as List<dynamic>)
          .map(
            (row) =>
                _friendConnectionFromRow(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<FriendProfile> getOwnFriendProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return _profileRowToFriendProfile(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<FriendStatsProfile> loadFriendStatsProfile({
    required String userId,
    required String friendUserId,
  }) async {
    try {
      // Stats must be bucketed into the *viewer's* local days/timezone
      // (e.g. "drinks today"), which Postgres can't infer on its own, so
      // the client's offset/timezone are sent explicitly to the function
      // doing the aggregation.
      final utcOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final timeZone = await _timeZoneProvider.getLocalTimeZoneIdentifier();
      final response = await _client.functions.invoke(
        'friend-shared-profile',
        method: HttpMethod.post,
        body: <String, dynamic>{
          'friendUserId': friendUserId.trim(),
          'utcOffsetMinutes': utcOffsetMinutes,
          'timeZone': ?timeZone,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const AppException('This friend profile is unavailable.');
      }
      return FriendStatsProfile.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (error) {
      // 404 (no such friend) and 403 (not actually friends / stats sharing
      // disabled) are collapsed to the same generic message deliberately —
      // distinguishing them would leak whether a user id/relationship
      // exists to someone who isn't authorized to know.
      if (error.status == 404) {
        throw const AppException('This friend profile is unavailable.');
      }
      if (error.status == 403) {
        throw const AppException('This friend profile is unavailable.');
      }
      throw AppException(
        error.reasonPhrase ?? 'This friend profile is unavailable.',
      );
    }
  }

  @override
  Future<PublicFriendProfile> resolvePublicFriendProfileLink(
    String shareCode,
  ) async {
    final normalizedCode = shareCode.trim();
    if (normalizedCode.isEmpty) {
      throw const AppException('The profile link is invalid.');
    }

    try {
      // GET (rather than the RPC used by resolveFriendProfileLink) because
      // this same Edge Function endpoint also serves HTML/OpenGraph
      // previews for unauthenticated link shares (crawlers, chat unfurls);
      // format=json asks it for the same data this client needs instead.
      final response = await _client.functions.invoke(
        'friend-profile-preview/${Uri.encodeComponent(normalizedCode)}',
        method: HttpMethod.get,
        queryParameters: const <String, String>{'format': 'json'},
      );
      final data = response.data;
      if (data is! Map) {
        throw const AppException('The profile link is invalid.');
      }
      return PublicFriendProfile.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (error) {
      if (error.status == 404) {
        throw const AppException('The profile link is invalid.');
      }
      throw AppException(error.reasonPhrase ?? 'The profile link is invalid.');
    }
  }

  @override
  Future<FriendProfile> resolveFriendProfileLink(String shareCode) async {
    try {
      final rows = await _client.rpc(
        'resolve_friend_profile_link',
        params: <String, dynamic>{'target_share_code': shareCode.trim()},
      );
      final list = List<dynamic>.from(rows as List);
      if (list.isEmpty) {
        throw const AppException('The profile link is invalid.');
      }
      return _profileRowToFriendProfile(
        Map<String, dynamic>.from(list.single as Map),
      );
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  // This and the friend-request mutation RPCs below (accept/reject/cancel/
  // remove) all re-fetch the full connection list afterwards instead of
  // patching a local copy: the RPC is the only place that knows the
  // resulting status/direction for every affected row (including the other
  // party's), so refetching is simpler and less error-prone than trying to
  // predict server-side effects client-side.
  @override
  Future<List<FriendConnection>> sendFriendRequestToProfile({
    required String userId,
    required String shareCode,
  }) async {
    try {
      await _client.rpc(
        'send_friend_request_to_profile',
        params: <String, dynamic>{'target_share_code': shareCode.trim()},
      );
      return loadFriendConnections(userId);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<FriendConnection>> acceptFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    try {
      await _client.rpc(
        'accept_friend_request',
        params: <String, dynamic>{'target_relationship_id': relationshipId},
      );
      return loadFriendConnections(userId);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<FriendConnection>> rejectFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    try {
      await _client.rpc(
        'reject_friend_request',
        params: <String, dynamic>{'target_relationship_id': relationshipId},
      );
      return loadFriendConnections(userId);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<FriendConnection>> cancelFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    try {
      await _client.rpc(
        'cancel_friend_request',
        params: <String, dynamic>{'target_relationship_id': relationshipId},
      );
      return loadFriendConnections(userId);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<FriendConnection>> removeFriend({
    required String userId,
    required String friendUserId,
  }) async {
    try {
      await _client.rpc(
        'remove_friend',
        params: <String, dynamic>{'target_friend_user_id': friendUserId},
      );
      return loadFriendConnections(userId);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<AppNotification>> loadNotifications(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final rows = await _client.rpc('load_notifications');
      return (rows as List<dynamic>)
          .map(
            (row) =>
                AppNotification.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<AppNotification>> markNotificationsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    if (notificationIds.isEmpty) {
      return loadNotifications(userId);
    }

    try {
      final rows = await _client.rpc(
        'mark_notifications_read',
        params: <String, dynamic>{'notification_ids': notificationIds},
      );
      return (rows as List<dynamic>)
          .map(
            (row) =>
                AppNotification.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    late final StreamController<List<AppNotification>> controller;
    Future<void> Function()? stopWatchingNotifications;
    // Guards every async callback (realtime events, in-flight loads) from
    // touching the controller after onCancel has run, since those
    // callbacks can still fire after cancellation due to network latency.
    var isClosed = false;

    // Realtime only tells us *that* something changed on the notifications
    // table, not the resulting row (it's filtered/RLS-shaped server-side),
    // so each change event triggers a full reload via the RPC rather than
    // trying to apply a diff from the raw postgres_changes payload.
    Future<void> publishSnapshot() async {
      if (isClosed) {
        return;
      }
      try {
        final notifications = await loadNotifications(userId);
        if (!isClosed) {
          controller.add(notifications);
        }
      } on Object catch (error, stackTrace) {
        if (!isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<AppNotification>>.broadcast(
      onListen: () {
        stopWatchingNotifications = startWatchingNotifications(
          userId: userId,
          publishSnapshot: publishSnapshot,
          publishError: (error, stackTrace) {
            if (!isClosed) {
              controller.addError(error, stackTrace);
            }
          },
        );
      },
      onCancel: () async {
        isClosed = true;
        final stopWatching = stopWatchingNotifications;
        if (stopWatching != null) {
          await stopWatching();
        }
      },
    );
    return controller.stream;
  }

  // Extracted as its own (testable) method so tests can drive the
  // subscribe callback/publishSnapshot without needing a real Supabase
  // realtime connection.
  @visibleForTesting
  Future<void> Function() startWatchingNotifications({
    required String userId,
    required Future<void> Function() publishSnapshot,
    required void Function(Object error, StackTrace stackTrace) publishError,
  }) {
    final channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          // Filtered server-side to this recipient even though RLS would
          // already prevent seeing other users' rows — without this filter
          // every notifications-table change on the server would still
          // trigger a reload here, wastefully re-fetching on unrelated
          // activity.
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_user_id',
            value: userId,
          ),
          callback: (_) => unawaited(publishSnapshot()),
        );

    channel.subscribe((status, [error]) {
      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          // Fetch once immediately on subscribe: postgres_changes only
          // reports changes that happen *after* subscribing, so without
          // this the stream would stay empty until the next mutation.
          unawaited(publishSnapshot());
          break;
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          publishError(
            error ?? Exception('Notification realtime subscription failed.'),
            notificationSubscriptionErrorStackTrace,
          );
          break;
        case RealtimeSubscribeStatus.closed:
          break;
      }
    });

    return () => _client.removeChannel(channel);
  }

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    try {
      await _client.rpc(
        'register_notification_device_token',
        params: <String, dynamic>{
          'device_token': token.trim(),
          'device_platform': platform.trim(),
        },
      );
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _client.rpc(
        'unregister_notification_device_token',
        params: <String, dynamic>{'device_token': token.trim()},
      );
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog({
    bool forceRefresh = false,
  }) async {
    try {
      final rows = await _client
          .from('global_drinks')
          .select()
          .order('category_slug')
          .order('name_en');

      final drinks = (rows as List<dynamic>)
          .map(
            (row) =>
                _globalDrinkToDefinition(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      // Falls back to the bundled catalog both on query failure and on an
      // empty (but successful) result — the latter covers a freshly seeded
      // or misconfigured `global_drinks` table, so the app never shows an
      // empty drink picker.
      if (drinks.isEmpty) {
        return buildDefaultDrinkCatalog();
      }
      return drinks;
    } on PostgrestException {
      return buildDefaultDrinkCatalog();
    }
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final rows = await _client
          .from('user_drinks')
          .select()
          .eq('user_id', userId)
          .order('name');

      return (rows as List<dynamic>)
          .map(
            (row) =>
                _userDrinkToDefinition(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    bool isAlcoholFree = false,
    String? imagePath,
  }) async {
    try {
      // drinkId is only present when editing an existing custom drink; a
      // fresh uuid means this is a create, so there's no previous image to
      // look up or later clean up.
      final id = drinkId ?? _uuid.v4();
      final previousImagePath = await _loadCustomDrinkImagePath(
        userId: userId,
        drinkId: drinkId,
      );
      final finalImagePath = await _resolveMediaPath(
        userId: userId,
        imagePath: imagePath,
        folder: 'custom-drinks',
      );

      final row = await _client
          .from('user_drinks')
          .upsert(<String, dynamic>{
            'id': id,
            'user_id': userId,
            'name': name.trim(),
            'category_slug': category.storageValue,
            'volume_ml': volumeMl,
            'is_alcohol_free': _customDrinkAlcoholFreeValue(
              category,
              isAlcoholFree,
            ),
            'image_path': finalImagePath,
          }, onConflict: 'id')
          .select()
          .single();

      if (previousImagePath != finalImagePath) {
        await _deleteMediaPathIfOwned(previousImagePath, userId);
      }

      return _userDrinkToDefinition(Map<String, dynamic>.from(row));
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  }) async {
    try {
      final rows = await _client
          .from('user_drinks')
          .delete()
          .eq('id', drink.id)
          .eq('user_id', userId)
          .select('id');

      if ((rows as List<dynamic>).isEmpty) {
        throw const AppException('The custom drink could not be deleted.');
      }

      await _deleteMediaPathIfOwned(drink.imagePath, userId);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<DrinkEntry>> loadEntries(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final rows = await _client
          .from('drink_entries')
          .select()
          .eq('user_id', userId)
          .order('consumed_at', ascending: false);

      return (rows as List<dynamic>)
          .map((row) => _entryFromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<FeedDrinkPostPage> loadFeedDrinkPosts({
    required String userId,
    FeedDrinkPostCursor? cursor,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final pageLimit = limit.clamp(1, 50).toInt();
      final params = <String, dynamic>{
        'page_limit': pageLimit,
        if (cursor != null) ...<String, dynamic>{
          'cursor_consumed_at': cursor.consumedAt.toUtc().toIso8601String(),
          'cursor_id': cursor.entryId,
        },
      };
      final rows = await _client.rpc('load_feed_drink_posts', params: params);
      final posts = (rows as List<dynamic>)
          .map((row) => _feedPostFromRow(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      final hasMore = posts.length > pageLimit;
      final pagePosts = posts.take(pageLimit).toList(growable: false);
      return FeedDrinkPostPage(
        posts: pagePosts,
        cursor: hasMore && pagePosts.isNotEmpty ? pagePosts.last.cursor : null,
        hasMore: hasMore,
      );
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<FeedEntryCheersUpdate> setFeedEntryCheers({
    required String userId,
    required String entryId,
    required bool shouldCheer,
  }) async {
    try {
      final rows = await _client.rpc(
        'set_feed_entry_cheers',
        params: <String, dynamic>{
          'target_entry_id': entryId,
          'should_cheer': shouldCheer,
        },
      );
      final decoded = (rows as List<dynamic>)
          .map((row) {
            return Map<String, dynamic>.from(row as Map);
          })
          .toList(growable: false);
      if (decoded.isEmpty) {
        throw const AppException('The cheers could not be updated.');
      }
      return _feedEntryCheersUpdateFromRow(decoded.first);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    DateTime? consumedAt,
    String? importSource,
    String? importSourceId,
  }) async {
    try {
      final trimmedImportSource = importSource?.trim();
      final trimmedImportSourceId = importSourceId?.trim();
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: imagePath,
        folder: 'entries',
      );

      final row = await _client
          .from('drink_entries')
          .insert(<String, dynamic>{
            'id': _uuid.v4(),
            'user_id': user.id,
            'source_type': drink.isCustom ? 'custom' : 'global',
            'source_drink_id': drink.id,
            // drink_name/category_slug are denormalized (copied) onto the
            // entry rather than only referenced by source_drink_id, so a
            // logged entry keeps showing its original drink even if the
            // custom drink it pointed to is later renamed or deleted.
            'drink_name': drink.name,
            'category_slug': drink.category.storageValue,
            'volume_ml': volumeMl,
            'is_alcohol_free': drink.isEffectivelyAlcoholFree,
            'comment': comment?.trim().isEmpty ?? true ? null : comment?.trim(),
            'image_path': finalImagePath,
            'location_latitude': locationLatitude,
            'location_longitude': locationLongitude,
            'location_address': _normalizeLocationAddress(locationAddress),
            'import_source': trimmedImportSource,
            'import_source_id': trimmedImportSourceId,
            'consumed_at': (consumedAt ?? DateTime.now())
                .toUtc()
                .toIso8601String(),
          })
          .select()
          .single();

      return _entryFromRow(Map<String, dynamic>.from(row));
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      // A DB-level unique constraint on (import_source, import_source_id)
      // prevents re-importing the same external entry twice (e.g. retrying
      // a bulk import); surface that specific case with a clearer message
      // instead of a generic constraint-violation error.
      if (_isDuplicateImportConflict(
        error,
        importSource: importSource,
        importSourceId: importSourceId,
      )) {
        throw const AppException('This BeerWithMe entry was already imported.');
      }
      throw AppException(error.message);
    }
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    DrinkDefinition? replacementDrink,
    double? volumeMl,
    String? comment,
    String? imagePath,
  }) async {
    try {
      final trimmedComment = comment?.trim();
      final trimmedImagePath = imagePath?.trim();
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: trimmedImagePath,
        folder: 'entries',
      );
      final body = <String, dynamic>{
        'comment': trimmedComment == null || trimmedComment.isEmpty
            ? null
            : trimmedComment,
        'image_path': finalImagePath,
      };
      if (replacementDrink != null) {
        body.addAll(<String, dynamic>{
          'source_type': replacementDrink.isCustom ? 'custom' : 'global',
          'source_drink_id': replacementDrink.id,
          'drink_name': replacementDrink.name,
          'category_slug': replacementDrink.category.storageValue,
          'is_alcohol_free': replacementDrink.isEffectivelyAlcoholFree,
          'volume_ml': volumeMl,
        });
      }

      final row = await _client
          .from('drink_entries')
          .update(body)
          .eq('id', entry.id)
          .eq('user_id', user.id)
          .select()
          .maybeSingle();

      if (row == null) {
        throw const AppException('The drink entry could not be updated.');
      }

      if (entry.imagePath != finalImagePath) {
        await _deleteMediaPathIfOwned(entry.imagePath, user.id);
      }

      return _entryFromRow(Map<String, dynamic>.from(row));
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) async {
    try {
      final rows = await _client
          .from('drink_entries')
          .delete()
          .eq('id', entry.id)
          .eq('user_id', userId)
          .select('id');

      if ((rows as List<dynamic>).isEmpty) {
        throw const AppException('The drink entry could not be deleted.');
      }

      await _deleteMediaPathIfOwned(entry.imagePath, userId);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<UserSettings> loadSettings(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final row = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        return UserSettings.defaults();
      }
      return UserSettings.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<UserSettings> saveSettings(
    String userId,
    UserSettings settings,
  ) async {
    try {
      final row = await _client
          .from('user_settings')
          .upsert(<String, dynamic>{
            'user_id': userId,
            'theme_preference': settings.themePreference.storageValue,
            'locale_code': settings.localeCode,
            'unit': settings.unit.storageValue,
            'handedness': settings.handedness.storageValue,
            'share_stats_with_friends': settings.shareStatsWithFriends,
            'hidden_global_drink_ids': settings.hiddenGlobalDrinkIds,
            'hidden_global_drink_categories': settings
                .hiddenGlobalDrinkCategories
                .map((category) => category.storageValue)
                .toList(growable: false),
            'global_drink_order_overrides': <String, List<String>>{
              for (final entry in settings.globalDrinkOrderOverrides.entries)
                entry.key.storageValue: entry.value.toList(growable: false),
            },
          }, onConflict: 'user_id')
          .select()
          .single();

      return UserSettings.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  // Bridges Supabase Auth (which knows the user exists) and the app's own
  // `profiles`/`user_settings` tables (which may not have rows yet — e.g.
  // first sign-in after a new auth user was created, or a profile row
  // that's missing for any other reason). Called on every sign-in/sign-up/
  // restore so the app never has to special-case "authenticated but no
  // profile row yet".
  Future<AppUser> _ensureProfile(
    User authUser, {
    String? preferredDisplayName,
    DateTime? preferredBirthday,
    String? preferredProfileImagePath,
  }) async {
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing != null) {
      await _ensureSettingsRow(authUser.id);
      return _profileToUser(
        Map<String, dynamic>.from(existing),
        userId: authUser.id,
        email: authUser.email ?? '',
      );
    }

    final metadata = Map<String, dynamic>.from(
      authUser.userMetadata ?? const <String, dynamic>{},
    );
    final row = await _client
        .from('profiles')
        .insert(<String, dynamic>{
          'id': authUser.id,
          'email': authUser.email,
          // Falls back through explicit sign-up input, then whatever a
          // third-party auth provider (e.g. OAuth) may have put in
          // metadata, and finally derives something from the email so a
          // profile is never created with a blank name.
          'display_name':
              preferredDisplayName ??
              (metadata['display_name'] as String?) ??
              (metadata['nickname'] as String?) ??
              _fallbackDisplayName(authUser.email),
          'birthday': preferredBirthday == null
              ? metadata['birthday']
              : _toDateString(preferredBirthday),
          'profile_image_path':
              preferredProfileImagePath ??
              (metadata['profile_image_path'] as String?),
        })
        .select()
        .single();

    await _ensureSettingsRow(authUser.id);
    return _profileToUser(
      Map<String, dynamic>.from(row),
      userId: authUser.id,
      email: authUser.email ?? '',
    );
  }

  // ignoreDuplicates makes this safe to call unconditionally on every
  // sign-in (see _ensureProfile) without overwriting settings a returning
  // user has already customized — it only inserts defaults the first time
  // a settings row doesn't exist.
  Future<void> _ensureSettingsRow(String userId) async {
    await _client
        .from('user_settings')
        .upsert(
          <String, dynamic>{
            'user_id': userId,
            'theme_preference': AppThemePreference.system.storageValue,
            'locale_code': 'en',
            'unit': AppUnit.ml.storageValue,
            'handedness': AppHandedness.right.storageValue,
            'share_stats_with_friends': true,
            'hidden_global_drink_ids': const <String>[],
            'global_drink_order_overrides': const <String, List<String>>{},
          },
          onConflict: 'user_id',
          ignoreDuplicates: true,
        );
  }

  Future<AppUser?> _loadProfile(
    String userId, {
    required String fallbackEmail,
  }) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return _profileToUser(
      Map<String, dynamic>.from(row),
      userId: userId,
      email: fallbackEmail,
    );
  }

  AppUser _profileToUser(
    Map<String, dynamic> row, {
    required String userId,
    required String email,
  }) {
    final birthdayRaw = row['birthday'];
    return AppUser(
      id: userId,
      email: (row['email'] as String?) ?? email,
      displayName:
          (row['display_name'] as String?) ??
          (row['nickname'] as String?) ??
          _fallbackDisplayName(email),
      profileImagePath: row['profile_image_path'] as String?,
      birthday: normalizeBirthdayOrNull(
        birthdayRaw == null ? null : DateTime.parse(birthdayRaw as String),
      ),
      profileShareCode: row['profile_share_code'] as String?,
    );
  }

  FriendConnection _friendConnectionFromRow(Map<String, dynamic> row) {
    return FriendConnection(
      id: row['relationship_id'] as String,
      profile: _profileRowToFriendProfile(row),
      status: FriendRequestStatusX.fromStorage(row['status'] as String),
      direction: FriendRequestDirectionX.fromStorage(
        row['direction'] as String?,
      ),
    );
  }

  FriendProfile _profileRowToFriendProfile(Map<String, dynamic> row) {
    return FriendProfile(
      id: (row['profile_id'] as String?) ?? (row['id'] as String),
      email: row['email'] as String,
      displayName:
          (row['display_name'] as String?) ??
          _fallbackDisplayName(row['email'] as String?),
      profileImagePath: row['profile_image_path'] as String?,
      profileShareCode: row['profile_share_code'] as String?,
    );
  }

  DrinkDefinition _globalDrinkToDefinition(Map<String, dynamic> row) {
    return DrinkDefinition(
      id: row['id'] as String,
      name: row['name_en'] as String,
      localizedNameDe: row['name_de'] as String?,
      category: DrinkCategoryX.fromStorage(row['category_slug'] as String),
      volumeMl: (row['default_volume_ml'] as num?)?.toDouble(),
      isAlcoholFree: row['is_alcohol_free'] == true,
    );
  }

  DrinkDefinition _userDrinkToDefinition(Map<String, dynamic> row) {
    return DrinkDefinition(
      id: row['id'] as String,
      name: row['name'] as String,
      category: DrinkCategoryX.fromStorage(row['category_slug'] as String),
      volumeMl: (row['volume_ml'] as num?)?.toDouble(),
      isAlcoholFree: row['is_alcohol_free'] == true,
      imagePath: row['image_path'] as String?,
      ownerUserId: row['user_id'] as String?,
    );
  }

  DrinkEntry _entryFromRow(Map<String, dynamic> row) {
    return DrinkEntry(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      drinkId: row['source_drink_id'] as String,
      drinkName: row['drink_name'] as String,
      category: DrinkCategoryX.fromStorage(row['category_slug'] as String),
      consumedAt: DateTime.parse(row['consumed_at'] as String).toLocal(),
      volumeMl: (row['volume_ml'] as num?)?.toDouble(),
      isAlcoholFree: row['is_alcohol_free'] == true,
      comment: row['comment'] as String?,
      imagePath: row['image_path'] as String?,
      locationLatitude: (row['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (row['location_longitude'] as num?)?.toDouble(),
      locationAddress: row['location_address'] as String?,
      importSource: row['import_source'] as String?,
      importSourceId: row['import_source_id'] as String?,
    );
  }

  FeedDrinkPost _feedPostFromRow(Map<String, dynamic> row) {
    final authorProfile = FriendProfile(
      id: row['author_profile_id'] as String,
      email: (row['author_email'] as String?) ?? '',
      displayName:
          (row['author_display_name'] as String?) ??
          _fallbackDisplayName(row['author_email'] as String?),
      profileImagePath: row['author_profile_image_path'] as String?,
      profileShareCode: row['author_profile_share_code'] as String?,
    );
    return FeedDrinkPost(
      entry: _entryFromRow(row),
      authorProfile: authorProfile,
      isOwnEntry: row['is_own_entry'] == true,
      cheersCount: (row['cheers_count'] as num?)?.toInt() ?? 0,
      hasCurrentUserCheered: row['has_current_user_cheered'] == true,
    );
  }

  FeedEntryCheersUpdate _feedEntryCheersUpdateFromRow(
    Map<String, dynamic> row,
  ) {
    return FeedEntryCheersUpdate(
      cheersCount: (row['cheers_count'] as num?)?.toInt() ?? 0,
      hasCurrentUserCheered: row['has_current_user_cheered'] == true,
    );
  }

  bool _customDrinkAlcoholFreeValue(
    DrinkCategory category,
    bool isAlcoholFree,
  ) {
    return switch (category) {
      DrinkCategory.nonAlcoholic => true,
      DrinkCategory.beer => isAlcoholFree,
      _ => false,
    };
  }

  // Postgrest doesn't expose which unique constraint was violated in a
  // structured way, so this checks the Postgres unique_violation code
  // (23505) plus a substring match on the constraint name that Postgres
  // includes in the message/details — the only reliable way to distinguish
  // "duplicate import" from any other unique-constraint conflict.
  bool _isDuplicateImportConflict(
    PostgrestException error, {
    required String? importSource,
    required String? importSourceId,
  }) {
    final normalizedSource = importSource?.trim();
    final normalizedSourceId = importSourceId?.trim();
    if (normalizedSource == null ||
        normalizedSource.isEmpty ||
        normalizedSourceId == null ||
        normalizedSourceId.isEmpty) {
      return false;
    }

    final message = error.message.toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();
    return error.code == '23505' &&
        (message.contains('import_source') ||
            details.contains('import_source'));
  }

  // GoTrue doesn't expose a typed "wrong password" error, so this matches
  // on the known message text to distinguish it from other auth failures
  // (network errors, rate limiting, etc.) that shouldn't be reported as
  // "incorrect password".
  bool _isInvalidLoginCredentials(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('invalid login credentials') ||
        message.contains('invalid credentials');
  }

  Future<User?> _restoreAuthUser({required bool forceRefresh}) async {
    if (!forceRefresh) {
      return _client.auth.currentUser;
    }
    // Avoid calling refreshSession without a session present: it throws
    // rather than returning null, so this checks first to make "signed
    // out" a normal (non-exceptional) code path.
    if (_client.auth.currentSession == null) {
      return null;
    }
    final response = await _client.auth.refreshSession();
    return response.user ?? response.session?.user ?? _client.auth.currentUser;
  }

  // Used by restoreSession to decide whether a refresh failure means
  // "cleanly signed out" (expected, return null) vs. a real error worth
  // surfacing (e.g. network failure, which is excluded below via
  // AuthRetryableFetchException).
  bool _isMissingOrInvalidSession(AuthException error) {
    if (error is AuthSessionMissingException ||
        error is AuthInvalidJwtException) {
      return true;
    }
    if (error is AuthRetryableFetchException) {
      return false;
    }
    final message = error.message.toLowerCase();
    return error.code == 'invalid_grant' ||
        error.code == 'session_not_found' ||
        message.contains('refresh token') ||
        message.contains('invalid grant') ||
        message.contains('session expired') ||
        message.contains('invalid jwt');
  }

  Future<String?> _loadCustomDrinkImagePath({
    required String userId,
    required String? drinkId,
  }) async {
    if (drinkId == null) {
      return null;
    }

    final row = await _client
        .from('user_drinks')
        .select('image_path')
        .eq('id', drinkId)
        .eq('user_id', userId)
        .maybeSingle();

    final imagePath = (row?['image_path'] as String?)?.trim();
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    return imagePath;
  }

  // Callers pass whatever image path the UI currently has, which may
  // already be a remote Storage path (nothing to do) or a local file/blob/
  // data URI selected from the device that still needs uploading; this is
  // the single place that decides which case applies and performs the
  // upload so every entry point (profile, custom drink, drink entry) stays
  // consistent.
  Future<String?> _resolveMediaPath({
    required String userId,
    required String? imagePath,
    required String folder,
  }) async {
    final normalized = imagePath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (!_looksLikeLocalFile(normalized)) {
      return normalized;
    }

    final bytes = await _readUploadBytes(normalized);
    final mimeType = _guessMimeTypeFromSource(normalized);
    final fileName = _storageFileNameForSource(normalized, mimeType);
    // Timestamp-prefixed filename avoids collisions when the same file name
    // is picked twice (e.g. re-selecting "IMG_0001.jpg"), without needing a
    // server round trip to check existence first.
    final sanitized =
        '${DateTime.now().millisecondsSinceEpoch}-${fileName.replaceAll(' ', '-')}';
    // Storage path is namespaced by userId/folder so bucket-level storage
    // policies can scope access per-user without per-object ACLs, and so
    // ownership can be checked later by prefix (see _isOwnedStoragePath).
    final storagePath = '$userId/$folder/$sanitized';

    await _client.storage
        .from(_mediaBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mimeType),
        );

    return storagePath;
  }

  // Distinguishes "already uploaded" (http(s) Storage/CDN URL) from
  // "still on device" (blob/data URI on web, absolute path or file:// on
  // native, Windows drive path) so _resolveMediaPath knows whether an
  // upload is needed. Order matters: http(s) is checked first since a
  // remote URL could otherwise be misidentified by later checks.
  bool _looksLikeLocalFile(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return false;
    }
    if (path.startsWith('blob:') || path.startsWith('data:')) {
      return true;
    }
    if (path.startsWith('/')) {
      return true;
    }
    if (path.contains(':\\')) {
      return true;
    }
    return path.startsWith('file://');
  }

  // data: URIs (typical on web, e.g. from an <input type=file> read as a
  // data URL) are decoded directly since there's no filesystem to read
  // from; everything else goes through XFile, which works across native
  // file paths and web blob: URLs alike.
  Future<Uint8List> _readUploadBytes(String source) async {
    if (source.startsWith('data:')) {
      final bytes = Uri.parse(source).data?.contentAsBytes();
      if (bytes == null) {
        throw const AppException('The selected image could not be read.');
      }
      return Uint8List.fromList(bytes);
    }
    return XFile(source).readAsBytes();
  }

  // data:/blob: sources have no meaningful original filename to reuse, so a
  // generic name is derived from the detected mime type instead of trying
  // to extract one from the URI.
  String _storageFileNameForSource(String source, String mimeType) {
    if (source.startsWith('data:') || source.startsWith('blob:')) {
      return 'upload${_extensionForMimeType(mimeType)}';
    }
    return source.split(RegExp(r'[\\/]')).last;
  }

  // Auth metadata (unlike the profiles table) isn't updated as part of the
  // same transaction that uploads a new image, so it must never be given a
  // not-yet-uploaded local path — only an already-remote path is safe to
  // persist there (see signUp/_ensureProfile, which read this metadata as
  // a fallback before a profiles row exists).
  bool _shouldPersistAuthMetadataImagePath(String? imagePath) {
    final normalized = imagePath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return !_looksLikeLocalFile(normalized);
  }

  Future<void> _deleteMediaPathIfOwned(String? imagePath, String userId) async {
    final normalized = imagePath?.trim();
    if (!_isOwnedStoragePath(normalized, userId)) {
      return;
    }
    try {
      await _client.storage.from(_mediaBucket).remove(<String>[normalized!]);
    } on StorageException {
      // Best-effort cleanup; data changes should still succeed.
    }
  }

  // Guards against ever deleting a path that isn't actually a Storage
  // object owned by this user: a still-local path (never uploaded) or one
  // whose userId/ prefix doesn't match must not be passed to storage
  // .remove, since deleting an arbitrary/foreign path would be a data-loss
  // bug rather than cleanup.
  bool _isOwnedStoragePath(String? imagePath, String userId) {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    if (_looksLikeLocalFile(imagePath)) {
      return false;
    }
    return imagePath.split('/').first == userId;
  }

  String _guessMimeTypeFromSource(String source) {
    if (source.startsWith('data:')) {
      final mimeType = Uri.parse(source).data?.mimeType;
      if (mimeType != null && mimeType.isNotEmpty) {
        return mimeType;
      }
      return 'image/jpeg';
    }
    return _guessMimeType(source);
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _extensionForMimeType(String mimeType) {
    final normalized = mimeType.toLowerCase();
    if (normalized == 'image/png') {
      return '.png';
    }
    if (normalized == 'image/webp') {
      return '.webp';
    }
    return '.jpg';
  }

  String? _normalizeLocationAddress(String? value) {
    return normalizeLocationAddress(value);
  }

  String _fallbackDisplayName(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) {
      return 'Glass Trail User';
    }
    return value.split('@').first;
  }

  String _toDateString(DateTime value) {
    final normalized = normalizeBirthday(value);
    return normalized.toIso8601String().split('T').first;
  }
}
