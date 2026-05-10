import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

type FriendRelationshipRow = {
  requester_id: string;
  addressee_id: string;
  status: string;
};

type ProfileRow = {
  id: string;
  display_name: string | null;
  profile_image_path: string | null;
};

type UserSettingsRow = {
  user_id: string;
  share_stats_with_friends: boolean;
};

type DrinkEntryRow = {
  user_id: string;
  category_slug: string;
  is_alcohol_free: boolean;
  consumed_at: string;
};

type FunctionDatabase = {
  public: {
    Tables: {
      drink_entries: {
        Row: DrinkEntryRow;
        Insert: never;
        Update: never;
        Relationships: [];
      };
      friend_relationships: {
        Row: FriendRelationshipRow;
        Insert: never;
        Update: never;
        Relationships: [];
      };
      profiles: {
        Row: ProfileRow;
        Insert: never;
        Update: never;
        Relationships: [];
      };
      user_settings: {
        Row: UserSettingsRow;
        Insert: never;
        Update: never;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
  };
};

type AppSupabaseClient = SupabaseClient<FunctionDatabase>;

type FriendSharedProfileDataSource = {
  hasAcceptedFriendship: (
    viewerUserId: string,
    friendUserId: string,
  ) => Promise<boolean>;
  loadProfile: (friendUserId: string) => Promise<ProfileRow | null>;
  loadShareStatsWithFriends: (friendUserId: string) => Promise<boolean>;
  loadEntries: (friendUserId: string) => Promise<DrinkEntryRow[]>;
};

type CalendarDay = {
  year: number;
  month: number;
  day: number;
};

type CalendarDayContext =
  | {
    timeZoneFormatter: Intl.DateTimeFormat;
  }
  | {
    utcOffsetMinutes: number;
  };

const drinkCategories = [
  "beer",
  "wine",
  "sparklingWines",
  "longdrinks",
  "spirits",
  "shots",
  "cocktails",
  "appleWines",
  "nonAlcoholic",
] as const;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const drinkEntriesPageSize = 1_000;

if (import.meta.main) {
  Deno.serve(async (request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "method_not_allowed" }, 405);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ??
      "";
    if (supabaseUrl.length === 0 || serviceRoleKey.length === 0) {
      return serverErrorResponse();
    }

    const accessToken = bearerToken(request);
    if (accessToken == null) {
      return unauthorizedResponse();
    }

    const body = await requestBody(request);
    const friendUserId = stringValue(body?.friendUserId);
    const utcOffsetMinutes = integerValue(body?.utcOffsetMinutes);
    const timeZone = stringValue(body?.timeZone) || null;
    if (
      !isUuid(friendUserId) ||
      (timeZone == null && utcOffsetMinutes == null)
    ) {
      return jsonResponse({ error: "invalid_request" }, 400);
    }

    try {
      const client = createClient<FunctionDatabase>(
        supabaseUrl,
        serviceRoleKey,
      );
      const {
        data: { user },
        error: authError,
      } = await client.auth.getUser(accessToken);
      if (authError != null || user == null) {
        return unauthorizedResponse();
      }

      return await buildFriendSharedProfileResponse({
        viewerUserId: user.id,
        friendUserId,
        timeZone,
        utcOffsetMinutes,
        dataSource: dataSourceForClient(client),
      });
    } catch (error) {
      console.error(error);
      return serverErrorResponse();
    }
  });
}

export async function buildFriendSharedProfileResponse(input: {
  viewerUserId: string;
  friendUserId: string;
  timeZone?: string | null;
  utcOffsetMinutes?: number | null;
  dataSource: FriendSharedProfileDataSource;
  now?: Date;
}): Promise<Response> {
  const {
    viewerUserId,
    friendUserId,
    timeZone,
    utcOffsetMinutes,
    dataSource,
    now = new Date(),
  } = input;

  const isFriend = await dataSource.hasAcceptedFriendship(
    viewerUserId,
    friendUserId,
  );
  if (!isFriend) {
    return notFoundResponse();
  }

  const profile = await dataSource.loadProfile(friendUserId);
  if (profile == null) {
    return notFoundResponse();
  }

  const shareStatsWithFriends = await dataSource.loadShareStatsWithFriends(
    friendUserId,
  );
  if (!shareStatsWithFriends) {
    return jsonResponse(
      friendSharedProfileJson({
        profile,
        shareStatsWithFriends,
        statistics: null,
      }),
      200,
    );
  }

  const entries = await dataSource.loadEntries(friendUserId);
  return jsonResponse(
    friendSharedProfileJson({
      profile,
      shareStatsWithFriends,
      statistics: computeSharedStatistics(entries, {
        now,
        timeZone,
        utcOffsetMinutes,
      }),
    }),
    200,
  );
}

export async function loadAllDrinkEntries(
  loadPage: (
    fromInclusive: number,
    toInclusive: number,
  ) => Promise<DrinkEntryRow[]>,
): Promise<DrinkEntryRow[]> {
  const entries: DrinkEntryRow[] = [];
  let fromInclusive = 0;

  while (true) {
    const toInclusive = fromInclusive + drinkEntriesPageSize - 1;
    const page = await loadPage(fromInclusive, toInclusive);
    entries.push(...page);

    if (page.length < drinkEntriesPageSize) {
      return entries;
    }

    fromInclusive += drinkEntriesPageSize;
  }
}

function dataSourceForClient(
  client: AppSupabaseClient,
): FriendSharedProfileDataSource {
  return {
    async hasAcceptedFriendship(viewerUserId, friendUserId) {
      const { data, error } = await client
        .from("friend_relationships")
        .select("requester_id, addressee_id, status")
        .eq("status", "accepted")
        .or(
          `and(requester_id.eq.${viewerUserId},addressee_id.eq.${friendUserId}),and(requester_id.eq.${friendUserId},addressee_id.eq.${viewerUserId})`,
        )
        .limit(1);

      if (error != null) {
        throw error;
      }
      return (data ?? []).length > 0;
    },

    async loadProfile(friendUserId) {
      const { data, error } = await client
        .from("profiles")
        .select("id, display_name, profile_image_path")
        .eq("id", friendUserId)
        .maybeSingle();

      if (error != null) {
        throw error;
      }
      return data as ProfileRow | null;
    },

    async loadShareStatsWithFriends(friendUserId) {
      const { data, error } = await client
        .from("user_settings")
        .select("user_id, share_stats_with_friends")
        .eq("user_id", friendUserId)
        .maybeSingle();

      if (error != null) {
        throw error;
      }
      return data?.share_stats_with_friends ?? true;
    },

    async loadEntries(friendUserId) {
      return await loadAllDrinkEntries(async (fromInclusive, toInclusive) => {
        const { data, error } = await client
          .from("drink_entries")
          .select("category_slug, is_alcohol_free, consumed_at")
          .eq("user_id", friendUserId)
          .order("consumed_at", { ascending: false })
          .order("id", { ascending: false })
          .range(fromInclusive, toInclusive);

        if (error != null) {
          throw error;
        }
        return (data ?? []) as DrinkEntryRow[];
      });
    },
  };
}

function friendSharedProfileJson(input: {
  profile: ProfileRow;
  shareStatsWithFriends: boolean;
  statistics: Record<string, unknown> | null;
}): Record<string, unknown> {
  return {
    id: input.profile.id,
    displayName: displayName(input.profile),
    profileImagePath: input.profile.profile_image_path?.trim() || null,
    shareStatsWithFriends: input.shareStatsWithFriends,
    statistics: input.statistics,
  };
}

export function computeSharedStatistics(
  entries: DrinkEntryRow[],
  input: {
    now: Date;
    timeZone?: string | null;
    utcOffsetMinutes?: number | null;
  },
): Record<string, unknown> {
  const dayContext = calendarDayContextFor(input);
  const today = calendarDayFor(input.now, dayContext);
  const todayKey = dayKey(today);
  const weekStartKey = subtractDays(todayKey, weekdayForDayKey(todayKey) - 1);

  const categoryCounts = Object.fromEntries(
    drinkCategories.map((category) => [category, 0]),
  ) as Record<(typeof drinkCategories)[number], number>;

  let weeklyTotal = 0;
  let monthlyTotal = 0;
  let yearlyTotal = 0;
  let beerTotalCount = 0;
  let alcoholFreeBeerCount = 0;

  const uniqueDayKeys = new Set<string>();

  for (const entry of entries) {
    const entryDate = new Date(entry.consumed_at);
    const entryDay = calendarDayFor(entryDate, dayContext);
    const entryDayKey = dayKey(entryDay);
    uniqueDayKeys.add(entryDayKey);

    const category = normalizeCategory(entry.category_slug);
    categoryCounts[category]++;

    if (category === "beer") {
      beerTotalCount++;
      if (entry.is_alcohol_free) {
        alcoholFreeBeerCount++;
      }
    }

    if (entryDayKey >= weekStartKey) {
      weeklyTotal++;
    }
    if (entryDay.year === today.year && entryDay.month === today.month) {
      monthlyTotal++;
    }
    if (entryDay.year === today.year) {
      yearlyTotal++;
    }
  }

  const sortedDayKeys = Array.from(uniqueDayKeys).sort();
  let bestStreak = 0;
  let bestStreakStart: string | null = null;
  let bestStreakEnd: string | null = null;
  let rolling = 0;
  let previousKey: string | null = null;
  let rollingStart: string | null = null;

  for (const day of sortedDayKeys) {
    if (previousKey == null || differenceInDays(day, previousKey) > 1) {
      rolling = 1;
      rollingStart = day;
    } else if (differenceInDays(day, previousKey) === 1) {
      rolling++;
    }
    previousKey = day;
    if (rolling > bestStreak || (rolling === bestStreak && rolling > 0)) {
      bestStreak = rolling;
      bestStreakStart = rollingStart;
      bestStreakEnd = day;
    }
  }

  const hasEntryToday = uniqueDayKeys.has(todayKey);
  const currentStreak = countStreakFrom(uniqueDayKeys, todayKey);
  const yesterdayKey = subtractDays(todayKey, 1);
  const streakThroughYesterday = countStreakFrom(uniqueDayKeys, yesterdayKey);
  const streakMessageState = currentStreak === 0
    ? streakThroughYesterday > 0 ? "keepAlive" : "start"
    : currentStreak === 1
    ? "startedToday"
    : "continuedToday";

  return {
    weeklyTotal,
    monthlyTotal,
    yearlyTotal,
    currentStreak,
    bestStreak,
    bestStreakStart,
    bestStreakEnd,
    hasEntryToday,
    streakThroughYesterday,
    streakMessageState,
    weekProgress: Array.from({ length: 7 }, (_, index) => {
      const dateKey = addDays(weekStartKey, index);
      return {
        date: dateKey,
        weekday: weekdayForDayKey(dateKey),
        hasEntry: uniqueDayKeys.has(dateKey),
        isToday: dateKey === todayKey,
      };
    }),
    categoryCounts,
    totalEntries: entries.length,
    beerTotalCount,
    regularBeerCount: beerTotalCount - alcoholFreeBeerCount,
    alcoholFreeBeerCount,
  };
}

async function requestBody(
  request: Request,
): Promise<Record<string, unknown> | null> {
  try {
    const body = await request.json();
    return body == null || typeof body !== "object"
      ? null
      : (body as Record<string, unknown>);
  } catch (_) {
    return null;
  }
}

function bearerToken(request: Request): string | null {
  const authorization = request.headers.get("authorization")?.trim() ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return null;
  }
  const token = authorization.slice("Bearer ".length).trim();
  return token.length === 0 ? null : token;
}

function displayName(profile: ProfileRow): string {
  const value = profile.display_name?.trim() ?? "";
  return value.length === 0 ? "Glass Trail User" : value;
}

function normalizeCategory(value: string): (typeof drinkCategories)[number] {
  return drinkCategories.includes(value as (typeof drinkCategories)[number])
    ? (value as (typeof drinkCategories)[number])
    : "nonAlcoholic";
}

const calendarDayFormatters = new Map<string, Intl.DateTimeFormat>();

function calendarDayContextFor(input: {
  timeZone?: string | null;
  utcOffsetMinutes?: number | null;
}): CalendarDayContext {
  const formatter = formatterForTimeZone(input.timeZone ?? null);
  if (formatter != null) {
    return { timeZoneFormatter: formatter };
  }
  if (input.utcOffsetMinutes == null) {
    throw new Error("Missing calendar day context.");
  }
  return { utcOffsetMinutes: input.utcOffsetMinutes };
}

function formatterForTimeZone(
  timeZone: string | null,
): Intl.DateTimeFormat | null {
  if (timeZone == null) {
    return null;
  }
  const normalized = timeZone.trim();
  if (normalized.length === 0) {
    return null;
  }
  const cached = calendarDayFormatters.get(normalized);
  if (cached != null) {
    return cached;
  }
  try {
    const formatter = new Intl.DateTimeFormat("en-CA", {
      timeZone: normalized,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    calendarDayFormatters.set(normalized, formatter);
    return formatter;
  } catch (_) {
    return null;
  }
}

function calendarDayFromParts(parts: Intl.DateTimeFormatPart[]): CalendarDay {
  const year = Number(parts.find((part) => part.type === "year")?.value);
  const month = Number(parts.find((part) => part.type === "month")?.value);
  const day = Number(parts.find((part) => part.type === "day")?.value);
  if (
    !Number.isInteger(year) ||
    !Number.isInteger(month) ||
    !Number.isInteger(day)
  ) {
    throw new Error("Unable to derive calendar day.");
  }
  return { year, month, day };
}

function calendarDayFor(date: Date, context: CalendarDayContext): CalendarDay {
  if ("timeZoneFormatter" in context) {
    return calendarDayFromParts(context.timeZoneFormatter.formatToParts(date));
  }
  const { utcOffsetMinutes } = context;
  const shifted = new Date(date.getTime() + utcOffsetMinutes * 60 * 1000);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
  };
}

function dayKey(day: CalendarDay): string {
  return `${day.year.toString().padStart(4, "0")}-${
    day.month
      .toString()
      .padStart(2, "0")
  }-${day.day.toString().padStart(2, "0")}`;
}

function dayFromKey(value: string): CalendarDay {
  const [year, month, day] = value.split("-").map((part) => Number(part));
  return { year, month, day };
}

function dateFromDayKey(value: string): Date {
  const day = dayFromKey(value);
  return new Date(Date.UTC(day.year, day.month - 1, day.day));
}

function weekdayForDayKey(value: string): number {
  const weekday = dateFromDayKey(value).getUTCDay();
  return weekday === 0 ? 7 : weekday;
}

function addDays(value: string, days: number): string {
  const date = dateFromDayKey(value);
  date.setUTCDate(date.getUTCDate() + days);
  return dayKey({
    year: date.getUTCFullYear(),
    month: date.getUTCMonth() + 1,
    day: date.getUTCDate(),
  });
}

function subtractDays(value: string, days: number): string {
  return addDays(value, -days);
}

function differenceInDays(left: string, right: string): number {
  const difference = dateFromDayKey(left).getTime() -
    dateFromDayKey(right).getTime();
  return Math.round(difference / (24 * 60 * 60 * 1000));
}

function countStreakFrom(dayKeys: Set<string>, startKey: string): number {
  let streak = 0;
  let cursor = startKey;
  while (dayKeys.has(cursor)) {
    streak++;
    cursor = subtractDays(cursor, 1);
  }
  return streak;
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function integerValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }
  if (typeof value === "string" && /^-?\d+$/.test(value.trim())) {
    return Number(value);
  }
  return null;
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function unauthorizedResponse(): Response {
  return jsonResponse({ error: "unauthorized" }, 401);
}

function notFoundResponse(): Response {
  return jsonResponse({ error: "profile_not_found" }, 404);
}

function serverErrorResponse(): Response {
  return jsonResponse({ error: "profile_unavailable" }, 500);
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json; charset=utf-8",
      "cache-control": status === 200 ? "private, max-age=60" : "no-store",
    },
  });
}
