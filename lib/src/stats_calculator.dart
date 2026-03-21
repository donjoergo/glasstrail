import 'models.dart';

enum StreakMessageState { start, keepAlive, startedToday, continuedToday }

class WeekProgressDay {
  const WeekProgressDay({
    required this.date,
    required this.weekday,
    required this.hasEntry,
    required this.isToday,
  });

  final DateTime date;
  final int weekday;
  final bool hasEntry;
  final bool isToday;
}

class AppStatistics {
  const AppStatistics({
    required this.weeklyTotal,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.currentStreak,
    required this.bestStreak,
    required this.bestStreakStart,
    required this.bestStreakEnd,
    required this.hasEntryToday,
    required this.streakThroughYesterday,
    required this.streakMessageState,
    required this.weekProgress,
    required this.categoryCounts,
    required this.totalEntries,
  });

  final int weeklyTotal;
  final int monthlyTotal;
  final int yearlyTotal;
  final int currentStreak;
  final int bestStreak;
  final DateTime? bestStreakStart;
  final DateTime? bestStreakEnd;
  final bool hasEntryToday;
  final int streakThroughYesterday;
  final StreakMessageState streakMessageState;
  final List<WeekProgressDay> weekProgress;
  final int totalEntries;
  final Map<DrinkCategory, int> categoryCounts;
}

class StatsCalculator {
  const StatsCalculator._();

  static AppStatistics fromEntries(List<DrinkEntry> entries, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final categoryCounts = <DrinkCategory, int>{
      for (final category in DrinkCategory.values) category: 0,
    };

    var weeklyTotal = 0;
    var monthlyTotal = 0;
    var yearlyTotal = 0;

    for (final entry in entries) {
      final entryDay = DateTime(
        entry.consumedAt.year,
        entry.consumedAt.month,
        entry.consumedAt.day,
      );
      categoryCounts[entry.category] =
          (categoryCounts[entry.category] ?? 0) + 1;
      if (!entryDay.isBefore(weekStart)) {
        weeklyTotal++;
      }
      if (entry.consumedAt.year == reference.year &&
          entry.consumedAt.month == reference.month) {
        monthlyTotal++;
      }
      if (entry.consumedAt.year == reference.year) {
        yearlyTotal++;
      }
    }

    final uniqueDays =
        entries
            .map(
              (entry) => DateTime(
                entry.consumedAt.year,
                entry.consumedAt.month,
                entry.consumedAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    var bestStreak = 0;
    DateTime? bestStreakStart;
    DateTime? bestStreakEnd;
    var rolling = 0;
    DateTime? previous;
    DateTime? rollingStart;
    for (final day in uniqueDays) {
      if (previous == null || day.difference(previous).inDays > 1) {
        rolling = 1;
        rollingStart = day;
      } else if (day.difference(previous).inDays == 1) {
        rolling++;
      }
      previous = day;
      if (rolling > bestStreak || (rolling == bestStreak && rolling > 0)) {
        bestStreak = rolling;
        bestStreakStart = rollingStart;
        bestStreakEnd = day;
      }
    }

    final daySet = uniqueDays.toSet();
    final hasEntryToday = daySet.contains(today);
    var currentStreak = 0;
    var cursor = today;
    while (daySet.contains(cursor)) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final yesterday = today.subtract(const Duration(days: 1));
    final streakThroughYesterday = _countStreakFrom(daySet, yesterday);
    final weekProgress = List<WeekProgressDay>.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      return WeekProgressDay(
        date: date,
        weekday: date.weekday,
        hasEntry: daySet.contains(date),
        isToday: date == today,
      );
    }, growable: false);

    final streakMessageState = switch (currentStreak) {
      0 when streakThroughYesterday > 0 => StreakMessageState.keepAlive,
      0 => StreakMessageState.start,
      1 => StreakMessageState.startedToday,
      _ => StreakMessageState.continuedToday,
    };

    return AppStatistics(
      weeklyTotal: weeklyTotal,
      monthlyTotal: monthlyTotal,
      yearlyTotal: yearlyTotal,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      bestStreakStart: bestStreakStart,
      bestStreakEnd: bestStreakEnd,
      hasEntryToday: hasEntryToday,
      streakThroughYesterday: streakThroughYesterday,
      streakMessageState: streakMessageState,
      weekProgress: weekProgress,
      categoryCounts: categoryCounts,
      totalEntries: entries.length,
    );
  }

  static int _countStreakFrom(Set<DateTime> daySet, DateTime start) {
    var streak = 0;
    var cursor = start;
    while (daySet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
