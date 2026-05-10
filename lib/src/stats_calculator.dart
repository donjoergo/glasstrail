import 'models.dart';

enum StreakMessageState { start, keepAlive, startedToday, continuedToday }

extension StreakMessageStateX on StreakMessageState {
  String get storageValue => name;

  static StreakMessageState fromStorage(String? value) {
    return StreakMessageState.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => StreakMessageState.start,
    );
  }
}

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': _dateOnlyString(date),
      'weekday': weekday,
      'hasEntry': hasEntry,
      'isToday': isToday,
    };
  }

  factory WeekProgressDay.fromJson(Map<String, dynamic> json) {
    return WeekProgressDay(
      date: DateTime.parse(json['date'] as String),
      weekday: json['weekday'] as int,
      hasEntry: json['hasEntry'] == true,
      isToday: json['isToday'] == true,
    );
  }
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
    required this.beerTotalCount,
    required this.regularBeerCount,
    required this.alcoholFreeBeerCount,
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
  final int beerTotalCount;
  final int regularBeerCount;
  final int alcoholFreeBeerCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'weeklyTotal': weeklyTotal,
      'monthlyTotal': monthlyTotal,
      'yearlyTotal': yearlyTotal,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'bestStreakStart': bestStreakStart == null
          ? null
          : _dateOnlyString(bestStreakStart!),
      'bestStreakEnd': bestStreakEnd == null
          ? null
          : _dateOnlyString(bestStreakEnd!),
      'hasEntryToday': hasEntryToday,
      'streakThroughYesterday': streakThroughYesterday,
      'streakMessageState': streakMessageState.storageValue,
      'weekProgress': weekProgress
          .map((day) => day.toJson())
          .toList(growable: false),
      'categoryCounts': <String, int>{
        for (final entry in categoryCounts.entries)
          entry.key.storageValue: entry.value,
      },
      'totalEntries': totalEntries,
      'beerTotalCount': beerTotalCount,
      'regularBeerCount': regularBeerCount,
      'alcoholFreeBeerCount': alcoholFreeBeerCount,
    };
  }

  factory AppStatistics.fromJson(Map<String, dynamic> json) {
    final categoryCountsJson = json['categoryCounts'] is Map
        ? Map<String, dynamic>.from(json['categoryCounts'] as Map)
        : const <String, dynamic>{};
    return AppStatistics(
      weeklyTotal: (json['weeklyTotal'] as num?)?.toInt() ?? 0,
      monthlyTotal: (json['monthlyTotal'] as num?)?.toInt() ?? 0,
      yearlyTotal: (json['yearlyTotal'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      bestStreakStart: _dateFromJson(json['bestStreakStart']),
      bestStreakEnd: _dateFromJson(json['bestStreakEnd']),
      hasEntryToday: json['hasEntryToday'] == true,
      streakThroughYesterday:
          (json['streakThroughYesterday'] as num?)?.toInt() ?? 0,
      streakMessageState: StreakMessageStateX.fromStorage(
        json['streakMessageState'] as String?,
      ),
      weekProgress:
          (json['weekProgress'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) => WeekProgressDay.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false),
      categoryCounts: <DrinkCategory, int>{
        for (final category in DrinkCategory.values)
          category:
              (categoryCountsJson[category.storageValue] as num?)?.toInt() ?? 0,
      },
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      beerTotalCount: (json['beerTotalCount'] as num?)?.toInt() ?? 0,
      regularBeerCount: (json['regularBeerCount'] as num?)?.toInt() ?? 0,
      alcoholFreeBeerCount:
          (json['alcoholFreeBeerCount'] as num?)?.toInt() ?? 0,
    );
  }
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
    var beerTotalCount = 0;
    var alcoholFreeBeerCount = 0;

    for (final entry in entries) {
      final entryDay = DateTime(
        entry.consumedAt.year,
        entry.consumedAt.month,
        entry.consumedAt.day,
      );
      categoryCounts[entry.category] =
          (categoryCounts[entry.category] ?? 0) + 1;
      if (entry.category == DrinkCategory.beer) {
        beerTotalCount++;
        if (entry.isAlcoholFree) {
          alcoholFreeBeerCount++;
        }
      }
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
      beerTotalCount: beerTotalCount,
      regularBeerCount: beerTotalCount - alcoholFreeBeerCount,
      alcoholFreeBeerCount: alcoholFreeBeerCount,
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

DateTime? _dateFromJson(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.parse(value);
}

String _dateOnlyString(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
