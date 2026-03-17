import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/stats_calculator.dart';

void main() {
  group('StatsCalculator', () {
    test('computes totals, streaks, and category counts', () {
      final now = DateTime(2026, 3, 17, 12);
      final entries = <DrinkEntry>[
        DrinkEntry(
          id: '1',
          userId: 'u1',
          drinkId: 'water',
          drinkName: 'Water',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 17, 9),
        ),
        DrinkEntry(
          id: '2',
          userId: 'u1',
          drinkId: 'cola',
          drinkName: 'Cola',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 16, 9),
        ),
        DrinkEntry(
          id: '3',
          userId: 'u1',
          drinkId: 'pils',
          drinkName: 'Pils',
          category: DrinkCategory.beer,
          consumedAt: DateTime(2026, 3, 15, 9),
        ),
        DrinkEntry(
          id: '4',
          userId: 'u1',
          drinkId: 'wine',
          drinkName: 'Red Wine',
          category: DrinkCategory.wine,
          consumedAt: DateTime(2026, 2, 10, 9),
        ),
        DrinkEntry(
          id: '5',
          userId: 'u1',
          drinkId: 'tea',
          drinkName: 'Tea',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2025, 12, 25, 9),
        ),
      ];

      final stats = StatsCalculator.fromEntries(entries, now: now);

      expect(stats.weeklyTotal, 2);
      expect(stats.monthlyTotal, 3);
      expect(stats.yearlyTotal, 4);
      expect(stats.currentStreak, 3);
      expect(stats.bestStreak, 3);
      expect(stats.totalEntries, 5);
      expect(stats.categoryCounts[DrinkCategory.nonAlcoholic], 3);
      expect(stats.categoryCounts[DrinkCategory.beer], 1);
      expect(stats.categoryCounts[DrinkCategory.wine], 1);
    });

    test('returns zero current streak when today is missing', () {
      final now = DateTime(2026, 3, 17, 12);
      final entries = <DrinkEntry>[
        DrinkEntry(
          id: '1',
          userId: 'u1',
          drinkId: 'water',
          drinkName: 'Water',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 16, 9),
        ),
      ];

      final stats = StatsCalculator.fromEntries(entries, now: now);

      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 1);
    });
  });
}
