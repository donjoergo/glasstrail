import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/evaluator.dart';
import 'package:glasstrail/src/models.dart';

AchievementEntry _entry({String? countryCode}) {
  return AchievementEntry(
    category: DrinkCategory.beer,
    isAlcoholFree: false,
    achievementLocalDate: DateTime(2026, 1, 1),
    countryCode: countryCode,
  );
}

void main() {
  group('travel and country evaluators', () {
    test('travel starts at 3 countries, not 1', () {
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.travelCountries)!;
      expect(family.levels.first.threshold, 3);
    });

    test('travel counts unique identifiable countries worldwide', () {
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.travelCountries)!;
      final List<AchievementEntry> entries = <AchievementEntry>[
        _entry(countryCode: 'de'),
        _entry(countryCode: 'de'),
        _entry(countryCode: 'xx'), // non-curated country still counts for travel
        _entry(countryCode: 'yy'),
        _entry(countryCode: null),
      ];
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));
      final result = evaluateFamily(family, ctx);
      expect(result.liveValue, 3); // de, xx, yy
    });

    test('non-curated countries count for travel but do not create country badges', () {
      expect(curatedCountryCodes.contains('xx'), isFalse);
      expect(achievementCatalog.where((AchievementFamily f) => f.countryCode == 'xx'), isEmpty);
    });

    test('country badge unlocks from any qualifying drink in that country', () {
      final AchievementFamily germany = achievementFamilyById('country_de')!;
      final List<AchievementEntry> entries = <AchievementEntry>[_entry(countryCode: 'de')];
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));
      final result = evaluateFamily(germany, ctx);
      expect(result.liveValue, 1);
      expect(result.qualifyingLevels(germany.levels), <int>{1});
    });

    test('country badge does not unlock without a matching entry', () {
      final AchievementFamily japan = achievementFamilyById('country_jp')!;
      final List<AchievementEntry> entries = <AchievementEntry>[_entry(countryCode: 'de')];
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));
      final result = evaluateFamily(japan, ctx);
      expect(result.liveValue, 0);
    });
  });
}
