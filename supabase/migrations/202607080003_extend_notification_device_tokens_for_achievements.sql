alter table public.notification_device_tokens
  add column if not exists time_zone text,
  add column if not exists utc_offset_minutes integer,
  add column if not exists time_zone_updated_at timestamptz not null default timezone('utc', now());
