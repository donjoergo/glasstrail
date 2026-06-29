import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

    test('writes and normalizes accent colors for custom drinks', () async {
      const userId = 'user-123';

      final updated = await repository.saveCustomDrink(
        userId: userId,
        drinkId: 'drink-234',
        name: 'Sunset Spritz',
        category: DrinkCategory.cocktails,
        volumeMl: 250,
        accentColorHex: 'ec4899',
      );

      expect(updated.accentColorHex, '#EC4899');
      expect(server.lastUpsertBody?['accent_color_hex'], '#EC4899');
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
