import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/catalog_models.dart';
import 'package:glasstrail/src/achievements/repository_models.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalAppRepository> _buildRepository() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  return LocalAppRepository(preferences);
}

void main() {
  group('LocalAppRepository achievements', () {
    test('upserting grants a fresh unlock and is idempotent', () async {
      final repository = await _buildRepository();
      final grant = AchievementUnlockGrant(
        familyId: 'type_beer',
        level: 10,
        qualifiedAt: DateTime(2026, 1, 1),
        source: AchievementUnlockSource.realtimeLog,
      );

      final first = await repository.upsertAchievementUnlocks(
        userId: 'user-1',
        grants: <AchievementUnlockGrant>[grant],
      );
      expect(first, hasLength(1));
      expect(first.single.familyId, 'type_beer');
      expect(first.single.level, 10);

      // Re-running the same grant must not create a duplicate.
      final second = await repository.upsertAchievementUnlocks(
        userId: 'user-1',
        grants: <AchievementUnlockGrant>[grant],
      );
      expect(second, hasLength(1));

      final loaded = await repository.loadAchievementUnlocks('user-1');
      expect(loaded, hasLength(1));
    });

    test('upsert keeps the earliest qualifiedAt on conflict', () async {
      final repository = await _buildRepository();
      await repository.upsertAchievementUnlocks(
        userId: 'user-1',
        grants: <AchievementUnlockGrant>[
          AchievementUnlockGrant(
            familyId: 'type_beer',
            level: 10,
            qualifiedAt: DateTime(2026, 2, 1),
            source: AchievementUnlockSource.realtimeLog,
          ),
        ],
      );

      await repository.upsertAchievementUnlocks(
        userId: 'user-1',
        grants: <AchievementUnlockGrant>[
          AchievementUnlockGrant(
            familyId: 'type_beer',
            level: 10,
            qualifiedAt: DateTime(2026, 1, 1), // earlier
            source: AchievementUnlockSource.backfill,
          ),
        ],
      );

      final loaded = await repository.loadAchievementUnlocks('user-1');
      expect(loaded.single.qualifiedAt, DateTime(2026, 1, 1));
    });

    test('markAchievementUnlocksSurfaced only touches matching refs once', () async {
      final repository = await _buildRepository();
      await repository.upsertAchievementUnlocks(
        userId: 'user-1',
        grants: <AchievementUnlockGrant>[
          AchievementUnlockGrant(
            familyId: 'type_beer',
            level: 10,
            qualifiedAt: DateTime(2026, 1, 1),
            source: AchievementUnlockSource.realtimeLog,
          ),
          AchievementUnlockGrant(
            familyId: 'type_wine',
            level: 10,
            qualifiedAt: DateTime(2026, 1, 1),
            source: AchievementUnlockSource.realtimeLog,
          ),
        ],
      );

      await repository.markAchievementUnlocksSurfaced(
        userId: 'user-1',
        unlocks: <AchievementUnlockRef>[
          const AchievementUnlockRef(familyId: 'type_beer', level: 10),
        ],
      );

      final loaded = await repository.loadAchievementUnlocks('user-1');
      final beer = loaded.firstWhere((u) => u.familyId == 'type_beer');
      final wine = loaded.firstWhere((u) => u.familyId == 'type_wine');
      expect(beer.surfacedAt, isNotNull);
      expect(wine.surfacedAt, isNull);
    });

    test('user scopes are fully isolated', () async {
      final repository = await _buildRepository();
      await repository.upsertAchievementUnlocks(
        userId: 'user-1',
        grants: <AchievementUnlockGrant>[
          AchievementUnlockGrant(
            familyId: 'type_beer',
            level: 10,
            qualifiedAt: DateTime(2026, 1, 1),
            source: AchievementUnlockSource.realtimeLog,
          ),
        ],
      );
      expect(await repository.loadAchievementUnlocks('user-2'), isEmpty);
    });
  });

  group('LocalAppRepository saved places', () {
    test('replacing an active place archives the previous one', () async {
      final repository = await _buildRepository();
      final home1 = await repository.replaceActiveSavedPlace(
        userId: 'user-1',
        placeType: SavedPlaceType.home,
        latitude: 52.5,
        longitude: 13.4,
      );
      expect(home1.isActive, isTrue);

      final home2 = await repository.replaceActiveSavedPlace(
        userId: 'user-1',
        placeType: SavedPlaceType.home,
        latitude: 48.1,
        longitude: 11.5,
      );

      final places = await repository.loadSavedPlaces(
        userId: 'user-1',
        placeType: SavedPlaceType.home,
      );
      expect(places, hasLength(2));
      final archived = places.firstWhere((p) => p.id == home1.id);
      final active = places.firstWhere((p) => p.id == home2.id);
      expect(archived.isActive, isFalse);
      expect(archived.archivedAt, isNotNull);
      expect(active.isActive, isTrue);
    });

    test('deleting a place removes it without touching others', () async {
      final repository = await _buildRepository();
      final home = await repository.replaceActiveSavedPlace(
        userId: 'user-1',
        placeType: SavedPlaceType.home,
        latitude: 52.5,
        longitude: 13.4,
      );
      final work = await repository.replaceActiveSavedPlace(
        userId: 'user-1',
        placeType: SavedPlaceType.work,
        latitude: 52.6,
        longitude: 13.5,
      );

      await repository.deleteSavedPlace(userId: 'user-1', placeId: home.id);

      final places = await repository.loadSavedPlaces(userId: 'user-1');
      expect(places.map((p) => p.id), <String>[work.id]);
    });

    test('home and work do not interfere with each other', () async {
      final repository = await _buildRepository();
      await repository.replaceActiveSavedPlace(
        userId: 'user-1',
        placeType: SavedPlaceType.home,
        latitude: 52.5,
        longitude: 13.4,
      );
      await repository.replaceActiveSavedPlace(
        userId: 'user-1',
        placeType: SavedPlaceType.work,
        latitude: 52.6,
        longitude: 13.5,
      );

      final homes = await repository.loadSavedPlaces(
        userId: 'user-1',
        placeType: SavedPlaceType.home,
      );
      final works = await repository.loadSavedPlaces(
        userId: 'user-1',
        placeType: SavedPlaceType.work,
      );
      expect(homes, hasLength(1));
      expect(works, hasLength(1));
    });
  });
}
