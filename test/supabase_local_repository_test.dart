import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/backend_config.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/supabase_app_repository.dart';
import 'package:glasstrail/src/time_zone_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opt-in smoke tests against a local Supabase stack (`supabase start` +
/// `supabase db reset`). They are skipped unless all of these are set:
///
/// ```bash
/// export GLASSTRAIL_SUPABASE_LOCAL_TESTS=1
/// export GLASSTRAIL_SUPABASE_URL=http://127.0.0.1:54321
/// export GLASSTRAIL_SUPABASE_ANON_KEY=<local anon key from `supabase status`>
/// flutter test test/supabase_local_repository_test.dart
/// ```
///
/// The tests refuse to run against the production backend and never fall
/// back to the checked-in `BackendConfig` defaults.
const _transparentPngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRSEAAAAASUVORK5CYII=';

class _FixedTimeZoneProvider implements TimeZoneProvider {
  const _FixedTimeZoneProvider();

  @override
  Future<String?> getLocalTimeZoneIdentifier() async => 'Europe/Berlin';
}

String? _skipReason() {
  final enabled = Platform.environment['GLASSTRAIL_SUPABASE_LOCAL_TESTS'];
  final url = Platform.environment['GLASSTRAIL_SUPABASE_URL'];
  final anonKey = Platform.environment['GLASSTRAIL_SUPABASE_ANON_KEY'];
  if (enabled != '1' ||
      url == null ||
      url.isEmpty ||
      anonKey == null ||
      anonKey.isEmpty) {
    return 'Local Supabase tests are opt-in: set '
        'GLASSTRAIL_SUPABASE_LOCAL_TESTS=1, GLASSTRAIL_SUPABASE_URL, and '
        'GLASSTRAIL_SUPABASE_ANON_KEY.';
  }
  if (url == BackendConfig.defaultSupabaseUrl) {
    return 'Refusing to run local Supabase tests against the production '
        'backend URL.';
  }
  return null;
}

void main() {
  final skipReason = _skipReason();

  group('SupabaseAppRepository against local Supabase', () {
    late SupabaseClient clientA;
    late SupabaseClient clientB;
    late SupabaseAppRepository repositoryA;
    late SupabaseAppRepository repositoryB;
    late AppUser userA;
    late AppUser userB;

    // The implicit flow avoids the asyncStorage requirement of the default
    // PKCE flow; these tests only need short-lived password sessions.
    SupabaseClient newClient() => SupabaseClient(
      Platform.environment['GLASSTRAIL_SUPABASE_URL']!,
      Platform.environment['GLASSTRAIL_SUPABASE_ANON_KEY']!,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    setUpAll(() async {
      clientA = newClient();
      clientB = newClient();
      repositoryA = SupabaseAppRepository(
        clientA,
        timeZoneProvider: const _FixedTimeZoneProvider(),
      );
      repositoryB = SupabaseAppRepository(
        clientB,
        timeZoneProvider: const _FixedTimeZoneProvider(),
      );

      final runId = DateTime.now().millisecondsSinceEpoch;
      userA = await repositoryA.signUp(
        email: 'gt-local-a-$runId@example.com',
        password: 'password-a-123',
        displayName: 'Local Test A',
      );
      userB = await repositoryB.signUp(
        email: 'gt-local-b-$runId@example.com',
        password: 'password-b-123',
        displayName: 'Local Test B',
      );
    });

    tearDownAll(() async {
      await clientA.dispose();
      await clientB.dispose();
    });

    Future<DrinkDefinition> firstCatalogDrink() async {
      final catalog = await repositoryA.loadDefaultCatalog(forceRefresh: true);
      expect(catalog, isNotEmpty);
      return catalog.first;
    }

    test('persists settings changes across loads', () async {
      final initial = await repositoryA.loadSettings(userA.id);
      final updated = await repositoryA.saveSettings(
        userA.id,
        initial.copyWith(unit: AppUnit.oz, shareStatsWithFriends: false),
      );
      expect(updated.unit, AppUnit.oz);

      final reloaded = await repositoryA.loadSettings(
        userA.id,
        forceRefresh: true,
      );
      expect(reloaded.unit, AppUnit.oz);
      expect(reloaded.shareStatsWithFriends, isFalse);
    });

    test('creates, updates, and deletes a drink entry', () async {
      final drink = await firstCatalogDrink();
      final entry = await repositoryA.addDrinkEntry(
        user: userA,
        drink: drink,
        comment: 'local supabase entry',
      );
      expect(entry.comment, 'local supabase entry');

      final updated = await repositoryA.updateDrinkEntry(
        user: userA,
        entry: entry,
        comment: 'updated comment',
      );
      expect(updated.comment, 'updated comment');

      await repositoryA.deleteDrinkEntry(userId: userA.id, entry: updated);
      final entries = await repositoryA.loadEntries(
        userA.id,
        forceRefresh: true,
      );
      expect(entries.where((e) => e.id == entry.id), isEmpty);
    });

    test('creates, updates, and deletes a custom drink', () async {
      final created = await repositoryA.saveCustomDrink(
        userId: userA.id,
        name: 'Local Test Brew',
        category: DrinkCategory.values.first,
        volumeMl: 330,
      );
      expect(created.isCustom, isTrue);

      final renamed = await repositoryA.saveCustomDrink(
        userId: userA.id,
        drinkId: created.id,
        name: 'Local Test Brew Renamed',
        category: created.category,
        volumeMl: 500,
      );
      expect(renamed.name, 'Local Test Brew Renamed');

      await repositoryA.deleteCustomDrink(userId: userA.id, drink: renamed);
      final drinks = await repositoryA.loadCustomDrinks(
        userA.id,
        forceRefresh: true,
      );
      expect(drinks.where((d) => d.id == created.id), isEmpty);
    });

    test(
      'maps duplicate import inserts to the already-imported error',
      () async {
        final drink = await firstCatalogDrink();
        final entry = await repositoryA.addDrinkEntry(
          user: userA,
          drink: drink,
          importSource: 'beerwithme',
          importSourceId: 'gt-local-duplicate-check',
        );

        await expectLater(
          repositoryA.addDrinkEntry(
            user: userA,
            drink: drink,
            importSource: 'beerwithme',
            importSourceId: 'gt-local-duplicate-check',
          ),
          throwsA(
            isA<AppException>().having(
              (error) => error.message,
              'message',
              'This BeerWithMe entry was already imported.',
            ),
          ),
        );

        await repositoryA.deleteDrinkEntry(userId: userA.id, entry: entry);
      },
    );

    test('isolates rows and media between users', () async {
      final drink = await firstCatalogDrink();
      final customDrink = await repositoryA.saveCustomDrink(
        userId: userA.id,
        name: 'Isolation Brew',
        category: DrinkCategory.values.first,
      );
      final entry = await repositoryA.addDrinkEntry(
        user: userA,
        drink: drink,
        comment: 'isolation entry',
        imagePath: _transparentPngDataUrl,
      );
      expect(entry.imagePath, isNotNull);

      final entriesSeenByB = await repositoryB.loadEntries(
        userA.id,
        forceRefresh: true,
      );
      expect(entriesSeenByB, isEmpty);

      final drinksSeenByB = await repositoryB.loadCustomDrinks(
        userA.id,
        forceRefresh: true,
      );
      expect(drinksSeenByB, isEmpty);

      await expectLater(
        repositoryB.saveSettings(
          userA.id,
          (await repositoryB.loadSettings(userB.id)).copyWith(unit: AppUnit.oz),
        ),
        throwsA(isA<AppException>()),
      );

      await expectLater(
        clientB.storage.from('user-media').download(entry.imagePath!),
        throwsA(isA<StorageException>()),
      );

      // A cross-user delete must fail and must not remove user A's data.
      await expectLater(
        repositoryB.deleteDrinkEntry(userId: userA.id, entry: entry),
        throwsA(isA<AppException>()),
      );
      final entriesSeenByA = await repositoryA.loadEntries(
        userA.id,
        forceRefresh: true,
      );
      expect(entriesSeenByA.where((e) => e.id == entry.id), isNotEmpty);

      await repositoryA.deleteDrinkEntry(userId: userA.id, entry: entry);
      await repositoryA.deleteCustomDrink(userId: userA.id, drink: customDrink);
    });
  }, skip: skipReason);
}
