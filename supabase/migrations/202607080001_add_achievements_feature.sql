-- Achievements feature: schema extensions, new tables, helper/mutation
-- functions, RLS, and the hourly reminder cron schedule.

-- user_settings: achievement sharing/reminder preferences
alter table public.user_settings
  add column if not exists share_achievements boolean not null default true,
  add column if not exists achievement_reminders_enabled boolean not null default true,
  add column if not exists achievement_catalog_version_seen integer not null default 0;

-- drink_entries: local-time and location context needed for achievement evaluation
alter table public.drink_entries
  add column if not exists achievement_local_date date,
  add column if not exists achievement_utc_offset_minutes integer,
  add column if not exists achievement_time_zone text,
  add column if not exists country_code text,
  add column if not exists location_precision text
    check (location_precision in ('none', 'approximate', 'precise'));

-- notification_device_tokens: time zone context for local-time reminder delivery
alter table public.notification_device_tokens
  add column if not exists time_zone text,
  add column if not exists utc_offset_minutes integer,
  add column if not exists time_zone_updated_at timestamptz not null default timezone('utc', now());

-- achievement_unlocks: one row per (user, family, level) unlock
create table if not exists public.achievement_unlocks (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  family_id text not null,
  level integer not null,
  qualified_at timestamptz not null,
  granted_at timestamptz not null,
  source text not null check (source in ('realtime_log', 'import', 'backfill', 'history_edit', 'settings_change')),
  surfaced_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists achievement_unlocks_user_family_level_idx
  on public.achievement_unlocks (user_id, family_id, level);

create index if not exists achievement_unlocks_user_granted_at_idx
  on public.achievement_unlocks (user_id, granted_at desc);

create index if not exists achievement_unlocks_unsurfaced_idx
  on public.achievement_unlocks (user_id, surfaced_at)
  where surfaced_at is null;

alter table public.achievement_unlocks enable row level security;

drop trigger if exists achievement_unlocks_touch_updated_at on public.achievement_unlocks;
create trigger achievement_unlocks_touch_updated_at
before update on public.achievement_unlocks
for each row execute procedure public.touch_updated_at();

drop policy if exists "Users can read own achievement unlocks" on public.achievement_unlocks;
create policy "Users can read own achievement unlocks"
on public.achievement_unlocks
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own achievement unlocks" on public.achievement_unlocks;
create policy "Users can insert own achievement unlocks"
on public.achievement_unlocks
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own achievement unlocks" on public.achievement_unlocks;
create policy "Users can update own achievement unlocks"
on public.achievement_unlocks
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- saved_places: user's Home/Work locations, one active row per type
create table if not exists public.saved_places (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  place_type text not null check (place_type in ('home', 'work')),
  latitude double precision not null,
  longitude double precision not null,
  is_active boolean not null default true,
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists saved_places_active_type_idx
  on public.saved_places (user_id, place_type)
  where is_active = true;

create index if not exists saved_places_user_type_active_idx
  on public.saved_places (user_id, place_type, is_active);

alter table public.saved_places enable row level security;

drop trigger if exists saved_places_touch_updated_at on public.saved_places;
create trigger saved_places_touch_updated_at
before update on public.saved_places
for each row execute procedure public.touch_updated_at();

drop policy if exists "Users can read own saved places" on public.saved_places;
create policy "Users can read own saved places"
on public.saved_places
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own saved places" on public.saved_places;
create policy "Users can insert own saved places"
on public.saved_places
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own saved places" on public.saved_places;
create policy "Users can update own saved places"
on public.saved_places
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own saved places" on public.saved_places;
create policy "Users can delete own saved places"
on public.saved_places
for delete
to authenticated
using ((select auth.uid()) = user_id);

-- achievement_reminder_deliveries: dedupe log for the reminder cron job
create table if not exists public.achievement_reminder_deliveries (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  device_token_id uuid not null references public.notification_device_tokens(id) on delete cascade,
  family_id text not null,
  occasion_year integer not null,
  eligible_local_date date not null,
  time_zone_used text not null,
  sent_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists achievement_reminder_deliveries_dedupe_idx
  on public.achievement_reminder_deliveries (device_token_id, family_id, occasion_year);

create index if not exists achievement_reminder_deliveries_user_sent_at_idx
  on public.achievement_reminder_deliveries (user_id, sent_at desc);

create index if not exists achievement_reminder_deliveries_device_date_idx
  on public.achievement_reminder_deliveries (device_token_id, eligible_local_date);

-- No client insert/update/delete policies: only the security-definer
-- reminder-sending function (service-role, running in the scheduled Edge
-- Function) writes here. RLS stays enabled with no policies, so this table
-- is unreadable/unwritable to regular authenticated clients.
alter table public.achievement_reminder_deliveries enable row level security;

-- register_notification_device_token: now also captures time zone context
drop function if exists public.register_notification_device_token(text, text);

create or replace function public.register_notification_device_token(
  device_token text,
  device_platform text,
  device_time_zone text default null,
  device_utc_offset_minutes integer default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  normalized_token text := btrim(coalesce(device_token, ''));
  normalized_platform text := lower(btrim(coalesce(device_platform, '')));
  normalized_time_zone text := nullif(btrim(coalesce(device_time_zone, '')), '');
begin
  if requesting_user_id is null
      or normalized_token = ''
      or normalized_platform <> 'android' then
    return;
  end if;

  insert into public.notification_device_tokens (
    user_id,
    token,
    platform,
    last_seen_at,
    time_zone,
    utc_offset_minutes,
    time_zone_updated_at
  )
  values (
    requesting_user_id,
    normalized_token,
    normalized_platform,
    timezone('utc', now()),
    normalized_time_zone,
    device_utc_offset_minutes,
    timezone('utc', now())
  )
  on conflict (token)
  do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    last_seen_at = timezone('utc', now()),
    time_zone = excluded.time_zone,
    utc_offset_minutes = excluded.utc_offset_minutes,
    time_zone_updated_at = timezone('utc', now());
end;
$$;

revoke all on function public.register_notification_device_token(text, text, text, integer) from public;
grant execute on function public.register_notification_device_token(text, text, text, integer) to authenticated;

-- Friend achievement reads go through this dedicated, narrow RPC instead of
-- table-wide friend RLS on achievement_unlocks. Per
-- docs/achievements/checklist-repository-and-sync.md's Friend View Data
-- Contract ("Do not expose unlock timestamps"), granted_at is deliberately
-- excluded from the return set.
create function public.load_friend_shared_achievements(
  target_friend_user_id uuid
)
returns table (
  friend_user_id uuid,
  family_id text,
  level integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  target_shares_achievements boolean;
begin
  if requesting_user_id is null or target_friend_user_id is null then
    return;
  end if;

  if not exists (
    select 1
    from public.friend_relationships relationships
    where relationships.status = 'accepted'
      and (
        (relationships.requester_id = requesting_user_id and relationships.addressee_id = target_friend_user_id)
        or (relationships.requester_id = target_friend_user_id and relationships.addressee_id = requesting_user_id)
      )
  ) then
    return;
  end if;

  select coalesce(settings.share_achievements, false)
  into target_shares_achievements
  from public.user_settings settings
  where settings.user_id = target_friend_user_id;

  if not coalesce(target_shares_achievements, false) then
    return;
  end if;

  return query
  select
    target_friend_user_id,
    unlocks.family_id,
    unlocks.level
  from public.achievement_unlocks unlocks
  where unlocks.user_id = target_friend_user_id
  order by unlocks.granted_at desc;
end;
$$;

revoke all on function public.load_friend_shared_achievements(uuid) from public;
grant execute on function public.load_friend_shared_achievements(uuid) to authenticated;

-- Upserts a batch of achievement unlock grants for the calling user,
-- keeping the earliest qualified_at/granted_at on conflict (multi-device
-- races should never move either timestamp later). Returns the resulting
-- rows for exactly the (family_id, level) pairs requested.
create or replace function public.upsert_achievement_unlocks(
  grants jsonb
)
returns setof public.achievement_unlocks
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  grant_record jsonb;
  requested_family_ids text[] := '{}';
  requested_levels integer[] := '{}';
begin
  if requesting_user_id is null then
    return;
  end if;

  for grant_record in select * from jsonb_array_elements(coalesce(grants, '[]'::jsonb))
  loop
    insert into public.achievement_unlocks (
      user_id,
      family_id,
      level,
      qualified_at,
      granted_at,
      source
    )
    values (
      requesting_user_id,
      grant_record ->> 'familyId',
      (grant_record ->> 'level')::integer,
      (grant_record ->> 'qualifiedAt')::timestamptz,
      (grant_record ->> 'grantedAt')::timestamptz,
      grant_record ->> 'source'
    )
    on conflict (user_id, family_id, level) do update set
      qualified_at = least(achievement_unlocks.qualified_at, excluded.qualified_at),
      granted_at = least(achievement_unlocks.granted_at, excluded.granted_at);

    requested_family_ids := requested_family_ids || (grant_record ->> 'familyId');
    requested_levels := requested_levels || (grant_record ->> 'level')::integer;
  end loop;

  return query
  select unlocks.*
  from public.achievement_unlocks unlocks
  join unnest(requested_family_ids, requested_levels) as requested(family_id, level)
    on unlocks.family_id = requested.family_id and unlocks.level = requested.level
  where unlocks.user_id = requesting_user_id;
end;
$$;

revoke all on function public.upsert_achievement_unlocks(jsonb) from public;
grant execute on function public.upsert_achievement_unlocks(jsonb) to authenticated;

-- Atomically archives the caller's current active place of the given type
-- (if any) and inserts the new active place, avoiding a select-then-insert
-- race between two devices replacing Home/Work at once.
create or replace function public.replace_active_saved_place(
  target_place_type text,
  target_latitude double precision,
  target_longitude double precision
)
returns public.saved_places
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  normalized_place_type text := lower(btrim(coalesce(target_place_type, '')));
  new_row public.saved_places;
begin
  if requesting_user_id is null or normalized_place_type not in ('home', 'work') then
    raise exception 'The place could not be saved.';
  end if;

  update public.saved_places
  set is_active = false,
      archived_at = timezone('utc', now())
  where user_id = requesting_user_id
    and place_type = normalized_place_type
    and is_active = true;

  insert into public.saved_places (
    user_id,
    place_type,
    latitude,
    longitude,
    is_active
  )
  values (
    requesting_user_id,
    normalized_place_type,
    target_latitude,
    target_longitude,
    true
  )
  returning * into new_row;

  return new_row;
end;
$$;

revoke all on function public.replace_active_saved_place(text, double precision, double precision) from public;
grant execute on function public.replace_active_saved_place(text, double precision, double precision) to authenticated;

-- Schedules the achievement-reminders Edge Function to run hourly via
-- pg_cron + pg_net, matching the 09:00-23:00 local-time retry window the
-- function itself evaluates per device (see
-- supabase/functions/achievement-reminders/index.ts).
--
-- MANUAL POST-DEPLOY STEP (required, cannot be done from a migration):
-- The function call below reads its target URL and auth header from
-- Vault secrets, because a service-role key must never be committed to a
-- portable SQL migration. After deploying this migration, run once in the
-- SQL editor (or via the CLI) for each environment:
--
--   select vault.create_secret(
--     'https://<project-ref>.supabase.co/functions/v1/achievement-reminders',
--     'achievement_reminders_function_url'
--   );
--   select vault.create_secret(
--     '<service-role-key>',
--     'achievement_reminders_service_role_key'
--   );
--
-- Until both secrets exist, the scheduled job will fail fast (the function
-- body raises if either secret is missing) rather than silently no-op.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

grant usage on schema cron to postgres;

select cron.unschedule(jobid)
from cron.job
where jobname = 'achievement-reminders-hourly';

select cron.schedule(
  'achievement-reminders-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'achievement_reminders_function_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'achievement_reminders_service_role_key')
    ),
    body := '{}'::jsonb
  );
  $$
);
