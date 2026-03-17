import 'models.dart';

class AppStatistics {
  const AppStatistics({
    required this.weeklyTotal,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.currentStreak,
    required this.bestStreak,
    required this.categoryCounts,
    required this.totalEntries,
  });

  final int weeklyTotal;
  final int monthlyTotal;
  final int yearlyTotal;
  final int currentStreak;
  final int bestStreak;
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
      categoryCounts[entry.category] = (categoryCounts[entry.category] ?? 0) + 1;
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

    final uniqueDays = entries
        .map((entry) => DateTime(entry.consumedAt.year, entry.consumedAt.month, entry.consumedAt.day))
        .toSet()
        .toList()
      ..sort();

    var bestStreak = 0;
    var rolling = 0;
    DateTime? previous;
    for (final day in uniqueDays) {
      if (previous == null || day.difference(previous).inDays > 1) {
        rolling = 1;
      } else if (day.difference(previous).inDays == 1) {
        rolling++;
      }
      previous = day;
      if (rolling > bestStreak) {
        bestStreak = rolling;
      }
    }

    final daySet = uniqueDays.toSet();
    var currentStreak = 0;
    var cursor = today;
    while (daySet.contains(cursor)) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return AppStatistics(
      weeklyTotal: weeklyTotal,
      monthlyTotal: monthlyTotal,
      yearlyTotal: yearlyTotal,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      categoryCounts: categoryCounts,
      totalEntries: entries.length,
    );
  }
}
