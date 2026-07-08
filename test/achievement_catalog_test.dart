import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/catalog.dart';

void main() {
  group('achievement catalog', () {
    test('has no duplicate familyId + level pairs', () {
      final Set<AchievementUnlockRef> seen = <AchievementUnlockRef>{};
      for (final AchievementFamily family in achievementCatalog) {
        for (final AchievementLevelDef level in family.levels) {
          final AchievementUnlockRef ref = AchievementUnlockRef(
            familyId: family.familyId,
            level: level.level,
          );
          expect(
            seen.contains(ref),
            isFalse,
            reason: 'Duplicate catalog entry: $ref',
          );
          seen.add(ref);
        }
      }
    });

    test('category order matches spec.md', () {
      final List<AchievementCategory> seenOrder = <AchievementCategory>[];
      for (final AchievementFamily family in achievementCatalog) {
        if (seenOrder.isEmpty || seenOrder.last != family.category) {
          seenOrder.add(family.category);
        }
      }
      expect(seenOrder, <AchievementCategory>[
        AchievementCategory.totals,
        AchievementCategory.streaks,
        AchievementCategory.drinkTypes,
        AchievementCategory.occasions,
        AchievementCategory.places,
        AchievementCategory.travel,
        AchievementCategory.countries,
      ]);
    });

    test('every catalog entry has a title key, description key, and art key', () {
      for (final AchievementFamily family in achievementCatalog) {
        expect(family.familyTitleKey, isNotEmpty);
        expect(family.coverArtKey, isNotEmpty);
        for (final AchievementLevelDef level in family.levels) {
          expect(level.titleKey, isNotEmpty);
          expect(level.descriptionKey, isNotEmpty);
          expect(level.artKey, isNotEmpty);
        }
      }
    });

    test('country catalog contains exactly the 27 curated country badges', () {
      final List<AchievementFamily> countryFamilies = achievementCatalog
          .where((AchievementFamily f) => f.kind == AchievementKind.oneOffCountry)
          .toList();
      expect(countryFamilies, hasLength(27));
      expect(curatedCountryCodes, hasLength(27));
      for (final AchievementFamily family in countryFamilies) {
        expect(family.countryCode, isNotNull);
        expect(family.countryLabelKey, isNotNull);
        expect(family.levels, hasLength(1));
        expect(family.levels.single.level, 1);
        expect(family.levels.single.threshold, isNull);
      }
    });

    test('occasion catalog has exactly the 9 locked occasion families', () {
      final List<AchievementFamily> occasionFamilies = achievementCatalog
          .where((AchievementFamily f) => f.kind == AchievementKind.oneOffOccasion)
          .toList();
      expect(occasionFamilies, hasLength(9));
      for (final AchievementFamily family in occasionFamilies) {
        expect(family.levels, hasLength(1));
        expect(family.levels.single.level, 1);
      }
    });

    test('total drinks thresholds match spec.md', () {
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.totalDrinks)!;
      expect(
        family.levels.map((AchievementLevelDef l) => l.threshold).toList(),
        <int>[1, 10, 25, 50, 100, 200, 300, 400, 500, 1000],
      );
    });

    test('streak thresholds match spec.md', () {
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.streaks)!;
      expect(
        family.levels.map((AchievementLevelDef l) => l.threshold).toList(),
        <int>[3, 7, 14, 30, 60, 90, 180, 365],
      );
    });

    test('drink type family thresholds all match spec.md', () {
      const List<int> expected = <int>[10, 25, 50, 100, 200, 300, 400, 500, 1000];
      for (final String familyId in <String>[
        AchievementFamilyIds.typeBeer,
        AchievementFamilyIds.typeWine,
        AchievementFamilyIds.typeSparklingWines,
        AchievementFamilyIds.typeLongdrinks,
        AchievementFamilyIds.typeSpirits,
        AchievementFamilyIds.typeShots,
        AchievementFamilyIds.typeCocktails,
        AchievementFamilyIds.typeAppleWines,
        AchievementFamilyIds.typeNonAlcoholic,
      ]) {
        final AchievementFamily family = achievementFamilyById(familyId)!;
        expect(
          family.levels.map((AchievementLevelDef l) => l.threshold).toList(),
          expected,
          reason: familyId,
        );
      }
    });

    test('home/work thresholds match spec.md', () {
      const List<int> expected = <int>[1, 10, 25, 50, 100];
      expect(
        achievementFamilyById(AchievementFamilyIds.placeHome)!
            .levels
            .map((AchievementLevelDef l) => l.threshold)
            .toList(),
        expected,
      );
      expect(
        achievementFamilyById(AchievementFamilyIds.placeWork)!
            .levels
            .map((AchievementLevelDef l) => l.threshold)
            .toList(),
        expected,
      );
    });

    test('travel countries thresholds match spec.md', () {
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.travelCountries)!;
      expect(
        family.levels.map((AchievementLevelDef l) => l.threshold).toList(),
        <int>[3, 5, 10, 15, 20, 30, 50],
      );
    });

    test('ladder families use level == threshold identity', () {
      for (final AchievementFamily family in achievementCatalog) {
        if (family.kind != AchievementKind.ladder) continue;
        for (final AchievementLevelDef level in family.levels) {
          expect(level.level, level.threshold);
        }
      }
    });

    test('oktoberfest date table covers 2026-2030 per spec.md', () {
      expect(oktoberfestDateRanges[2026], (9, 19, 10, 4));
      expect(oktoberfestDateRanges[2027], (9, 18, 10, 3));
      expect(oktoberfestDateRanges[2028], (9, 16, 10, 3));
      expect(oktoberfestDateRanges[2029], (9, 22, 10, 7));
      expect(oktoberfestDateRanges[2030], (9, 21, 10, 6));
    });
  });
}
