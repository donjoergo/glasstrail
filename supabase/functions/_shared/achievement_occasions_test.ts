import {
  easterSunday,
  fatThursday,
  goodFriday,
  localDateAndHour,
  mardiGras,
  occasionMatches,
  occasionYearForDate,
  oktoberfestWindow,
} from "./achievement_occasions.ts";

function assertEqual(actual: unknown, expected: unknown, label: string) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) {
    throw new Error(`${label}: expected ${e}, got ${a}`);
  }
}

Deno.test("easterSunday matches the locked 2026/2027 dates", () => {
  assertEqual(easterSunday(2026), { year: 2026, month: 4, day: 5 }, "2026");
  assertEqual(easterSunday(2027), { year: 2027, month: 3, day: 28 }, "2027");
});

Deno.test("goodFriday/easterMonday bracket Easter Sunday", () => {
  assertEqual(goodFriday(2026), { year: 2026, month: 4, day: 3 }, "goodFriday");
});

Deno.test("carnival runs from Fat Thursday through Mardi Gras", () => {
  assertEqual(mardiGras(2026), { year: 2026, month: 2, day: 17 }, "mardiGras");
  assertEqual(
    fatThursday(2026),
    { year: 2026, month: 2, day: 12 },
    "fatThursday",
  );

  const inWindow = occasionMatches({
    familyId: "occasion_carnival",
    localDate: { year: 2026, month: 2, day: 12 },
    isBeer: false,
    birthdayMonthDay: null,
    firstSipAnniversaryMonthDay: null,
  });
  const outOfWindow = occasionMatches({
    familyId: "occasion_carnival",
    localDate: { year: 2026, month: 2, day: 18 },
    isBeer: false,
    birthdayMonthDay: null,
    firstSipAnniversaryMonthDay: null,
  });
  assertEqual(inWindow, true, "in window");
  assertEqual(outOfWindow, false, "out of window");
});

Deno.test("oktoberfest uses the hardcoded 2026-2030 table and requires beer", () => {
  assertEqual(oktoberfestWindow(2031), null, "2031 undefined");
  const matchesWithBeer = occasionMatches({
    familyId: "occasion_oktoberfest",
    localDate: { year: 2026, month: 9, day: 19 },
    isBeer: true,
    birthdayMonthDay: null,
    firstSipAnniversaryMonthDay: null,
  });
  const matchesWithoutBeer = occasionMatches({
    familyId: "occasion_oktoberfest",
    localDate: { year: 2026, month: 9, day: 19 },
    isBeer: false,
    birthdayMonthDay: null,
    firstSipAnniversaryMonthDay: null,
  });
  assertEqual(matchesWithBeer, true, "with beer");
  assertEqual(matchesWithoutBeer, false, "without beer");
});

Deno.test("Feb 29 birthday falls back to Feb 28 in non-leap years", () => {
  const matches2027 = occasionMatches({
    familyId: "occasion_birthday",
    localDate: { year: 2027, month: 2, day: 28 },
    isBeer: false,
    birthdayMonthDay: { month: 2, day: 29 },
    firstSipAnniversaryMonthDay: null,
  });
  const matches2028 = occasionMatches({
    familyId: "occasion_birthday",
    localDate: { year: 2028, month: 2, day: 29 },
    isBeer: false,
    birthdayMonthDay: { month: 2, day: 29 },
    firstSipAnniversaryMonthDay: null,
  });
  assertEqual(matches2027, true, "2027 (non-leap)");
  assertEqual(matches2028, true, "2028 (leap)");
});

Deno.test("New Year occasion year dedupes on the Dec 31 year", () => {
  assertEqual(
    occasionYearForDate("occasion_new_year", {
      year: 2026,
      month: 12,
      day: 31,
    }),
    2026,
    "dec 31",
  );
  assertEqual(
    occasionYearForDate("occasion_new_year", { year: 2027, month: 1, day: 1 }),
    2026,
    "jan 1",
  );
});

Deno.test("localDateAndHour applies the UTC offset", () => {
  const utcNow = new Date(Date.UTC(2026, 0, 1, 23, 30));
  const result = localDateAndHour(utcNow, 120); // UTC+2
  assertEqual(result.date, { year: 2026, month: 1, day: 2 }, "date");
  assertEqual(result.hour, 1, "hour");
});
