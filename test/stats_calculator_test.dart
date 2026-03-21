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
      expect(stats.bestStreakStart, DateTime(2026, 3, 15));
      expect(stats.bestStreakEnd, DateTime(2026, 3, 17));
      expect(stats.hasEntryToday, isTrue);
      expect(stats.streakThroughYesterday, 2);
      expect(stats.streakMessageState, StreakMessageState.continuedToday);
      expect(stats.totalEntries, 5);
      expect(stats.categoryCounts[DrinkCategory.nonAlcoholic], 3);
      expect(stats.categoryCounts[DrinkCategory.beer], 1);
      expect(stats.categoryCounts[DrinkCategory.wine], 1);
      expect(stats.weekProgress.map((day) => day.weekday), <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ]);
      expect(stats.weekProgress[0].hasEntry, isTrue);
      expect(stats.weekProgress[1].hasEntry, isTrue);
      expect(stats.weekProgress[1].isToday, isTrue);
      expect(stats.weekProgress[2].hasEntry, isFalse);
      expect(stats.weekProgress[6].hasEntry, isFalse);
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
      expect(stats.bestStreakStart, DateTime(2026, 3, 16));
      expect(stats.bestStreakEnd, DateTime(2026, 3, 16));
      expect(stats.hasEntryToday, isFalse);
      expect(stats.streakThroughYesterday, 1);
      expect(stats.streakMessageState, StreakMessageState.keepAlive);
    });

    test(
      'returns start prompt state when there is no active streak to preserve',
      () {
        final now = DateTime(2026, 3, 17, 12);
        final entries = <DrinkEntry>[
          DrinkEntry(
            id: '1',
            userId: 'u1',
            drinkId: 'water',
            drinkName: 'Water',
            category: DrinkCategory.nonAlcoholic,
            consumedAt: DateTime(2026, 3, 14, 9),
          ),
        ];

        final stats = StatsCalculator.fromEntries(entries, now: now);

        expect(stats.currentStreak, 0);
        expect(stats.bestStreakStart, DateTime(2026, 3, 14));
        expect(stats.bestStreakEnd, DateTime(2026, 3, 14));
        expect(stats.streakThroughYesterday, 0);
        expect(stats.streakMessageState, StreakMessageState.start);
      },
    );

    test('returns started-today prompt state for a fresh streak', () {
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
      ];

      final stats = StatsCalculator.fromEntries(entries, now: now);

      expect(stats.currentStreak, 1);
      expect(stats.hasEntryToday, isTrue);
      expect(stats.bestStreakStart, DateTime(2026, 3, 17));
      expect(stats.bestStreakEnd, DateTime(2026, 3, 17));
      expect(stats.streakThroughYesterday, 0);
      expect(stats.streakMessageState, StreakMessageState.startedToday);
    });

    test(
      'marks a weekday once even when multiple drinks were logged that day',
      () {
        final now = DateTime(2026, 3, 19, 12);
        final entries = <DrinkEntry>[
          DrinkEntry(
            id: '1',
            userId: 'u1',
            drinkId: 'water',
            drinkName: 'Water',
            category: DrinkCategory.nonAlcoholic,
            consumedAt: DateTime(2026, 3, 19, 9),
          ),
          DrinkEntry(
            id: '2',
            userId: 'u1',
            drinkId: 'tea',
            drinkName: 'Tea',
            category: DrinkCategory.nonAlcoholic,
            consumedAt: DateTime(2026, 3, 19, 18),
          ),
        ];

        final stats = StatsCalculator.fromEntries(entries, now: now);

        expect(stats.currentStreak, 1);
        expect(stats.bestStreakStart, DateTime(2026, 3, 19));
        expect(stats.bestStreakEnd, DateTime(2026, 3, 19));
        expect(stats.weekProgress.where((day) => day.hasEntry), hasLength(1));
        expect(
          stats.weekProgress.singleWhere((day) => day.hasEntry).weekday,
          DateTime.thursday,
        );
      },
    );

    test('prefers the most recent range when multiple best streaks tie', () {
      final now = DateTime(2026, 3, 20, 12);
      final entries = <DrinkEntry>[
        DrinkEntry(
          id: '1',
          userId: 'u1',
          drinkId: 'water',
          drinkName: 'Water',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 1, 9),
        ),
        DrinkEntry(
          id: '2',
          userId: 'u1',
          drinkId: 'tea',
          drinkName: 'Tea',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 2, 9),
        ),
        DrinkEntry(
          id: '3',
          userId: 'u1',
          drinkId: 'cola',
          drinkName: 'Cola',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 10, 9),
        ),
        DrinkEntry(
          id: '4',
          userId: 'u1',
          drinkId: 'juice',
          drinkName: 'Juice',
          category: DrinkCategory.nonAlcoholic,
          consumedAt: DateTime(2026, 3, 11, 9),
        ),
      ];

      final stats = StatsCalculator.fromEntries(entries, now: now);

      expect(stats.bestStreak, 2);
      expect(stats.bestStreakStart, DateTime(2026, 3, 10));
      expect(stats.bestStreakEnd, DateTime(2026, 3, 11));
    });

    test('keeps the best streak range empty when there are no entries', () {
      final stats = StatsCalculator.fromEntries(
        const <DrinkEntry>[],
        now: DateTime(2026, 3, 17, 12),
      );

      expect(stats.bestStreak, 0);
      expect(stats.bestStreakStart, isNull);
      expect(stats.bestStreakEnd, isNull);
    });
  });
}
