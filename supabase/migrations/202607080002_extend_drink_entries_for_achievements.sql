alter table public.drink_entries
  add column if not exists achievement_local_date date,
  add column if not exists achievement_utc_offset_minutes integer,
  add column if not exists achievement_time_zone text,
  add column if not exists country_code text,
  add column if not exists location_precision text
    check (location_precision in ('none', 'approximate', 'precise'));
