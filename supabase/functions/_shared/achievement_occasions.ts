// Pure date-window logic for reminder-eligible occasion achievements.
// Ported from lib/src/achievements/occasion_rules.dart and
// lib/src/achievements/catalog.dart -- keep both in sync with
// docs/achievements/spec.md if either changes.

export type LocalDate = { year: number; month: number; day: number };

/** Family IDs for the 9 reminder-eligible occasion badges, in the fixed
 * catalog order used for same-day stagger determinism. */
export const reminderOccasionFamilyIds: readonly string[] = [
  "occasion_birthday",
  "occasion_first_sip_anniversary",
  "occasion_new_year",
  "occasion_christmas",
  "occasion_easter",
  "occasion_halloween",
  "occasion_st_patricks_day",
  "occasion_oktoberfest",
  "occasion_carnival",
];

/** Hardcoded Oktoberfest date ranges, identical to catalog.dart. Only
 * 2026-2030 are locked; years outside this table have no Oktoberfest
 * reminder window. */
const oktoberfestDateRanges: Record<
  number,
  [number, number, number, number]
> = {
  2026: [9, 19, 10, 4],
  2027: [9, 18, 10, 3],
  2028: [9, 16, 10, 3],
  2029: [9, 22, 10, 7],
  2030: [9, 21, 10, 6],
};

function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

function dateOnly(date: LocalDate): LocalDate {
  return { year: date.year, month: date.month, day: date.day };
}

/** Days since the epoch via UTC construction, so local DST never shifts
 * the delta away from exactly 1 -- mirrors streaks.dart's _dayKey. */
function dayKey(date: LocalDate): number {
  return Math.floor(
    Date.UTC(date.year, date.month - 1, date.day) / 86_400_000,
  );
}

function addDays(date: LocalDate, days: number): LocalDate {
  const key = dayKey(date) + days;
  const utcMillis = key * 86_400_000;
  const d = new Date(utcMillis);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
  };
}

function compareDates(a: LocalDate, b: LocalDate): number {
  return dayKey(a) - dayKey(b);
}

function withinInclusive(
  date: LocalDate,
  start: LocalDate,
  end: LocalDate,
): boolean {
  return compareDates(date, start) >= 0 && compareDates(date, end) <= 0;
}

/** Matches `date` against a fixed annual (month, day), applying the locked
 * Feb 29 -> Feb 28 fallback in non-leap years. Used for birthday and
 * first-sip-anniversary matching. */
export function matchesAnnualMonthDay(
  date: LocalDate,
  monthDay: { month: number; day: number },
): boolean {
  let month = monthDay.month;
  let day = monthDay.day;
  if (month === 2 && day === 29 && !isLeapYear(date.year)) {
    day = 28;
  }
  return date.month === month && date.day === day;
}

/** Western (Gregorian) computus: Easter Sunday for `year`. Anonymous
 * Gregorian algorithm, identical to occasion_rules.dart. */
export function easterSunday(year: number): LocalDate {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return { year, month, day };
}

export function goodFriday(year: number): LocalDate {
  return addDays(easterSunday(year), -2);
}

export function easterMonday(year: number): LocalDate {
  return addDays(easterSunday(year), 1);
}

/** Mardi Gras / Shrove Tuesday: 47 days before Easter Sunday. */
export function mardiGras(year: number): LocalDate {
  return addDays(easterSunday(year), -47);
}

/** Fat Thursday / Weiberfastnacht: the Thursday before Mardi Gras. */
export function fatThursday(year: number): LocalDate {
  return addDays(mardiGras(year), -5);
}

export function oktoberfestWindow(
  year: number,
): [LocalDate, LocalDate] | null {
  const range = oktoberfestDateRanges[year];
  if (range == null) return null;
  const [startMonth, startDay, endMonth, endDay] = range;
  return [
    { year, month: startMonth, day: startDay },
    { year, month: endMonth, day: endDay },
  ];
}

export type OccasionMatchInput = {
  familyId: string;
  localDate: LocalDate;
  isBeer: boolean;
  birthdayMonthDay: { month: number; day: number } | null;
  firstSipAnniversaryMonthDay: { month: number; day: number } | null;
};

/** Evaluates whether `localDate` (a device-local calendar date) falls
 * within the reminder-eligible window for `familyId`. Mirrors
 * occasion_rules.dart's `occasionMatches`. */
export function occasionMatches(input: OccasionMatchInput): boolean {
  const date = dateOnly(input.localDate);
  switch (input.familyId) {
    case "occasion_birthday":
      return input.birthdayMonthDay != null &&
        matchesAnnualMonthDay(date, input.birthdayMonthDay);
    case "occasion_first_sip_anniversary":
      return input.firstSipAnniversaryMonthDay != null &&
        matchesAnnualMonthDay(date, input.firstSipAnniversaryMonthDay);
    case "occasion_new_year":
      return (date.month === 12 && date.day === 31) ||
        (date.month === 1 && date.day === 1);
    case "occasion_christmas":
      return date.month === 12 && date.day >= 24 && date.day <= 26;
    case "occasion_easter":
      return withinInclusive(
        date,
        goodFriday(date.year),
        easterMonday(date.year),
      );
    case "occasion_halloween":
      return date.month === 10 && date.day === 31;
    case "occasion_st_patricks_day":
      return input.isBeer && date.month === 3 && date.day === 17;
    case "occasion_oktoberfest": {
      if (!input.isBeer) return false;
      const window = oktoberfestWindow(date.year);
      if (window == null) return false;
      return withinInclusive(date, window[0], window[1]);
    }
    case "occasion_carnival":
      return withinInclusive(
        date,
        fatThursday(date.year),
        mardiGras(date.year),
      );
    default:
      return false;
  }
}

/** The occasion-year dedupe key for an eligible `localDate`, matching
 * spec.md: "the calendar year of the window's first day (New Year uses
 * the year of Dec 31)". */
export function occasionYearForDate(
  familyId: string,
  localDate: LocalDate,
): number {
  const date = dateOnly(localDate);
  if (
    familyId === "occasion_new_year" && date.month === 1 && date.day === 1
  ) {
    return date.year - 1;
  }
  return date.year;
}

/** Converts a UTC instant plus a UTC offset in minutes into the device's
 * local calendar date and local hour-of-day (0-23), matching how the app
 * derives `achievementLocalDate` from `achievementUtcOffsetMinutes`. */
export function localDateAndHour(
  utcNow: Date,
  utcOffsetMinutes: number,
): { date: LocalDate; hour: number } {
  const shifted = new Date(utcNow.getTime() + utcOffsetMinutes * 60_000);
  return {
    date: {
      year: shifted.getUTCFullYear(),
      month: shifted.getUTCMonth() + 1,
      day: shifted.getUTCDate(),
    },
    hour: shifted.getUTCHours(),
  };
}

export function localDateToIso(date: LocalDate): string {
  const y = String(date.year).padStart(4, "0");
  const m = String(date.month).padStart(2, "0");
  const d = String(date.day).padStart(2, "0");
  return `${y}-${m}-${d}`;
}
