import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/evaluator.dart';
import 'package:glasstrail/src/achievements/streaks.dart';
import 'package:glasstrail/src/models.dart';

AchievementEntry _entryOn(DateTime date) {
  return AchievementEntry(
    category: DrinkCategory.beer,
    isAlcoholFree: false,
    achievementLocalDate: date,
  );
}

void main() {
  group('streak evaluator', () {
    test('computeStreaks finds best and current runs', () {
      final List<DateTime> dates = <DateTime>[
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
      ];
      final StreakResult result = computeStreaks(dates, today: DateTime(2026, 1, 8));
      expect(result.best, 4);
      expect(result.current, 4);
    });

    test('broken streak remains earned but current progress drops', () {
      final AchievementFamily family = achievementFamilyById(AchievementFamilyIds.streaks)!;
      final List<AchievementEntry> entries = <AchievementEntry>[
        for (int day = 1; day <= 7; day++) _entryOn(DateTime(2026, 1, day)),
        // gap, then a single day active streak far later
        _entryOn(DateTime(2026, 2, 1)),
      ];
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: entries, now: DateTime(2026, 2, 1));
      final LadderEvaluationResult result = evaluateFamily(family, ctx);

      // Best historical streak (7) still qualifies levels up to 7.
      expect(result.qualifyingValue, 7);
      expect(result.qualifyingLevels(family.levels), <int>{3, 7});
      // Live/current streak is only 1 day.
      expect(result.liveValue, 1);

      final AchievementFamilyProgress progress = mergeFamilyProgress(
        family: family,
        result: result,
        persistedEarnedLevels: <int>{3, 7},
      );
      // Earned levels stay permanent even though current streak dropped.
      expect(progress.earnedLevels, <int>{3, 7});
      expect(progress.currentValue, 1);
      expect(progress.nextLevel, 14);
    });

    test('deleting an entry can move current streak and best streak correctly', () {
      final List<AchievementEntry> withGapDay = <AchievementEntry>[
        _entryOn(DateTime(2026, 1, 1)),
        _entryOn(DateTime(2026, 1, 2)),
        _entryOn(DateTime(2026, 1, 3)),
      ];
      final StreakResult before = computeStreaks(
        withGapDay.map((AchievementEntry e) => e.achievementLocalDate),
        today: DateTime(2026, 1, 3),
      );
      expect(before.current, 3);

      // Delete the middle day.
      final List<AchievementEntry> afterDelete = <AchievementEntry>[
        _entryOn(DateTime(2026, 1, 1)),
        _entryOn(DateTime(2026, 1, 3)),
      ];
      final StreakResult after = computeStreaks(
        afterDelete.map((AchievementEntry e) => e.achievementLocalDate),
        today: DateTime(2026, 1, 3),
      );
      expect(after.current, 1);
      expect(after.best, 1);
    });

    test('no entry today means zero current streak', () {
      final List<AchievementEntry> entries = <AchievementEntry>[
        _entryOn(DateTime(2026, 1, 1)),
        _entryOn(DateTime(2026, 1, 2)),
      ];
      final StreakResult result = computeStreaks(
        entries.map((AchievementEntry e) => e.achievementLocalDate),
        today: DateTime(2026, 1, 5),
      );
      expect(result.current, 0);
      expect(result.best, 2);
    });
  });
}
