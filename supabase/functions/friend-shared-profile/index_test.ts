import {
  buildFriendSharedProfileResponse,
  loadAllDrinkEntries,
} from "./index.ts";

type ProfileRow = {
  id: string;
  display_name: string | null;
  profile_image_path: string | null;
};

type DrinkEntryRow = {
  user_id: string;
  category_slug: string;
  is_alcohol_free: boolean;
  consumed_at: string;
};

type DataSource = Parameters<
  typeof buildFriendSharedProfileResponse
>[0]["dataSource"];

function expectEqual(actual: unknown, expected: unknown, label: string): void {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`${label}: expected ${expectedJson}, got ${actualJson}`);
  }
}

function profileRow(overrides: Partial<ProfileRow> = {}): ProfileRow {
  return {
    id: "0f0f0f0f-1111-4222-8333-444444444444",
    display_name: "Shared Friend",
    profile_image_path:
      "0f0f0f0f-1111-4222-8333-444444444444/profiles/avatar.png",
    ...overrides,
  };
}

function dataSource(overrides: Partial<DataSource> = {}): DataSource {
  return {
    hasAcceptedFriendship: async () => true,
    loadProfile: async () => profileRow(),
    loadShareStatsWithFriends: async () => true,
    loadEntries: async () => [],
    ...overrides,
  };
}

async function responseJson(response: Response): Promise<unknown> {
  return JSON.parse(await response.text());
}

function drinkEntryRow(
  overrides: Partial<DrinkEntryRow> = {},
): DrinkEntryRow {
  return {
    user_id: "22222222-2222-4222-8222-222222222222",
    category_slug: "beer",
    is_alcohol_free: false,
    consumed_at: "2026-05-05T07:00:00Z",
    ...overrides,
  };
}

Deno.test("returns not found when the viewer is not an accepted friend", async () => {
  const response = await buildFriendSharedProfileResponse({
    viewerUserId: "11111111-1111-4111-8111-111111111111",
    friendUserId: "22222222-2222-4222-8222-222222222222",
    utcOffsetMinutes: 0,
    dataSource: dataSource({
      hasAcceptedFriendship: async () => false,
    }),
  });

  expectEqual(response.status, 404, "status");
  expectEqual(
    await responseJson(response),
    { error: "profile_not_found" },
    "body",
  );
});

Deno.test("returns profile data without statistics when sharing is disabled", async () => {
  const response = await buildFriendSharedProfileResponse({
    viewerUserId: "11111111-1111-4111-8111-111111111111",
    friendUserId: "22222222-2222-4222-8222-222222222222",
    utcOffsetMinutes: 0,
    dataSource: dataSource({
      loadShareStatsWithFriends: async () => false,
      loadEntries: async () => {
        throw new Error("entries should not be loaded when sharing is off");
      },
    }),
  });

  expectEqual(response.status, 200, "status");
  expectEqual(await responseJson(response), {
    id: "0f0f0f0f-1111-4222-8333-444444444444",
    displayName: "Shared Friend",
    profileImagePath:
      "0f0f0f0f-1111-4222-8333-444444444444/profiles/avatar.png",
    shareStatsWithFriends: false,
    statistics: null,
  }, "body");
});

Deno.test("loadAllDrinkEntries fetches every page past the default row cap", async () => {
  const requestedRanges: Array<[number, number]> = [];
  const firstPage = Array.from({ length: 1_000 }, (_, index) =>
    drinkEntryRow({
      consumed_at: new Date(Date.UTC(2026, 0, 1, 0, 0, index)).toISOString(),
    }));
  const secondPage = [
    drinkEntryRow({
      category_slug: "wine",
      consumed_at: "2026-01-01T00:16:40.000Z",
    }),
    drinkEntryRow({
      category_slug: "cocktails",
      consumed_at: "2026-01-01T00:16:41.000Z",
    }),
  ];
  let page = 0;

  const entries = await loadAllDrinkEntries(
    async (fromInclusive, toInclusive) => {
      requestedRanges.push([fromInclusive, toInclusive]);

      switch (page++) {
        case 0:
          return firstPage;
        case 1:
          return secondPage;
        default:
          return [];
      }
    },
  );

  expectEqual(requestedRanges, [
    [0, 999],
    [1000, 1999],
  ], "requestedRanges");
  expectEqual(entries.length, 1_002, "entry count");
  expectEqual(entries[0], firstPage[0], "first entry");
  expectEqual(entries[entries.length - 1], secondPage[1], "last entry");
});

Deno.test("returns deterministic statistics json for a fixed set of entries", async () => {
  const entries: DrinkEntryRow[] = [
    drinkEntryRow({
      category_slug: "beer",
      is_alcohol_free: false,
      consumed_at: "2026-05-05T07:00:00Z",
    }),
    drinkEntryRow({
      category_slug: "beer",
      is_alcohol_free: true,
      consumed_at: "2026-05-04T21:30:00Z",
    }),
    drinkEntryRow({
      category_slug: "wine",
      is_alcohol_free: false,
      consumed_at: "2026-05-03T18:00:00Z",
    }),
    drinkEntryRow({
      category_slug: "cocktails",
      is_alcohol_free: false,
      consumed_at: "2026-04-30T22:30:00Z",
    }),
    drinkEntryRow({
      category_slug: "nonAlcoholic",
      is_alcohol_free: false,
      consumed_at: "2025-12-31T23:30:00Z",
    }),
  ];

  const response = await buildFriendSharedProfileResponse({
    viewerUserId: "11111111-1111-4111-8111-111111111111",
    friendUserId: "22222222-2222-4222-8222-222222222222",
    utcOffsetMinutes: 120,
    now: new Date("2026-05-05T10:00:00Z"),
    dataSource: dataSource({
      loadEntries: async () => entries,
    }),
  });

  expectEqual(response.status, 200, "status");
  expectEqual(await responseJson(response), {
    id: "0f0f0f0f-1111-4222-8333-444444444444",
    displayName: "Shared Friend",
    profileImagePath:
      "0f0f0f0f-1111-4222-8333-444444444444/profiles/avatar.png",
    shareStatsWithFriends: true,
    statistics: {
      weeklyTotal: 2,
      monthlyTotal: 4,
      yearlyTotal: 5,
      currentStreak: 3,
      bestStreak: 3,
      bestStreakStart: "2026-05-03",
      bestStreakEnd: "2026-05-05",
      hasEntryToday: true,
      streakThroughYesterday: 2,
      streakMessageState: "continuedToday",
      weekProgress: [
        {
          date: "2026-05-04",
          weekday: 1,
          hasEntry: true,
          isToday: false,
        },
        {
          date: "2026-05-05",
          weekday: 2,
          hasEntry: true,
          isToday: true,
        },
        {
          date: "2026-05-06",
          weekday: 3,
          hasEntry: false,
          isToday: false,
        },
        {
          date: "2026-05-07",
          weekday: 4,
          hasEntry: false,
          isToday: false,
        },
        {
          date: "2026-05-08",
          weekday: 5,
          hasEntry: false,
          isToday: false,
        },
        {
          date: "2026-05-09",
          weekday: 6,
          hasEntry: false,
          isToday: false,
        },
        {
          date: "2026-05-10",
          weekday: 7,
          hasEntry: false,
          isToday: false,
        },
      ],
      categoryCounts: {
        beer: 2,
        wine: 1,
        sparklingWines: 0,
        longdrinks: 0,
        spirits: 0,
        shots: 0,
        cocktails: 1,
        appleWines: 0,
        nonAlcoholic: 1,
      },
      totalEntries: 5,
      beerTotalCount: 2,
      regularBeerCount: 1,
      alcoholFreeBeerCount: 1,
    },
  }, "body");
});

Deno.test("uses timezone rules for historical DST boundaries", async () => {
  const entries: DrinkEntryRow[] = [
    drinkEntryRow({
      category_slug: "beer",
      is_alcohol_free: false,
      consumed_at: "2026-01-15T22:30:00Z",
    }),
    drinkEntryRow({
      category_slug: "wine",
      is_alcohol_free: false,
      consumed_at: "2026-01-16T10:00:00Z",
    }),
  ];

  const response = await buildFriendSharedProfileResponse({
    viewerUserId: "11111111-1111-4111-8111-111111111111",
    friendUserId: "22222222-2222-4222-8222-222222222222",
    timeZone: "Europe/Berlin",
    utcOffsetMinutes: 120,
    now: new Date("2026-07-01T10:00:00Z"),
    dataSource: dataSource({
      loadEntries: async () => entries,
    }),
  });

  const body = await responseJson(response) as {
    statistics: {
      bestStreak: number;
      bestStreakStart: string | null;
      bestStreakEnd: string | null;
    };
  };

  expectEqual(response.status, 200, "status");
  expectEqual(body.statistics.bestStreak, 2, "bestStreak");
  expectEqual(body.statistics.bestStreakStart, "2026-01-15", "bestStreakStart");
  expectEqual(body.statistics.bestStreakEnd, "2026-01-16", "bestStreakEnd");
});
