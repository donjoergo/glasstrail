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
