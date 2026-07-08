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
