import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/evaluator.dart';
import 'package:glasstrail/src/models.dart';

AchievementEntry _entry(DrinkCategory category, {int day = 1}) {
  return AchievementEntry(
    category: category,
    isAlcoholFree: category == DrinkCategory.nonAlcoholic,
    achievementLocalDate: DateTime(2026, 1, day),
  );
}

void main() {
  group('simple ladder evaluators', () {
    test('total-drink thresholds unlock correctly', () {
      final List<AchievementEntry> entries = List<AchievementEntry>.generate(
        25,
        (int i) => _entry(DrinkCategory.beer, day: i + 1),
      );
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.totalDrinks)!;
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));
      final LadderEvaluationResult result = evaluateFamily(family, ctx);
      expect(result.liveValue, 25);
      expect(result.qualifyingLevels(family.levels), <int>{1, 10, 25});
    });

    test('each drink type counts only matching entries', () {
      final List<AchievementEntry> entries = <AchievementEntry>[
        _entry(DrinkCategory.beer),
        _entry(DrinkCategory.beer),
        _entry(DrinkCategory.wine),
      ];
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));

      final AchievementFamily beer = achievementFamilyById(AchievementFamilyIds.typeBeer)!;
      final AchievementFamily wine = achievementFamilyById(AchievementFamilyIds.typeWine)!;
      expect(evaluateFamily(beer, ctx).liveValue, 2);
      expect(evaluateFamily(wine, ctx).liveValue, 1);
    });

    test('hidden drinks/categories still count if represented in entry data', () {
      // The evaluator has no concept of "hidden" at all -- hidden-ness is a
      // display-layer filter applied elsewhere. Any entry present in the
      // input list counts, proving hidden entries are not silently dropped
      // here.
      final List<AchievementEntry> entries = <AchievementEntry>[
        _entry(DrinkCategory.beer),
        _entry(DrinkCategory.beer),
      ];
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));
      final AchievementFamily beer = achievementFamilyById(AchievementFamilyIds.typeBeer)!;
      expect(evaluateFamily(beer, ctx).liveValue, 2);
    });

    test('editing an entry category changes future progress in the evaluator result', () {
      final List<AchievementEntry> before = <AchievementEntry>[_entry(DrinkCategory.beer)];
      final List<AchievementEntry> after = <AchievementEntry>[_entry(DrinkCategory.wine)];
      final AchievementFamily beer = achievementFamilyById(AchievementFamilyIds.typeBeer)!;
      final AchievementFamily wine = achievementFamilyById(AchievementFamilyIds.typeWine)!;

      final AchievementEvaluationContext beforeCtx =
          AchievementEvaluationContext(entries: before, now: DateTime(2026, 2, 1));
      final AchievementEvaluationContext afterCtx =
          AchievementEvaluationContext(entries: after, now: DateTime(2026, 2, 1));

      expect(evaluateFamily(beer, beforeCtx).liveValue, 1);
      expect(evaluateFamily(wine, beforeCtx).liveValue, 0);
      expect(evaluateFamily(beer, afterCtx).liveValue, 0);
      expect(evaluateFamily(wine, afterCtx).liveValue, 1);
    });

    test('mergeFamilyProgress keeps earned levels permanent below live value', () {
      final AchievementFamily beer = achievementFamilyById(AchievementFamilyIds.typeBeer)!;
      final LadderEvaluationResult result =
          const LadderEvaluationResult(familyId: AchievementFamilyIds.typeBeer, liveValue: 5, qualifyingValue: 5);
      final AchievementFamilyProgress progress = mergeFamilyProgress(
        family: beer,
        result: result,
        persistedEarnedLevels: <int>{10},
      );
      expect(progress.earnedLevels, contains(10));
      expect(progress.currentValue, 5);
      expect(progress.nextLevel, 25);
    });
  });
}
