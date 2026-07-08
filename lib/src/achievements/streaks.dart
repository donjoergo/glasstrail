/// Pure streak math over a set of calendar dates.
///
/// Per `spec.md`: unlock eligibility uses the best historical streak;
/// live progress uses the current active streak. Both are recomputed live
/// from current data every time, never persisted.
library;

class StreakResult {
  const StreakResult({required this.best, required this.current});

  /// Longest run of consecutive calendar days with at least one entry,
  /// anywhere in history.
  final int best;

  /// Run of consecutive calendar days with at least one entry, ending on
  /// [today]. Zero if there is no entry on [today].
  final int current;
}

/// Computes best and current streaks from a set of local calendar dates
/// (time-of-day is ignored; callers should pass date-only values).
StreakResult computeStreaks(Iterable<DateTime> localDates, {required DateTime today}) {
  final DateTime todayOnly = DateTime(today.year, today.month, today.day);

  final Set<int> dayKeys = <int>{};
  for (final DateTime date in localDates) {
    dayKeys.add(_dayKey(DateTime(date.year, date.month, date.day)));
  }

  if (dayKeys.isEmpty) {
    return const StreakResult(best: 0, current: 0);
  }

  final List<int> sortedKeys = dayKeys.toList()..sort();
  final Set<int> keySet = dayKeys;

  int best = 1;
  int run = 1;
  for (int i = 1; i < sortedKeys.length; i++) {
    if (sortedKeys[i] == sortedKeys[i - 1] + 1) {
      run += 1;
    } else {
      run = 1;
    }
    if (run > best) {
      best = run;
    }
  }

  int current = 0;
  int cursor = _dayKey(todayOnly);
  while (keySet.contains(cursor)) {
    current += 1;
    cursor -= 1;
  }

  return StreakResult(best: best, current: current);
}

/// Days since the Dart epoch, used as a comparable/consecutive integer key
/// for calendar dates. Built via UTC construction so local DST transitions
/// never shift the day delta away from exactly 1.
int _dayKey(DateTime dateOnly) =>
    DateTime.utc(dateOnly.year, dateOnly.month, dateOnly.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
