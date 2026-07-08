# Achievements DB Schema Contract

This document locks the exact storage contract for the achievements feature on the Supabase side.

## Existing Tables To Extend

### `public.user_settings`

Add:

- `share_achievements boolean not null default true`
- `achievement_reminders_enabled boolean not null default true`
- `achievement_catalog_version_seen integer not null default 0`

Notes:

- `share_achievements` is independent from `share_stats_with_friends`.
- `achievement_catalog_version_seen` is the persisted server-side marker for startup backfill version comparison in Supabase mode.

### `public.drink_entries`

Add nullable columns for new achievement-aware entries:

- `achievement_local_date date`
- `achievement_utc_offset_minutes integer`
- `achievement_time_zone text`
- `country_code text`
- `location_precision text check (location_precision in ('none', 'approximate', 'precise'))`

Notes:

- Keep all new columns nullable so legacy rows remain valid without a risky timezone reconstruction migration.
- App code must fall back to best-effort legacy evaluation when these columns are null.
- `country_code` uses lowercase ISO-3166-1 alpha-2 values such as `de`, `us`, `jp`.

### `public.notification_device_tokens`

Add:

- `time_zone text`
- `utc_offset_minutes integer`
- `time_zone_updated_at timestamptz not null default timezone('utc', now())`

Notes:

- Reminders use device timezone data, not a profile timezone.
- Existing `platform in ('android')` check remains valid in v1.
- `last_seen_at` remains the activity gate for the `within 30 days` reminder eligibility rule.

## New Tables

### `public.achievement_unlocks`

Purpose:

- durable, deduplicated record of earned achievement levels

Columns:

- `id uuid primary key default extensions.gen_random_uuid()`
- `user_id uuid not null references public.profiles(id) on delete cascade`
- `family_id text not null`
- `level integer not null`
- `qualified_at timestamptz not null`
- `granted_at timestamptz not null`
- `source text not null check (source in ('realtime_log', 'import', 'backfill', 'history_edit', 'settings_change'))`
- `surfaced_at timestamptz`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

Indexes and constraints:

- unique index on `(user_id, family_id, level)`
- index on `(user_id, granted_at desc)`
- partial index on `(user_id, surfaced_at)` where `surfaced_at is null`

Notes:

- `qualified_at` is when the user’s data first met the rule.
- `granted_at` is when the app/backend persisted the unlock row.
- `surfaced_at` prevents repeated “newly unlocked” summaries for the same row.
- `settings_change` is used for unlocks granted by re-evaluation after relevant settings changes (birthday set, home/work place set or changed, place deletion, first-drink anchor changes).

### `public.saved_places`

Purpose:

- store active and archived `Home` / `Work` achievement places

Columns:

- `id uuid primary key default extensions.gen_random_uuid()`
- `user_id uuid not null references public.profiles(id) on delete cascade`
- `place_type text not null check (place_type in ('home', 'work'))`
- `latitude double precision not null`
- `longitude double precision not null`
- `is_active boolean not null default true`
- `archived_at timestamptz`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

Indexes and constraints:

- partial unique index on `(user_id, place_type)` where `is_active = true`
- index on `(user_id, place_type, is_active)`

Notes:

- Only one active `home` and one active `work` row can exist per user.
- Replacing an active place archives the previous row by setting `is_active = false` and `archived_at`.
- Deleted rows are fully removed and stop contributing to future progress.

### `public.achievement_reminder_deliveries`

Purpose:

- record successful reminder sends and prevent duplicate sends

Columns:

- `id uuid primary key default extensions.gen_random_uuid()`
- `user_id uuid not null references public.profiles(id) on delete cascade`
- `device_token_id uuid not null references public.notification_device_tokens(id) on delete cascade`
- `family_id text not null`
- `occasion_year integer not null`
- `eligible_local_date date not null`
- `time_zone_used text not null`
- `sent_at timestamptz not null`
- `created_at timestamptz not null default timezone('utc', now())`

Indexes and constraints:

- unique index on `(device_token_id, family_id, occasion_year)`
- index on `(user_id, sent_at desc)`
- index on `(device_token_id, eligible_local_date)`

Notes:

- A row is created only after a successful send.
- There is no `opened_at` column in v1.
- `occasion_year` is the dedupe key: the calendar year of the occasion window's first day (New Year uses the year of Dec 31). This guarantees at most one send per device per occasion per year, even for multi-day windows.
- `eligible_local_date` records the actual send day in the device’s local calendar, for debugging only.

## Triggers

Add `touch_updated_at()` triggers where `updated_at` exists:

- `achievement_unlocks`
- `saved_places`
- `notification_device_tokens` already has one and should keep it

## Helper SQL Functions

### Replace `register_notification_device_token`

Final RPC shape:

```sql
public.register_notification_device_token(
  device_token text,
  device_platform text,
  device_time_zone text,
  device_utc_offset_minutes integer
)
```

Behavior:

- upsert by `token`
- refresh `user_id`
- refresh `platform`
- refresh `last_seen_at`
- refresh `time_zone`
- refresh `utc_offset_minutes`
- refresh `time_zone_updated_at`

### New friend-read RPC

Add:

```sql
public.load_friend_shared_achievements(target_friend_user_id uuid)
```

Returns only:

- `friend_user_id`
- `family_id`
- `level`
- `granted_at`

Behavior:

- requester must be authenticated
- requester and target must be friends
- target must have `share_achievements = true`
- only earned rows from `achievement_unlocks` are returned

Notes:

- `granted_at` is returned only so the client can sort the friend's achievements by `granted_at desc`. The friend UI must never display it.

## RLS Policies

### `achievement_unlocks`

- owner `select`
- owner `insert`
- owner `update`
- no direct cross-user select

Friend visibility should go through the dedicated RPC, not table-wide friend RLS.

### `saved_places`

- owner `select`
- owner `insert`
- owner `update`
- owner `delete`

### `achievement_reminder_deliveries`

- no client writes
- owner `select` only if the app ever needs it
- service-role or security-definer function writes

## Migration Strategy

Recommended migration split:

1. extend `user_settings`
2. extend `drink_entries`
3. extend `notification_device_tokens`
4. create `achievement_unlocks`
5. create `saved_places`
6. create `achievement_reminder_deliveries`
7. add/update helper functions and RLS

## Explicit Non-Goals

- No local-to-cloud achievement migration table
- No reminder-open tracking column
- No progress snapshot table
- No copied localized titles/descriptions in unlock rows

## Acceptance

- The database can represent all locked achievement state, saved places, and reminder send markers.
- Friend achievement reads are privacy-gated and independent from shared statistics.
- Legacy entries remain valid without a lossy timezone reconstruction migration.
