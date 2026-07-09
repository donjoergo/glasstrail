import {
  type DeviceEligibilityInput,
  eligibleRemindersForDevice,
} from "./index.ts";

function assertEqual(actual: unknown, expected: unknown, label: string) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) {
    throw new Error(`${label}: expected ${e}, got ${a}`);
  }
}

function baseInput(
  overrides: Partial<DeviceEligibilityInput> = {},
): DeviceEligibilityInput {
  return {
    deviceTokenId: "device-1",
    utcOffsetMinutes: 0,
    birthdayMonthDay: null,
    firstSipAnniversaryMonthDay: null,
    firstSipAnniversaryYear: null,
    earnedOneTimeFamilyIds: new Set<string>(),
    sentOccasionYears: new Map<string, Set<number>>(),
    ...overrides,
  };
}

Deno.test("no reminders outside the 09:00-23:00 local window", () => {
  const input = baseInput({ birthdayMonthDay: { month: 10, day: 31 } });
  // Halloween at 08:00 UTC (before the 09:00 first-attempt hour).
  const tooEarly = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 9, 31, 8, 0)),
  );
  assertEqual(tooEarly, [], "too early");
});

Deno.test("sends a Halloween reminder within the retry window", () => {
  const input = baseInput({});
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 9, 31, 12, 0)),
  );
  assertEqual(result.length, 1, "one candidate");
  assertEqual(result[0].familyId, "occasion_halloween", "family");
});

Deno.test("skips a family already earned (one-time badge)", () => {
  const input = baseInput({
    earnedOneTimeFamilyIds: new Set(["occasion_halloween"]),
  });
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 9, 31, 12, 0)),
  );
  assertEqual(result, [], "already earned, no reminder");
});

Deno.test("skips a family already sent this occasion year", () => {
  const sentOccasionYears = new Map<string, Set<number>>();
  sentOccasionYears.set("occasion_halloween", new Set([2026]));
  const input = baseInput({ sentOccasionYears });
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 9, 31, 12, 0)),
  );
  assertEqual(result, [], "already sent this year");
});

Deno.test("sends again the following year after a previous send", () => {
  const sentOccasionYears = new Map<string, Set<number>>();
  sentOccasionYears.set("occasion_halloween", new Set([2025]));
  const input = baseInput({ sentOccasionYears });
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 9, 31, 12, 0)),
  );
  assertEqual(result.length, 1, "eligible again in 2026");
});

Deno.test("multiple eligible families on the same day are all returned in catalog order", () => {
  // Dec 31 is both New Year's Eve and (for a matching birthday) a
  // birthday reminder day.
  const input = baseInput({ birthdayMonthDay: { month: 12, day: 31 } });
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 11, 31, 12, 0)),
  );
  assertEqual(
    result.map((r) => r.familyId),
    ["occasion_birthday", "occasion_new_year"],
    "catalog order",
  );
});

Deno.test("computes {years} for the first-sip-anniversary reminder", () => {
  const input = baseInput({
    firstSipAnniversaryMonthDay: { month: 6, day: 15 },
    firstSipAnniversaryYear: 2020,
  });
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 5, 15, 12, 0)),
  );
  assertEqual(result.length, 1, "one candidate");
  assertEqual(result[0].years, 6, "years since first sip");
});

Deno.test("missing utc offset falls back to UTC", () => {
  const input = baseInput({
    utcOffsetMinutes: null,
  });
  const result = eligibleRemindersForDevice(
    input,
    new Date(Date.UTC(2026, 9, 31, 12, 0)),
  );
  assertEqual(result.length, 1, "still eligible");
  assertEqual(result[0].timeZoneUsed, "UTC", "falls back to UTC label");
});
