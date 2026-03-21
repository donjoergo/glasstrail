alter table public.drink_entries
  add column if not exists location_latitude double precision,
  add column if not exists location_longitude double precision,
  add column if not exists location_address text;
