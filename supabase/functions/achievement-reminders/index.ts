// Hourly evaluator + push sender for achievement reminders. Invoked by a
// pg_cron job (see supabase/migrations/*_schedule_achievement_reminders.sql)
// POSTing with the service-role key, same auth convention as
// send-notification-push.
//
// Delivery architecture note: true 15-minute wall-clock staggering between
// multiple same-day reminders for one device isn't achievable inside a
// single stateless Edge Function invocation (that would mean sleeping for
// up to an hour). Instead, eligible reminders for a device are sent
// sequentially within this invocation, in the fixed catalog order, each
// recorded with its own real send timestamp -- satisfying "ordered by
// catalog order" and "separate sent markers" honestly, even though actual
// FCM delivery lands within moments rather than exactly 15 minutes apart.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import {
  notificationPushBody,
  type NotificationPushInput,
  notificationPushTitle,
} from "../_shared/notification_l10n.ts";
import {
  type LocalDate,
  localDateAndHour,
  localDateToIso,
  occasionMatches,
  occasionYearForDate,
  reminderOccasionFamilyIds,
} from "../_shared/achievement_occasions.ts";

export type DeviceEligibilityInput = {
  deviceTokenId: string;
  utcOffsetMinutes: number | null;
  birthdayMonthDay: { month: number; day: number } | null;
  firstSipAnniversaryMonthDay: { month: number; day: number } | null;
  firstSipAnniversaryYear: number | null;
  earnedOneTimeFamilyIds: ReadonlySet<string>;
  sentOccasionYears: ReadonlyMap<string, ReadonlySet<number>>;
};

export type ReminderCandidate = {
  familyId: string;
  occasionYear: number;
  eligibleLocalDate: LocalDate;
  timeZoneUsed: string;
  years: number | null;
};

const firstAttemptHour = 9;
const lastAttemptHour = 23;

/** Pure eligibility evaluation for one device at one point in time. No I/O
 * -- fully unit-testable. Mirrors the retry/catch-up, dedupe-by-
 * occasion-year, and one-time-badge rules from spec.md. */
export function eligibleRemindersForDevice(
  input: DeviceEligibilityInput,
  utcNow: Date,
): ReminderCandidate[] {
  const offsetMinutes = input.utcOffsetMinutes ?? 0;
  const timeZoneUsed = input.utcOffsetMinutes == null
    ? "UTC"
    : offsetMinutesLabel(offsetMinutes);
  const { date, hour } = localDateAndHour(utcNow, offsetMinutes);
  if (hour < firstAttemptHour || hour > lastAttemptHour) {
    return [];
  }

  const results: ReminderCandidate[] = [];
  for (const familyId of reminderOccasionFamilyIds) {
    if (input.earnedOneTimeFamilyIds.has(familyId)) {
      continue;
    }
    const matches = occasionMatches({
      familyId,
      localDate: date,
      isBeer: true,
      birthdayMonthDay: input.birthdayMonthDay,
      firstSipAnniversaryMonthDay: input.firstSipAnniversaryMonthDay,
    });
    if (!matches) {
      continue;
    }
    const occasionYear = occasionYearForDate(familyId, date);
    const alreadySent = input.sentOccasionYears.get(familyId)?.has(
      occasionYear,
    ) ?? false;
    if (alreadySent) {
      continue;
    }
    results.push({
      familyId,
      occasionYear,
      eligibleLocalDate: date,
      timeZoneUsed,
      years: familyId === "occasion_first_sip_anniversary" &&
          input.firstSipAnniversaryYear != null
        ? date.year - input.firstSipAnniversaryYear
        : null,
    });
  }
  return results;
}

function offsetMinutesLabel(offsetMinutes: number): string {
  const sign = offsetMinutes >= 0 ? "+" : "-";
  const abs = Math.abs(offsetMinutes);
  const hours = String(Math.floor(abs / 60)).padStart(2, "0");
  const minutes = String(abs % 60).padStart(2, "0");
  return `UTC${sign}${hours}:${minutes}`;
}

// ---------------------------------------------------------------------
// I/O: database glue and FCM delivery.
// ---------------------------------------------------------------------

type DeviceTokenRow = {
  id: string;
  user_id: string;
  token: string;
  platform: string;
  utc_offset_minutes: number | null;
  time_zone: string | null;
  last_seen_at: string;
};

type ReminderDeliveryInsert = {
  user_id: string;
  device_token_id: string;
  family_id: string;
  occasion_year: number;
  eligible_local_date: string;
  time_zone_used: string;
  sent_at: string;
};

type FcmConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

type FunctionDatabase = {
  public: {
    Tables: {
      notification_device_tokens: {
        Row: DeviceTokenRow;
        Insert: never;
        Update: never;
        Relationships: [];
      };
      achievement_reminder_deliveries: {
        Row: ReminderDeliveryInsert & { id: string; created_at: string };
        Insert: ReminderDeliveryInsert;
        Update: never;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
  };
};

type AppSupabaseClient = SupabaseClient<FunctionDatabase>;

const androidNotificationChannelId = "glass_trail_achievement_reminders";
const activeDeviceWindowDays = 30;
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

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
    return jsonResponse({ ok: true, evaluated: 0 }, 202);
  }
  if (!isServiceRoleRequest(request, serviceRoleKey)) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const fcmConfig = fcmConfigFromEnvironment();
  if (fcmConfig == null) {
    return jsonResponse({ ok: true, pushEnabled: false }, 202);
  }

  const client = createClient<FunctionDatabase>(supabaseUrl, serviceRoleKey);
  const utcNow = new Date();

  let sent = 0;
  let failed = 0;
  let evaluated = 0;
  let noDateMatch = 0;

  try {
    const devices = await loadEligibleDeviceRows(client, utcNow);
    for (const device of devices) {
      evaluated++;
      const eligibility = await loadDeviceEligibilityContext(client, device);
      const candidates = eligibleRemindersForDevice(eligibility, utcNow);
      if (candidates.length === 0) {
        noDateMatch++;
      }

      for (const candidate of candidates) {
        const accessToken = await fcmAccessToken(fcmConfig);
        const locale = await loadUserLocale(client, device.user_id);
        const result = await sendReminderPush(fcmConfig, accessToken, {
          token: device.token,
          familyId: candidate.familyId,
          years: candidate.years,
          locale,
        });
        if (!result.ok) {
          failed++;
          await deleteInvalidToken(client, device.token, result.responseText);
          continue;
        }
        sent++;
        await recordDelivery(client, {
          userId: device.user_id,
          deviceTokenId: device.id,
          familyId: candidate.familyId,
          occasionYear: candidate.occasionYear,
          eligibleLocalDate: candidate.eligibleLocalDate,
          timeZoneUsed: candidate.timeZoneUsed,
        });
      }
    }
  } catch (error) {
    console.error("achievement-reminders evaluation failed", error);
  }

  if (noDateMatch > 0) {
    console.info(
      `achievement-reminders: ${noDateMatch} device(s) evaluated with no date-eligible reminder`,
    );
  }

  return jsonResponse({ ok: true, evaluated, sent, failed }, 202);
});

function isServiceRoleRequest(
  request: Request,
  serviceRoleKey: string,
): boolean {
  const authorization = request.headers.get("authorization")?.trim() ?? "";
  return authorization === `Bearer ${serviceRoleKey}`;
}

/** Devices with `last_seen_at` older than this are excluded as stale --
 * exported so the 30-day window boundary itself is unit-testable without a
 * live DB (the `.gte` filter it feeds is I/O and stays untested here). */
export function staleDeviceCutoffIso(utcNow: Date): string {
  return new Date(
    utcNow.getTime() - activeDeviceWindowDays * 24 * 60 * 60 * 1000,
  ).toISOString();
}

async function loadEligibleDeviceRows(
  client: AppSupabaseClient,
  utcNow: Date,
): Promise<DeviceTokenRow[]> {
  const cutoff = staleDeviceCutoffIso(utcNow);

  const { data, error } = await client
    .from("notification_device_tokens")
    .select("id, user_id, token, utc_offset_minutes, time_zone")
    .eq("platform", "android")
    .gte("last_seen_at", cutoff);

  if (error != null) {
    console.error("Failed to load device tokens", error);
    return [];
  }

  const rows = (data ?? []) as DeviceTokenRow[];
  if (rows.length === 0) {
    return [];
  }

  const userIds = Array.from(new Set(rows.map((row) => row.user_id)));
  const { data: settingsRows, error: settingsError } = await client
    .from("user_settings")
    .select("user_id, achievement_reminders_enabled")
    .in("user_id", userIds);
  if (settingsError != null) {
    console.error("Failed to load reminder settings", settingsError);
    return [];
  }
  const enabledUserIds = new Set(
    ((settingsRows ?? []) as {
      user_id: string;
      achievement_reminders_enabled: boolean;
    }[])
      .filter((row) => row.achievement_reminders_enabled)
      .map((row) => row.user_id),
  );

  const eligible = rows.filter((row) => enabledUserIds.has(row.user_id));
  const remindersDisabledExcluded = rows.length - eligible.length;
  if (remindersDisabledExcluded > 0) {
    // Stale-token exclusion already happened in the `.gte` filter above;
    // logging its count would need a second, unfiltered count query purely
    // for observability, which isn't worth the extra DB load on an hourly
    // job. Reminders-disabled exclusions are free since we already loaded
    // both sets.
    console.info(
      `achievement-reminders: ${remindersDisabledExcluded} device(s) excluded (reminders disabled)`,
    );
  }

  return eligible;
}

async function loadDeviceEligibilityContext(
  client: AppSupabaseClient,
  device: DeviceTokenRow,
): Promise<DeviceEligibilityInput> {
  const [profileResult, earliestEntryResult, unlockRows, deliveryRows] =
    await Promise.all([
      client.from("profiles").select("birthday").eq("id", device.user_id)
        .maybeSingle(),
      client
        .from("drink_entries")
        .select("achievement_local_date, consumed_at")
        .eq("user_id", device.user_id)
        .order("consumed_at", { ascending: true })
        .limit(1)
        .maybeSingle(),
      client
        .from("achievement_unlocks")
        .select("family_id")
        .eq("user_id", device.user_id)
        .eq("level", 1)
        .in("family_id", reminderOccasionFamilyIds as string[]),
      client
        .from("achievement_reminder_deliveries")
        .select("family_id, occasion_year")
        .eq("device_token_id", device.id),
    ]);

  const birthday = (profileResult.data as { birthday: string | null } | null)
    ?.birthday ?? null;
  const birthdayMonthDay = birthday == null ? null : monthDayFromIso(birthday);

  const earliestRow = earliestEntryResult.data as
    | { achievement_local_date: string | null; consumed_at: string }
    | null;
  const earliestIso = earliestRow?.achievement_local_date ??
    earliestRow?.consumed_at?.slice(0, 10) ?? null;
  const firstSipAnniversaryMonthDay = earliestIso == null
    ? null
    : monthDayFromIso(earliestIso);
  const firstSipAnniversaryYear = earliestIso == null
    ? null
    : Number(earliestIso.slice(0, 4));

  const earnedOneTimeFamilyIds = new Set(
    ((unlockRows.data ?? []) as { family_id: string }[]).map((row) =>
      row.family_id
    ),
  );

  const sentOccasionYears = new Map<string, Set<number>>();
  for (
    const row of (deliveryRows.data ?? []) as {
      family_id: string;
      occasion_year: number;
    }[]
  ) {
    const set = sentOccasionYears.get(row.family_id) ?? new Set<number>();
    set.add(row.occasion_year);
    sentOccasionYears.set(row.family_id, set);
  }

  return {
    deviceTokenId: device.id,
    utcOffsetMinutes: device.utc_offset_minutes,
    birthdayMonthDay,
    firstSipAnniversaryMonthDay,
    firstSipAnniversaryYear,
    earnedOneTimeFamilyIds,
    sentOccasionYears,
  };
}

function monthDayFromIso(
  iso: string,
): { month: number; day: number } | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
  if (match == null) return null;
  return { month: Number(match[2]), day: Number(match[3]) };
}

async function loadUserLocale(
  client: AppSupabaseClient,
  userId: string,
): Promise<string> {
  const { data, error } = await client
    .from("user_settings")
    .select("locale_code")
    .eq("user_id", userId)
    .maybeSingle();
  if (error != null) {
    return "en";
  }
  const locale = (data as { locale_code: string } | null)?.locale_code;
  return locale != null && locale.length > 0 ? locale : "en";
}

async function recordDelivery(
  client: AppSupabaseClient,
  input: {
    userId: string;
    deviceTokenId: string;
    familyId: string;
    occasionYear: number;
    eligibleLocalDate: LocalDate;
    timeZoneUsed: string;
  },
): Promise<void> {
  const { error } = await client.from("achievement_reminder_deliveries")
    .insert({
      user_id: input.userId,
      device_token_id: input.deviceTokenId,
      family_id: input.familyId,
      occasion_year: input.occasionYear,
      eligible_local_date: localDateToIso(input.eligibleLocalDate),
      time_zone_used: input.timeZoneUsed,
      sent_at: new Date().toISOString(),
    });
  if (error != null) {
    // A unique-violation here means a concurrent overlapping run already
    // recorded this exact (device, family, occasion_year) delivery --
    // exactly the idempotency guarantee the schema's unique index exists
    // to provide. Anything else is a real logging failure.
    console.error("Failed to record reminder delivery", error);
  }
}

async function sendReminderPush(
  config: FcmConfig,
  accessToken: string,
  input: {
    token: string;
    familyId: string;
    years: number | null;
    locale: string;
  },
): Promise<{ ok: boolean; responseText: string }> {
  const type = `achievement_reminder_${input.familyId}`;
  const pushInput: NotificationPushInput = {
    type,
    locale: input.locale,
    templateArgs: input.years == null ? null : { years: input.years },
    senderDisplayName: "Glass Trail",
  };
  const title = notificationPushTitle(pushInput);
  const body = notificationPushBody(pushInput);
  const route = `/achievements/detail/${
    encodeURIComponent(input.familyId)
  }?level=1&source=push_reminder`;

  const notificationPayload: Record<string, string> = { title };
  if (body != null) {
    notificationPayload.body = body;
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${config.projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json; charset=utf-8",
      },
      body: JSON.stringify({
        message: {
          token: input.token,
          notification: notificationPayload,
          data: {
            notification_type: type,
            family_id: input.familyId,
            level: "1",
            source: "push_reminder",
            route,
          },
          android: {
            priority: "HIGH",
            notification: {
              channel_id: androidNotificationChannelId,
              default_sound: true,
              default_vibrate_timings: true,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              notification_priority: "PRIORITY_HIGH",
            },
          },
        },
      }),
    },
  );

  const responseText = await response.text();
  if (!response.ok) {
    console.error("FCM send failed", response.status, responseText);
  }
  return { ok: response.ok, responseText };
}

async function deleteInvalidToken(
  client: AppSupabaseClient,
  token: string,
  responseText: string,
): Promise<void> {
  if (
    !responseText.includes("UNREGISTERED") &&
    !responseText.includes("registration-token-not-registered")
  ) {
    return;
  }
  const { error } = await client
    .from("notification_device_tokens")
    .delete()
    .eq("token", token);
  if (error != null) {
    console.error("Failed to delete invalid FCM token", error);
  }
}

async function fcmAccessToken(config: FcmConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken != null && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.token;
  }

  const assertion = await serviceAccountJwt(config, now);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const body = await response.json();
  if (!response.ok || typeof body.access_token !== "string") {
    throw new Error("Unable to fetch FCM access token.");
  }

  cachedAccessToken = {
    token: body.access_token,
    expiresAt: now + Number(body.expires_in ?? 3600),
  };
  return cachedAccessToken.token;
}

async function serviceAccountJwt(
  config: FcmConfig,
  issuedAt: number,
): Promise<string> {
  const header = base64UrlEncodeJson({ alg: "RS256", typ: "JWT" });
  const payload = base64UrlEncodeJson({
    iss: config.clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: issuedAt,
    exp: issuedAt + 3600,
  });
  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(config.privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
}

function fcmConfigFromEnvironment(): FcmConfig | null {
  const rawJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")?.trim() ?? "";
  if (rawJson.length === 0) {
    return null;
  }
  try {
    const parsed = JSON.parse(rawJson) as Record<string, unknown>;
    return normalizeFcmConfig({
      projectId: parsed.project_id,
      clientEmail: parsed.client_email,
      privateKey: parsed.private_key,
    });
  } catch (error) {
    console.error("Invalid FCM_SERVICE_ACCOUNT_JSON", error);
    return null;
  }
}

function normalizeFcmConfig(input: {
  projectId: unknown;
  clientEmail: unknown;
  privateKey: unknown;
}): FcmConfig | null {
  const projectId = typeof input.projectId === "string"
    ? input.projectId.trim()
    : "";
  const clientEmail = typeof input.clientEmail === "string"
    ? input.clientEmail.trim()
    : "";
  const privateKey = typeof input.privateKey === "string"
    ? input.privateKey.replaceAll("\\n", "\n").trim()
    : "";
  if (
    projectId.length === 0 || clientEmail.length === 0 ||
    privateKey.length === 0
  ) {
    return null;
  }
  return { projectId, clientEmail, privateKey };
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

function base64UrlEncodeJson(value: unknown): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}
