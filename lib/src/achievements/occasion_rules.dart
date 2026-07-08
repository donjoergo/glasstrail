/// Pure date-window rules for occasion achievements.
///
/// Easter and Carnival use the Western (Gregorian) computus. Oktoberfest
/// uses the hardcoded `oktoberfestDateRanges` table from `catalog.dart`,
/// which only covers 2026-2030 per `spec.md`.
library;

import 'catalog.dart';

bool _isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [days] (may be negative) to a date-only [date], via UTC epoch-day
/// arithmetic so local DST transitions never shift the result by an hour.
DateTime _addDays(DateTime date, int days) {
  final DateTime utcResult =
      DateTime.utc(date.year, date.month, date.day).add(Duration(days: days));
  return DateTime(utcResult.year, utcResult.month, utcResult.day);
}

/// Matches [localDate] against a fixed annual `(month, day)`, applying the
/// locked `Feb 29 -> Feb 28` fallback in non-leap years. Used for both
/// birthday and first-sip-anniversary matching.
bool matchesAnnualMonthDay(DateTime localDate, DateTime monthDay) {
  int month = monthDay.month;
  int day = monthDay.day;
  if (month == 2 && day == 29 && !_isLeapYear(localDate.year)) {
    day = 28;
  }
  return localDate.month == month && localDate.day == day;
}

/// Western (Gregorian) computus: Easter Sunday for [year].
/// Anonymous Gregorian algorithm.
DateTime easterSunday(int year) {
  final int a = year % 19;
  final int b = year ~/ 100;
  final int c = year % 100;
  final int d = b ~/ 4;
  final int e = b % 4;
  final int f = (b + 8) ~/ 25;
  final int g = (b - f + 1) ~/ 3;
  final int h = (19 * a + b - d - g + 15) % 30;
  final int i = c ~/ 4;
  final int k = c % 4;
  final int l = (32 + 2 * e + 2 * i - h - k) % 7;
  final int m = (a + 11 * h + 22 * l) ~/ 451;
  final int month = (h + l - 7 * m + 114) ~/ 31;
  final int day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

DateTime goodFriday(int year) => _addDays(easterSunday(year), -2);
DateTime easterMonday(int year) => _addDays(easterSunday(year), 1);

/// Mardi Gras / Shrove Tuesday: the day before Ash Wednesday (46 days
/// before Easter Sunday), i.e. 47 days before Easter Sunday.
DateTime mardiGras(int year) => _addDays(easterSunday(year), -47);

/// Fat Thursday / Weiberfastnacht: the Thursday before Mardi Gras.
DateTime fatThursday(int year) => _addDays(mardiGras(year), -5);

bool _withinInclusive(DateTime date, DateTime start, DateTime end) {
  final DateTime d = _dateOnly(date);
  return !d.isBefore(_dateOnly(start)) && !d.isAfter(_dateOnly(end));
}

/// The hardcoded Oktoberfest window for [year], or `null` outside the
/// locked 2026-2030 table.
(DateTime start, DateTime end)? oktoberfestWindow(int year) {
  final (int, int, int, int)? range = oktoberfestDateRanges[year];
  if (range == null) return null;
  final (int startMonth, int startDay, int endMonth, int endDay) = range;
  return (DateTime(year, startMonth, startDay), DateTime(year, endMonth, endDay));
}

/// Evaluates whether a single entry qualifies for occasion family
/// [familyId] on [localDate] (a date-only value).
///
/// [birthdayMonthDay] and [firstSipAnniversaryMonthDay] carry only
/// month/day (any reference year); pass `null` when unset (setup-required).
bool occasionMatches({
  required String familyId,
  required DateTime localDate,
  required bool isBeer,
  DateTime? birthdayMonthDay,
  DateTime? firstSipAnniversaryMonthDay,
}) {
  final DateTime date = _dateOnly(localDate);
  switch (familyId) {
    case AchievementFamilyIds.occasionBirthday:
      return birthdayMonthDay != null && matchesAnnualMonthDay(date, birthdayMonthDay);
    case AchievementFamilyIds.occasionFirstSipAnniversary:
      return firstSipAnniversaryMonthDay != null &&
          matchesAnnualMonthDay(date, firstSipAnniversaryMonthDay);
    case AchievementFamilyIds.occasionNewYear:
      return (date.month == 12 && date.day == 31) || (date.month == 1 && date.day == 1);
    case AchievementFamilyIds.occasionChristmas:
      return date.month == 12 && date.day >= 24 && date.day <= 26;
    case AchievementFamilyIds.occasionEaster:
      return _withinInclusive(date, goodFriday(date.year), easterMonday(date.year));
    case AchievementFamilyIds.occasionHalloween:
      return date.month == 10 && date.day == 31;
    case AchievementFamilyIds.occasionStPatricksDay:
      return isBeer && date.month == 3 && date.day == 17;
    case AchievementFamilyIds.occasionOktoberfest:
      if (!isBeer) return false;
      final (DateTime, DateTime)? window = oktoberfestWindow(date.year);
      if (window == null) return false;
      return _withinInclusive(date, window.$1, window.$2);
    case AchievementFamilyIds.occasionCarnival:
      return _withinInclusive(date, fatThursday(date.year), mardiGras(date.year));
    default:
      return false;
  }
}

/// The occasion-year dedupe key for an eligible [localDate], matching
/// `spec.md`: "the calendar year of the window's first day (New Year uses
/// the year of Dec 31)".
int occasionYearForDate({required String familyId, required DateTime localDate}) {
  final DateTime date = _dateOnly(localDate);
  if (familyId == AchievementFamilyIds.occasionNewYear && date.month == 1 && date.day == 1) {
    return date.year - 1;
  }
  return date.year;
}

/// The next eligible window `(start, end)` for [familyId] at or after
/// [now]. Returns `null` if the family has no defined future window (e.g.
/// Oktoberfest outside the locked table), or requires unset prerequisite
/// data (birthday/anniversary).
(DateTime start, DateTime end)? nextEligibleWindow({
  required String familyId,
  required DateTime now,
  DateTime? birthdayMonthDay,
  DateTime? firstSipAnniversaryMonthDay,
}) {
  final DateTime today = _dateOnly(now);

  (DateTime, DateTime)? windowForYear(int year) {
    switch (familyId) {
      case AchievementFamilyIds.occasionBirthday:
        if (birthdayMonthDay == null) return null;
        int month = birthdayMonthDay.month;
        int day = birthdayMonthDay.day;
        if (month == 2 && day == 29 && !_isLeapYear(year)) day = 28;
        final DateTime d = DateTime(year, month, day);
        return (d, d);
      case AchievementFamilyIds.occasionFirstSipAnniversary:
        if (firstSipAnniversaryMonthDay == null) return null;
        int month = firstSipAnniversaryMonthDay.month;
        int day = firstSipAnniversaryMonthDay.day;
        if (month == 2 && day == 29 && !_isLeapYear(year)) day = 28;
        final DateTime d = DateTime(year, month, day);
        return (d, d);
      case AchievementFamilyIds.occasionNewYear:
        return (DateTime(year, 12, 31), DateTime(year + 1, 1, 1));
      case AchievementFamilyIds.occasionChristmas:
        return (DateTime(year, 12, 24), DateTime(year, 12, 26));
      case AchievementFamilyIds.occasionEaster:
        return (goodFriday(year), easterMonday(year));
      case AchievementFamilyIds.occasionHalloween:
        final DateTime d = DateTime(year, 10, 31);
        return (d, d);
      case AchievementFamilyIds.occasionStPatricksDay:
        final DateTime d = DateTime(year, 3, 17);
        return (d, d);
      case AchievementFamilyIds.occasionOktoberfest:
        final (DateTime, DateTime)? window = oktoberfestWindow(year);
        return window;
      case AchievementFamilyIds.occasionCarnival:
        return (fatThursday(year), mardiGras(year));
      default:
        return null;
    }
  }

  for (int year = today.year; year <= today.year + 6; year++) {
    final (DateTime, DateTime)? window = windowForYear(year);
    if (window == null) continue;
    if (!today.isAfter(_dateOnly(window.$2))) {
      return window;
    }
  }
  return null;
}
