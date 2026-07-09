import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/catalog_models.dart';
import 'package:glasstrail/src/achievements/repository_models.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/supabase_app_repository.dart';
import 'package:glasstrail/src/time_zone_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAppRepository.changePassword', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test('reauthenticates before updating the password', () async {
      const user = AppUser(
        id: 'user-123',
        email: 'user@example.com',
        displayName: 'Password User',
      );

      await repository.changePassword(
        user: user,
        currentPassword: 'secret',
        newPassword: 'new-secret',
      );

      expect(server.signInWithPasswordCalls, 1);
      expect(server.lastSignInBody?['email'], 'user@example.com');
      expect(server.lastSignInBody?['password'], 'secret');
      expect(server.updateUserCalls, 1);
      expect(server.lastUpdateUserBody?['password'], 'new-secret');
    });

    test(
      'maps invalid current password failures to a dedicated app error',
      () async {
        const user = AppUser(
          id: 'user-123',
          email: 'user@example.com',
          displayName: 'Password User',
        );
        server.failPasswordReauth = true;

        expect(
          () => repository.changePassword(
            user: user,
            currentPassword: 'wrong-secret',
            newPassword: 'new-secret',
          ),
          throwsA(
            isA<AppException>().having(
              (error) => error.message,
              'message',
              'The current password is incorrect.',
            ),
          ),
        );
        expect(server.updateUserCalls, 0);
      },
    );
  });

  group('SupabaseAppRepository.deleteAccount', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test('calls the delete-account function and signs out locally', () async {
      const user = AppUser(
        id: 'user-123',
        email: 'user@example.com',
        displayName: 'Delete User',
      );
      await client.auth.signInWithPassword(
        email: 'user@example.com',
        password: 'secret',
      );

      await repository.deleteAccount(user);

      expect(server.deleteAccountFunctionCalls, 1);
      expect(server.logoutCalls, 1);
    });

    test(
      'treats logout cleanup as best effort after the account was deleted',
      () async {
        const user = AppUser(
          id: 'user-123',
          email: 'user@example.com',
          displayName: 'Delete User',
        );
        server.failLogout = true;
        await client.auth.signInWithPassword(
          email: 'user@example.com',
          password: 'secret',
        );

        await repository.deleteAccount(user);

        expect(server.deleteAccountFunctionCalls, 1);
        expect(server.logoutCalls, 1);
        expect(client.auth.currentSession, isNull);
      },
    );
  });

  group('SupabaseAppRepository.restoreSession', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test(
      'forceRefresh revalidates the current session with Supabase',
      () async {
        server.profilesById['user-123'] = <String, dynamic>{
          'id': 'user-123',
          'email': 'user@example.com',
          'display_name': 'Restored User',
        };
        await client.auth.signInWithPassword(
          email: 'user@example.com',
          password: 'secret',
        );

        final restored = await repository.restoreSession(forceRefresh: true);

        expect(restored?.id, 'user-123');
        expect(server.refreshSessionCalls, 1);
      },
    );

    test(
      'returns null when forceRefresh finds an invalid remote session',
      () async {
        await client.auth.signInWithPassword(
          email: 'user@example.com',
          password: 'secret',
        );
        server.failRefreshSession = true;

        final restored = await repository.restoreSession(forceRefresh: true);

        expect(restored, isNull);
        expect(server.refreshSessionCalls, 1);
      },
    );

    test(
      'still surfaces profile loading failures after a successful auth refresh',
      () async {
        await client.auth.signInWithPassword(
          email: 'user@example.com',
          password: 'secret',
        );
        server.failProfileLookup = true;

        await expectLater(
          () => repository.restoreSession(forceRefresh: true),
          throwsA(
            isA<AppException>().having(
              (error) => error.message,
              'message',
              contains('Profile lookup failed'),
            ),
          ),
        );
        expect(server.refreshSessionCalls, 1);
      },
    );
  });

  group('SupabaseAppRepository.saveCustomDrink', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        accessToken: () async => 'test-token',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test(
      'deletes the previous owned image when clearing a custom drink photo',
      () async {
        const userId = 'user-123';
        const drinkId = 'drink-123';
        const previousImagePath = 'user-123/custom-drinks/old-photo.png';

        server.userDrinksById[drinkId] = <String, dynamic>{
          'id': drinkId,
          'user_id': userId,
          'name': 'Office Brew',
          'category_slug': DrinkCategory.nonAlcoholic.storageValue,
          'volume_ml': 300,
          'image_path': previousImagePath,
        };

        final updated = await repository.saveCustomDrink(
          userId: userId,
          drinkId: drinkId,
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
          imagePath: null,
        );

        expect(updated.imagePath, isNull);
        expect(server.lastUpsertBody?['image_path'], isNull);
        expect(server.deletedPrefixes, <String>[previousImagePath]);
      },
    );

    test(
      'does not delete the stored image when the photo stays unchanged',
      () async {
        const userId = 'user-123';
        const drinkId = 'drink-123';
        const previousImagePath = 'user-123/custom-drinks/old-photo.png';

        server.userDrinksById[drinkId] = <String, dynamic>{
          'id': drinkId,
          'user_id': userId,
          'name': 'Office Brew',
          'category_slug': DrinkCategory.nonAlcoholic.storageValue,
          'volume_ml': 300,
          'image_path': previousImagePath,
        };

        final updated = await repository.saveCustomDrink(
          userId: userId,
          drinkId: drinkId,
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
          imagePath: previousImagePath,
        );

        expect(updated.imagePath, previousImagePath);
        expect(server.deletedPrefixes, isEmpty);
      },
    );

    test('writes alcohol-free flags for custom drinks', () async {
      const userId = 'user-123';

      final updated = await repository.saveCustomDrink(
        userId: userId,
        drinkId: 'drink-123',
        name: 'Free Pils',
        category: DrinkCategory.beer,
        volumeMl: 500,
        isAlcoholFree: true,
      );

      expect(updated.isAlcoholFree, isTrue);
      expect(server.lastUpsertBody?['is_alcohol_free'], isTrue);
    });

    test('loads global catalog alcohol-free flags', () async {
      server.globalDrinks.addAll(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'beer-non-alcoholic',
          'category_slug': DrinkCategory.beer.storageValue,
          'name_en': 'Non-alcoholic Beer',
          'name_de': 'Alkoholfreies Bier',
          'default_volume_ml': 500,
          'is_alcohol_free': true,
        },
      ]);

      final catalog = await repository.loadDefaultCatalog();

      expect(catalog.single.id, 'beer-non-alcoholic');
      expect(catalog.single.isAlcoholFree, isTrue);
    });

    test('snapshots alcohol-free flag when creating an entry', () async {
      const user = AppUser(
        id: 'user-123',
        email: 'user@example.com',
        password: 'secret',
        displayName: 'Test User',
      );

      final entry = await repository.addDrinkEntry(
        user: user,
        drink: const DrinkDefinition(
          id: 'beer-non-alcoholic',
          name: 'Non-alcoholic Beer',
          category: DrinkCategory.beer,
          isAlcoholFree: true,
        ),
      );

      expect(entry.isAlcoholFree, isTrue);
      expect(server.lastEntryInsertBody?['is_alcohol_free'], isTrue);
    });
  });

  group('SupabaseAppRepository.updateDrinkEntry', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        accessToken: () async => 'test-token',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test(
      'writes replacement drink snapshot fields in the patch body',
      () async {
        const user = AppUser(
          id: 'user-123',
          email: 'user@example.com',
          password: 'secret',
          displayName: 'Test User',
        );
        const entryId = 'entry-123';
        server.entryRowsById[entryId] = <String, dynamic>{
          'id': entryId,
          'user_id': user.id,
          'source_type': 'global',
          'source_drink_id': 'beer-pils',
          'drink_name': 'Pils',
          'category_slug': DrinkCategory.beer.storageValue,
          'volume_ml': 500,
          'is_alcohol_free': false,
          'comment': 'Original note',
          'image_path': 'user-123/entries/original-entry.png',
          'consumed_at': DateTime.utc(2026, 5, 11, 10).toIso8601String(),
        };
        final replacementDrink = DrinkDefinition(
          id: 'custom-negroni',
          name: 'House Negroni',
          category: DrinkCategory.cocktails,
          volumeMl: 180,
          ownerUserId: user.id,
        );

        final updated = await repository.updateDrinkEntry(
          user: user,
          entry: DrinkEntry(
            id: entryId,
            userId: user.id,
            drinkId: 'beer-pils',
            drinkName: 'Pils',
            category: DrinkCategory.beer,
            consumedAt: DateTime(2026, 5, 11, 12),
            volumeMl: 500,
            comment: 'Original note',
            imagePath: 'user-123/entries/original-entry.png',
          ),
          replacementDrink: replacementDrink,
          volumeMl: replacementDrink.volumeMl,
          comment: 'Updated note',
          imagePath: 'user-123/entries/original-entry.png',
        );

        expect(server.lastEntryUpdateBody?['source_type'], 'custom');
        expect(
          server.lastEntryUpdateBody?['source_drink_id'],
          'custom-negroni',
        );
        expect(server.lastEntryUpdateBody?['drink_name'], 'House Negroni');
        expect(
          server.lastEntryUpdateBody?['category_slug'],
          DrinkCategory.cocktails.storageValue,
        );
        expect(server.lastEntryUpdateBody?['is_alcohol_free'], isFalse);
        expect(server.lastEntryUpdateBody?['volume_ml'], 180);
        expect(updated.drinkId, 'custom-negroni');
        expect(updated.drinkName, 'House Negroni');
        expect(updated.category, DrinkCategory.cocktails);
        expect(updated.volumeMl, 180);
        expect(updated.comment, 'Updated note');
        expect(updated.imagePath, 'user-123/entries/original-entry.png');
      },
    );
  });

  group('SupabaseAppRepository.watchNotifications', () {
    test(
      'waits for subscription confirmation before loading snapshot',
      () async {
        final repository = _ControllableNotificationWatchRepository();
        final notifications = <AppNotification>[
          AppNotification(
            id: 'notification-1',
            recipientUserId: 'user-123',
            senderUserId: 'friend-456',
            senderDisplayName: 'Test Friend',
            type: AppNotificationTypes.friendRequestSent,
            createdAt: DateTime.utc(2026, 5, 2, 12),
          ),
        ];
        repository.notificationsToReturn = notifications;
        final emitted = <List<AppNotification>>[];

        final subscription = repository
            .watchNotifications('user-123')
            .listen(emitted.add);
        addTearDown(subscription.cancel);

        expect(repository.loadNotificationsCallCount, 0);
        expect(emitted, isEmpty);

        await repository.emitSubscribed();
        await Future<void>.delayed(Duration.zero);

        expect(repository.loadNotificationsCallCount, 1);
        expect(emitted.single, same(notifications));
      },
    );

    test('reloads snapshot when subscription is confirmed again', () async {
      final repository = _ControllableNotificationWatchRepository();
      repository.notificationsToReturn = <AppNotification>[
        AppNotification(
          id: 'notification-1',
          recipientUserId: 'user-123',
          senderUserId: 'friend-456',
          senderDisplayName: 'Test Friend',
          type: AppNotificationTypes.friendRequestSent,
          createdAt: DateTime.utc(2026, 5, 2, 12),
        ),
      ];

      final subscription = repository
          .watchNotifications('user-123')
          .listen((_) {});
      addTearDown(subscription.cancel);

      await repository.emitSubscribed();
      await repository.emitSubscribed();

      expect(repository.loadNotificationsCallCount, 2);
    });
  });

  group('SupabaseAppRepository.loadFriendStatsProfile', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        accessToken: () async => 'test-token',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test('sends a timezone identifier with offset fallback', () async {
      final repository = SupabaseAppRepository(
        client,
        timeZoneProvider: const _FakeTimeZoneProvider('Europe/Berlin'),
      );
      final expectedOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

      final profile = await repository.loadFriendStatsProfile(
        userId: '11111111-1111-4111-8111-111111111111',
        friendUserId: '22222222-2222-4222-8222-222222222222',
      );

      expect(profile.id, server.friendSharedProfileResponse['id']);
      expect(server.lastFunctionBody?['friendUserId'], profile.id);
      expect(server.lastFunctionBody?['timeZone'], 'Europe/Berlin');
      expect(
        server.lastFunctionBody?['utcOffsetMinutes'],
        expectedOffsetMinutes,
      );
    });

    test(
      'falls back to the current offset when the timezone is unavailable',
      () async {
        final repository = SupabaseAppRepository(
          client,
          timeZoneProvider: const _FakeTimeZoneProvider(null),
        );
        final expectedOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

        await repository.loadFriendStatsProfile(
          userId: '11111111-1111-4111-8111-111111111111',
          friendUserId: '22222222-2222-4222-8222-222222222222',
        );

        expect(server.lastFunctionBody?['timeZone'], isNull);
        expect(
          server.lastFunctionBody?['utcOffsetMinutes'],
          expectedOffsetMinutes,
        );
      },
    );
  });

  group('SupabaseAppRepository achievements', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        accessToken: () async => 'test-token',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test('loadAchievementUnlocks maps stored rows into AchievementUnlock', () async {
      server.achievementUnlocksByKey['total_drinks|1'] = <String, dynamic>{
        'family_id': 'total_drinks',
        'level': 1,
        'qualified_at': '2026-01-01T00:00:00Z',
        'granted_at': '2026-01-01T00:00:05Z',
        'source': 'realtime_log',
        'surfaced_at': null,
      };

      final unlocks = await repository.loadAchievementUnlocks('user-123');

      expect(unlocks.single.familyId, 'total_drinks');
      expect(unlocks.single.level, 1);
      expect(unlocks.single.source, AchievementUnlockSource.realtimeLog);
      expect(unlocks.single.surfacedAt, isNull);
    });

    test('upsertAchievementUnlocks sends the grants RPC and keeps the earliest qualifiedAt/grantedAt on conflict', () async {
      final first = await repository.upsertAchievementUnlocks(
        userId: 'user-123',
        grants: <AchievementUnlockGrant>[
          AchievementUnlockGrant(
            familyId: 'total_drinks',
            level: 1,
            qualifiedAt: DateTime.utc(2026, 3, 5),
            source: AchievementUnlockSource.realtimeLog,
          ),
        ],
      );
      expect(server.lastRpcName, 'upsert_achievement_unlocks');
      expect(first.single.qualifiedAt, DateTime.utc(2026, 3, 5));

      // A later, redundant grant for the same family/level (e.g. from a
      // second device's backfill) must not push qualifiedAt forward.
      final second = await repository.upsertAchievementUnlocks(
        userId: 'user-123',
        grants: <AchievementUnlockGrant>[
          AchievementUnlockGrant(
            familyId: 'total_drinks',
            level: 1,
            qualifiedAt: DateTime.utc(2026, 3, 10),
            source: AchievementUnlockSource.backfill,
          ),
        ],
      );

      expect(second.single.qualifiedAt, DateTime.utc(2026, 3, 5));
      expect(
        await repository.loadAchievementUnlocks('user-123'),
        hasLength(1),
      );
    });

    test('markAchievementUnlocksSurfaced only updates rows not already surfaced', () async {
      server.achievementUnlocksByKey['total_drinks|1'] = <String, dynamic>{
        'family_id': 'total_drinks',
        'level': 1,
        'qualified_at': '2026-01-01T00:00:00Z',
        'granted_at': '2026-01-01T00:00:05Z',
        'source': 'realtime_log',
        'surfaced_at': null,
      };
      server.achievementUnlocksByKey['type_beer|10'] = <String, dynamic>{
        'family_id': 'type_beer',
        'level': 10,
        'qualified_at': '2026-01-02T00:00:00Z',
        'granted_at': '2026-01-02T00:00:05Z',
        'source': 'realtime_log',
        'surfaced_at': '2026-01-02T01:00:00Z',
      };

      await repository.markAchievementUnlocksSurfaced(
        userId: 'user-123',
        unlocks: const <AchievementUnlockRef>[
          AchievementUnlockRef(familyId: 'total_drinks', level: 1),
          AchievementUnlockRef(familyId: 'type_beer', level: 10),
        ],
      );

      final unlocks = await repository.loadAchievementUnlocks('user-123');
      final totalDrinks = unlocks.firstWhere(
        (u) => u.familyId == 'total_drinks',
      );
      final typeBeer = unlocks.firstWhere((u) => u.familyId == 'type_beer');
      expect(totalDrinks.surfacedAt, isNotNull);
      // Already-surfaced row's original surfaced_at is untouched, not
      // overwritten with a later timestamp.
      expect(typeBeer.surfacedAt, DateTime.parse('2026-01-02T01:00:00Z'));
    });

    test('loadFriendSharedAchievements groups levels by family in first-seen order', () async {
      server.friendSharedAchievementRows = <Map<String, dynamic>>[
        <String, dynamic>{'family_id': 'total_drinks', 'level': 1},
        <String, dynamic>{'family_id': 'total_drinks', 'level': 10},
        <String, dynamic>{'family_id': 'type_beer', 'level': 1},
      ];

      final families = await repository.loadFriendSharedAchievements(
        userId: 'user-123',
        friendUserId: 'friend-456',
      );

      expect(server.lastRpcName, 'load_friend_shared_achievements');
      expect(server.lastRpcBody?['target_friend_user_id'], 'friend-456');
      expect(families.map((f) => f.familyId), <String>[
        'total_drinks',
        'type_beer',
      ]);
      expect(
        families.firstWhere((f) => f.familyId == 'total_drinks').earnedLevels,
        <int>[1, 10],
      );
    });

    test('saveSettings persists shareAchievements independently from shareStatsWithFriends', () async {
      const settings = UserSettings(
        themePreference: AppThemePreference.system,
        localeCode: 'en',
        unit: AppUnit.ml,
        handedness: AppHandedness.right,
        shareStatsWithFriends: false,
        shareAchievements: true,
      );

      await repository.saveSettings('user-123', settings);

      expect(server.userSettingsByUserId['user-123']?['share_stats_with_friends'], isFalse);
      expect(server.userSettingsByUserId['user-123']?['share_achievements'], isTrue);
    });

    test('replaceActiveSavedPlace archives the previous active place and loadSavedPlaces/deleteSavedPlace round-trip', () async {
      final first = await repository.replaceActiveSavedPlace(
        userId: 'user-123',
        placeType: SavedPlaceType.home,
        latitude: 52.52,
        longitude: 13.405,
      );
      expect(server.lastRpcName, 'replace_active_saved_place');

      final second = await repository.replaceActiveSavedPlace(
        userId: 'user-123',
        placeType: SavedPlaceType.home,
        latitude: 48.13,
        longitude: 11.58,
      );

      final places = await repository.loadSavedPlaces(userId: 'user-123');
      final archivedFirst = places.firstWhere((p) => p.id == first.id);
      expect(archivedFirst.isActive, isFalse);
      expect(archivedFirst.archivedAt, isNotNull);
      expect(places.firstWhere((p) => p.id == second.id).isActive, isTrue);

      await repository.deleteSavedPlace(userId: 'user-123', placeId: first.id);
      final afterDelete = await repository.loadSavedPlaces(userId: 'user-123');
      expect(afterDelete.map((p) => p.id), <String>[second.id]);
    });
  });
}

class _MockSupabaseServer {
  _MockSupabaseServer._(this._server) {
    _server.listen((request) async {
      try {
        await _handle(request);
      } catch (error) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, String>{'error': error.toString()}),
        );
        await request.response.close();
      }
    });
  }

  final HttpServer _server;
  final Map<String, Map<String, dynamic>> profilesById =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> userSettingsByUserId =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> userDrinksById =
      <String, Map<String, dynamic>>{};
  final List<Map<String, dynamic>> globalDrinks = <Map<String, dynamic>>[];
  final Map<String, Map<String, dynamic>> entryRowsById =
      <String, Map<String, dynamic>>{};
  final List<String> deletedPrefixes = <String>[];
  // Keyed by "familyId|level" -- the mock only ever serves one implicit
  // signed-in user per test, mirroring `upsert_achievement_unlocks`
  // inferring `auth.uid()` server-side rather than taking a userId param.
  final Map<String, Map<String, dynamic>> achievementUnlocksByKey =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> savedPlacesById =
      <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>> friendSharedAchievementRows =
      const <Map<String, dynamic>>[];
  Map<String, dynamic>? lastRpcBody;
  String? lastRpcName;
  bool failPasswordReauth = false;
  bool failRefreshSession = false;
  bool failLogout = false;
  bool failProfileLookup = false;
  final Map<String, dynamic> friendSharedProfileResponse = <String, dynamic>{
    'id': '22222222-2222-4222-8222-222222222222',
    'displayName': 'Shared Friend',
    'profileImagePath': null,
    'shareStatsWithFriends': true,
    'statistics': null,
  };
  int signInWithPasswordCalls = 0;
  int refreshSessionCalls = 0;
  int updateUserCalls = 0;
  int logoutCalls = 0;
  int deleteAccountFunctionCalls = 0;
  Map<String, dynamic>? lastSignInBody;
  Map<String, dynamic>? lastUpdateUserBody;
  Map<String, dynamic>? lastUpsertBody;
  Map<String, dynamic>? lastEntryInsertBody;
  Map<String, dynamic>? lastEntryUpdateBody;
  Map<String, dynamic>? lastFunctionBody;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_MockSupabaseServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _MockSupabaseServer._(server);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'POST' &&
        path == '/auth/v1/token' &&
        request.uri.queryParameters['grant_type'] == 'password') {
      signInWithPasswordCalls++;
      lastSignInBody = await _readJsonMap(request);
      if (failPasswordReauth) {
        await _writeAuthError(
          request.response,
          HttpStatus.badRequest,
          'Invalid login credentials',
        );
        return;
      }
      await _writeJson(request.response, <String, dynamic>{
        'access_token': 'reauth-token',
        'refresh_token': 'reauth-refresh-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': 1_893_456_000,
        'user': <String, dynamic>{
          'id': 'user-123',
          'email': lastSignInBody?['email'],
        },
      });
      return;
    }

    if (request.method == 'POST' &&
        path == '/auth/v1/token' &&
        request.uri.queryParameters['grant_type'] == 'refresh_token') {
      refreshSessionCalls++;
      await _readJsonMap(request);
      if (failRefreshSession) {
        await _writeAuthError(
          request.response,
          HttpStatus.badRequest,
          'Invalid Refresh Token',
        );
        return;
      }
      await _writeJson(request.response, <String, dynamic>{
        'access_token': 'refreshed-token',
        'refresh_token': 'refreshed-refresh-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': 1_893_456_000,
        'user': <String, dynamic>{
          'id': 'user-123',
          'email': 'user@example.com',
        },
      });
      return;
    }

    if (request.method == 'PUT' && path == '/auth/v1/user') {
      updateUserCalls++;
      lastUpdateUserBody = await _readJsonMap(request);
      await _writeJson(request.response, <String, dynamic>{
        'id': 'user-123',
        'email': 'user@example.com',
      });
      return;
    }

    if (request.method == 'POST' && path == '/auth/v1/logout') {
      logoutCalls++;
      if (failLogout) {
        await _writeAuthError(
          request.response,
          HttpStatus.internalServerError,
          'Logout failed',
        );
        return;
      }
      await _writeJson(request.response, <String, dynamic>{});
      return;
    }

    if (request.method == 'GET' && path == '/rest/v1/profiles') {
      if (failProfileLookup) {
        await _writePostgrestError(
          request.response,
          HttpStatus.internalServerError,
          'Profile lookup failed',
        );
        return;
      }
      final userId = _stripEqPrefix(request.uri.queryParameters['id']);
      final row = userId == null ? null : profilesById[userId];
      await _writeJson(
        request.response,
        row == null ? <Map<String, dynamic>>[] : <Map<String, dynamic>>[row],
      );
      return;
    }

    if (request.method == 'POST' && path == '/rest/v1/profiles') {
      final body = await _readJsonMap(request);
      profilesById[body['id'] as String] = Map<String, dynamic>.from(body);
      await _writeJson(request.response, body);
      return;
    }

    if (request.method == 'POST' && path == '/rest/v1/user_settings') {
      final body = await _readJsonMap(request);
      userSettingsByUserId[body['user_id'] as String] =
          Map<String, dynamic>.from(body);
      await _writeJson(request.response, body);
      return;
    }

    if (request.method == 'GET' && path == '/rest/v1/user_drinks') {
      final drinkId = _stripEqPrefix(request.uri.queryParameters['id']);
      final userId = _stripEqPrefix(request.uri.queryParameters['user_id']);
      final row = userDrinksById[drinkId];
      final responseBody = row != null && row['user_id'] == userId
          ? <Map<String, dynamic>>[
              <String, dynamic>{'image_path': row['image_path']},
            ]
          : <Map<String, dynamic>>[];
      await _writeJson(request.response, responseBody);
      return;
    }

    if (request.method == 'GET' && path == '/rest/v1/global_drinks') {
      await _writeJson(request.response, globalDrinks);
      return;
    }

    if (request.method == 'POST' && path == '/rest/v1/user_drinks') {
      final body = await _readJsonMap(request);
      lastUpsertBody = body;
      userDrinksById[body['id'] as String] = Map<String, dynamic>.from(body);
      await _writeJson(request.response, body);
      return;
    }

    if (request.method == 'POST' && path == '/rest/v1/drink_entries') {
      final body = await _readJsonMap(request);
      lastEntryInsertBody = body;
      entryRowsById[body['id'] as String] = Map<String, dynamic>.from(body);
      await _writeJson(request.response, body);
      return;
    }

    if (request.method == 'PATCH' && path == '/rest/v1/drink_entries') {
      final entryId = _stripEqPrefix(request.uri.queryParameters['id']);
      final userId = _stripEqPrefix(request.uri.queryParameters['user_id']);
      final existingRow = entryRowsById[entryId];
      if (entryId == null ||
          userId == null ||
          existingRow == null ||
          existingRow['user_id'] != userId) {
        await _writeJson(request.response, null);
        return;
      }

      final body = await _readJsonMap(request);
      lastEntryUpdateBody = body;
      final updatedRow = Map<String, dynamic>.from(existingRow)..addAll(body);
      entryRowsById[entryId] = updatedRow;
      await _writeJson(request.response, updatedRow);
      return;
    }

    if (request.method == 'GET' && path == '/rest/v1/achievement_unlocks') {
      final rows = achievementUnlocksByKey.values.toList(growable: false)
        ..sort(
          (a, b) => (b['granted_at'] as String).compareTo(
            a['granted_at'] as String,
          ),
        );
      await _writeJson(request.response, rows);
      return;
    }

    if (request.method == 'PATCH' && path == '/rest/v1/achievement_unlocks') {
      final familyId = _stripEqPrefix(
        request.uri.queryParameters['family_id'],
      );
      final level = _stripEqPrefix(request.uri.queryParameters['level']);
      final body = await _readJsonMap(request);
      final key = '$familyId|$level';
      final existing = achievementUnlocksByKey[key];
      if (existing != null && existing['surfaced_at'] == null) {
        achievementUnlocksByKey[key] = Map<String, dynamic>.from(existing)
          ..addAll(body);
      }
      await _writeJson(request.response, <Map<String, dynamic>>[]);
      return;
    }

    if (request.method == 'POST' &&
        path == '/rest/v1/rpc/upsert_achievement_unlocks') {
      final body = await _readJsonMap(request);
      lastRpcName = 'upsert_achievement_unlocks';
      lastRpcBody = body;
      final grants = List<Map<String, dynamic>>.from(
        (body['grants'] as List<dynamic>).map(
          (g) => Map<String, dynamic>.from(g as Map),
        ),
      );
      final returned = <Map<String, dynamic>>[];
      for (final grant in grants) {
        final familyId = grant['familyId'] as String;
        final level = grant['level'];
        final key = '$familyId|$level';
        final existing = achievementUnlocksByKey[key];
        final row = <String, dynamic>{
          'family_id': familyId,
          'level': level,
          'qualified_at': existing == null
              ? grant['qualifiedAt']
              : _earlierIso(
                  existing['qualified_at'] as String,
                  grant['qualifiedAt'] as String,
                ),
          'granted_at': existing == null
              ? grant['grantedAt']
              : _earlierIso(
                  existing['granted_at'] as String,
                  grant['grantedAt'] as String,
                ),
          'source': existing?['source'] ?? grant['source'],
          'surfaced_at': existing?['surfaced_at'],
        };
        achievementUnlocksByKey[key] = row;
        returned.add(row);
      }
      await _writeJson(request.response, returned);
      return;
    }

    if (request.method == 'POST' &&
        path == '/rest/v1/rpc/load_friend_shared_achievements') {
      lastRpcName = 'load_friend_shared_achievements';
      lastRpcBody = await _readJsonMap(request);
      await _writeJson(request.response, friendSharedAchievementRows);
      return;
    }

    if (request.method == 'GET' && path == '/rest/v1/saved_places') {
      final userId = _stripEqPrefix(request.uri.queryParameters['user_id']);
      final placeType = _stripEqPrefix(
        request.uri.queryParameters['place_type'],
      );
      final rows = savedPlacesById.values
          .where((row) => row['user_id'] == userId)
          .where((row) => placeType == null || row['place_type'] == placeType)
          .toList(growable: false);
      await _writeJson(request.response, rows);
      return;
    }

    if (request.method == 'DELETE' && path == '/rest/v1/saved_places') {
      final placeId = _stripEqPrefix(request.uri.queryParameters['id']);
      savedPlacesById.remove(placeId);
      await _writeJson(request.response, <Map<String, dynamic>>[]);
      return;
    }

    if (request.method == 'POST' &&
        path == '/rest/v1/rpc/replace_active_saved_place') {
      final body = await _readJsonMap(request);
      lastRpcName = 'replace_active_saved_place';
      lastRpcBody = body;
      final placeType = body['target_place_type'] as String;
      final now = DateTime.now().toUtc().toIso8601String();
      for (final entry in savedPlacesById.entries.toList()) {
        if (entry.value['place_type'] == placeType &&
            entry.value['is_active'] == true) {
          savedPlacesById[entry.key] = Map<String, dynamic>.from(entry.value)
            ..['is_active'] = false
            ..['archived_at'] = now;
        }
      }
      final id = 'place-${savedPlacesById.length + 1}';
      final row = <String, dynamic>{
        'id': id,
        'user_id': 'user-123',
        'place_type': placeType,
        'latitude': body['target_latitude'],
        'longitude': body['target_longitude'],
        'is_active': true,
        'created_at': now,
        'updated_at': now,
        'archived_at': null,
      };
      savedPlacesById[id] = row;
      await _writeJson(request.response, row);
      return;
    }

    if (request.method == 'POST' &&
        path == '/functions/v1/friend-shared-profile') {
      final body = await _readJsonMap(request);
      lastFunctionBody = body;
      await _writeJson(request.response, friendSharedProfileResponse);
      return;
    }

    if (request.method == 'POST' && path == '/functions/v1/delete-account') {
      deleteAccountFunctionCalls++;
      await _writeJson(request.response, <String, dynamic>{'success': true});
      return;
    }

    if (request.method == 'DELETE' && path == '/storage/v1/object/user-media') {
      final body = await _readJsonMap(request);
      final prefixes = List<String>.from(body['prefixes'] as List<dynamic>);
      deletedPrefixes.addAll(prefixes);
      await _writeJson(
        request.response,
        prefixes
            .map(
              (prefix) => <String, dynamic>{
                'name': prefix.split('/').last,
                'bucket_id': 'user-media',
              },
            )
            .toList(growable: false),
      );
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<Map<String, dynamic>> _readJsonMap(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
  }

  Future<void> _writeJson(HttpResponse response, Object? body) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }

  Future<void> _writeAuthError(
    HttpResponse response,
    int statusCode,
    String message,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(
      jsonEncode(<String, dynamic>{
        'error': 'invalid_grant',
        'error_description': message,
        'msg': message,
      }),
    );
    await response.close();
  }

  Future<void> _writePostgrestError(
    HttpResponse response,
    int statusCode,
    String message,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(<String, dynamic>{'message': message}));
    await response.close();
  }

  String _earlierIso(String a, String b) {
    return DateTime.parse(a).isBefore(DateTime.parse(b)) ? a : b;
  }

  String? _stripEqPrefix(String? value) {
    if (value == null) {
      return null;
    }
    return value.startsWith('eq.') ? value.substring(3) : value;
  }
}

class _ControllableNotificationWatchRepository extends SupabaseAppRepository {
  _ControllableNotificationWatchRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'test-key'));

  List<AppNotification> notificationsToReturn = const <AppNotification>[];
  int loadNotificationsCallCount = 0;
  Future<void> Function()? _publishSnapshot;

  @override
  Future<List<AppNotification>> loadNotifications(
    String userId, {
    bool forceRefresh = false,
  }) async {
    loadNotificationsCallCount++;
    return notificationsToReturn;
  }

  @override
  Future<void> Function() startWatchingNotifications({
    required String userId,
    required Future<void> Function() publishSnapshot,
    required void Function(Object error, StackTrace stackTrace) publishError,
  }) {
    _publishSnapshot = publishSnapshot;
    return () async {};
  }

  Future<void> emitSubscribed() async {
    await _publishSnapshot?.call();
  }
}

class _FakeTimeZoneProvider implements TimeZoneProvider {
  const _FakeTimeZoneProvider(this.identifier);

  final String? identifier;

  @override
  Future<String?> getLocalTimeZoneIdentifier() async => identifier;
}
