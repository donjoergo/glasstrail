import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../birthday.dart';
import '../friend_stats_profile.dart';
import '../models.dart';
import 'app_repository.dart';

class SupabaseAppRepository implements AppRepository {
  SupabaseAppRepository(this._client, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  static const _mediaBucket = 'user-media';

  final SupabaseClient _client;
  final Uuid _uuid;

  @visibleForTesting
  static const notificationSubscriptionErrorStackTrace = StackTrace.empty;

  @override
  String get backendLabel => 'Supabase';

  @override
  bool get usesRemoteBackend => true;

  @override
  Future<AppUser?> restoreSession() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return null;
    }
    try {
      return _ensureProfile(authUser);
    } on AuthException catch (error) {
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
          if (_shouldPersistAuthMetadataImagePath(trimmedProfileImagePath))
            'profile_image_path': trimmedProfileImagePath,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AppException('Sign-up did not return a user.');
      }

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
  Future<AppUser> updateProfile(AppUser user) async {
    try {
      final previousProfile = await _loadProfile(
        user.id,
        fallbackEmail: user.email,
      );
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: user.profileImagePath,
        folder: 'profiles',
      );

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
  Future<List<FriendConnection>> loadFriendConnections(String userId) async {
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
      final response = await _client.functions.invoke(
        'friend-shared-profile',
        method: HttpMethod.post,
        body: <String, dynamic>{
          'friendUserId': friendUserId.trim(),
          'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const AppException('This friend profile is unavailable.');
      }
      return FriendStatsProfile.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (error) {
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
  Future<List<AppNotification>> loadNotifications(String userId) async {
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
    var isClosed = false;

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
  Future<List<DrinkDefinition>> loadDefaultCatalog() async {
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

      if (drinks.isEmpty) {
        return buildDefaultDrinkCatalog();
      }
      return drinks;
    } on PostgrestException {
      return buildDefaultDrinkCatalog();
    }
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(String userId) async {
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
  Future<List<DrinkEntry>> loadEntries(String userId) async {
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

      final row = await _client
          .from('drink_entries')
          .update(<String, dynamic>{
            'comment': trimmedComment == null || trimmedComment.isEmpty
                ? null
                : trimmedComment,
            'image_path': finalImagePath,
          })
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
  Future<UserSettings> loadSettings(String userId) async {
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
    final sanitized =
        '${DateTime.now().millisecondsSinceEpoch}-${fileName.replaceAll(' ', '-')}';
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

  String _storageFileNameForSource(String source, String mimeType) {
    if (source.startsWith('data:') || source.startsWith('blob:')) {
      return 'upload${_extensionForMimeType(mimeType)}';
    }
    return source.split(RegExp(r'[\\/]')).last;
  }

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
