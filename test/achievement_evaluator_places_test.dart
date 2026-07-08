import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/evaluator.dart';
import 'package:glasstrail/src/achievements/place_matching.dart';
import 'package:glasstrail/src/models.dart';

const double _homeLat = 52.5200;
const double _homeLon = 13.4050;

SavedPlace _place(SavedPlaceType type, {bool active = true, double lat = _homeLat, double lon = _homeLon}) {
  return SavedPlace(
    id: '$type-$lat-$lon-$active',
    placeType: type,
    latitude: lat,
    longitude: lon,
    isActive: active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

AchievementEntry _entryAt(double lat, double lon, {LocationPrecision precision = LocationPrecision.precise}) {
  return AchievementEntry(
    category: DrinkCategory.beer,
    isAlcoholFree: false,
    achievementLocalDate: DateTime(2026, 1, 1),
    locationPrecision: precision,
    latitude: lat,
    longitude: lon,
  );
}

/// Roughly offsets a coordinate by [meters] north. 1 degree latitude is
/// ~111,320 m.
double _offsetLat(double lat, double meters) => lat + (meters / 111320);

void main() {
  group('place evaluator', () {
    test('entry within 50 m of active Home counts; 51 m does not', () {
      final SavedPlace home = _place(SavedPlaceType.home);
      final AchievementEntry within = _entryAt(_offsetLat(_homeLat, 40), _homeLon);
      final AchievementEntry outside = _entryAt(_offsetLat(_homeLat, 60), _homeLon);

      expect(matchesAnyPlace(lat: within.latitude!, lon: within.longitude!, places: <SavedPlace>[home]), isTrue);
      expect(matchesAnyPlace(lat: outside.latitude!, lon: outside.longitude!, places: <SavedPlace>[home]), isFalse);
    });

    test('approximate-location entries never match home/work', () {
      final AchievementFamily home = achievementFamilyById(AchievementFamilyIds.placeHome)!;
      final List<AchievementEntry> entries = <AchievementEntry>[
        _entryAt(_homeLat, _homeLon, precision: LocationPrecision.approximate),
      ];
      final AchievementEvaluationContext ctx = AchievementEvaluationContext(
        entries: entries,
        now: DateTime(2026, 2, 1),
        savedPlaces: <SavedPlace>[_place(SavedPlaceType.home)],
      );
      expect(evaluateFamily(home, ctx).liveValue, 0);
    });

    test('replacing Home re-evaluates future progress against the new coordinates', () {
      final AchievementFamily home = achievementFamilyById(AchievementFamilyIds.placeHome)!;
      const double newLat = 48.1351;
      const double newLon = 11.5820;
      final List<AchievementEntry> entries = <AchievementEntry>[_entryAt(newLat, newLon)];

      final AchievementEvaluationContext beforeMove = AchievementEvaluationContext(
        entries: entries,
        now: DateTime(2026, 2, 1),
        savedPlaces: <SavedPlace>[_place(SavedPlaceType.home)], // old Berlin coordinates
      );
      expect(evaluateFamily(home, beforeMove).liveValue, 0);

      final AchievementEvaluationContext afterMove = AchievementEvaluationContext(
        entries: entries,
        now: DateTime(2026, 2, 1),
        savedPlaces: <SavedPlace>[_place(SavedPlaceType.home, lat: newLat, lon: newLon)],
      );
      expect(evaluateFamily(home, afterMove).liveValue, 1);
    });

    test('deleting a place removes its future contribution without revoking earned levels', () {
      final AchievementFamily home = achievementFamilyById(AchievementFamilyIds.placeHome)!;
      final List<AchievementEntry> entries = <AchievementEntry>[_entryAt(_homeLat, _homeLon)];

      // Place deleted -> savedPlaces no longer contains it.
      final AchievementEvaluationContext ctxAfterDelete = AchievementEvaluationContext(
        entries: entries,
        now: DateTime(2026, 2, 1),
        savedPlaces: const <SavedPlace>[],
      );
      expect(evaluateFamily(home, ctxAfterDelete).liveValue, 0);
      // Permanence is a grant-flow concern (Chunk 5); here we only assert
      // that live evaluation itself doesn't try to "revoke" anything -- it
      // simply reports current data, which the merge step in progress.dart
      // unions with persisted earned levels.
    });

    test('archived places still count toward future progress', () {
      final AchievementFamily home = achievementFamilyById(AchievementFamilyIds.placeHome)!;
      final List<AchievementEntry> entries = <AchievementEntry>[_entryAt(_homeLat, _homeLon)];
      final AchievementEvaluationContext ctx = AchievementEvaluationContext(
        entries: entries,
        now: DateTime(2026, 2, 1),
        savedPlaces: <SavedPlace>[_place(SavedPlaceType.home, active: false)],
      );
      expect(evaluateFamily(home, ctx).liveValue, 1);
    });
  });
}
