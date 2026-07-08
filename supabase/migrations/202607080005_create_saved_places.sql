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
