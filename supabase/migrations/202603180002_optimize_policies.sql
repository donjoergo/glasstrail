create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create index if not exists global_drinks_category_slug_idx
  on public.global_drinks (category_slug);

create index if not exists user_drinks_category_slug_idx
  on public.user_drinks (category_slug);

create index if not exists drink_entries_category_slug_idx
  on public.drink_entries (category_slug);

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "Users can read own settings" on public.user_settings;
create policy "Users can read own settings"
on public.user_settings
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own settings" on public.user_settings;
create policy "Users can insert own settings"
on public.user_settings
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own settings" on public.user_settings;
create policy "Users can update own settings"
on public.user_settings
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can read own custom drinks" on public.user_drinks;
create policy "Users can read own custom drinks"
on public.user_drinks
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own custom drinks" on public.user_drinks;
create policy "Users can insert own custom drinks"
on public.user_drinks
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own custom drinks" on public.user_drinks;
create policy "Users can update own custom drinks"
on public.user_drinks
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can read own drink entries" on public.drink_entries;
create policy "Users can read own drink entries"
on public.drink_entries
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own drink entries" on public.drink_entries;
create policy "Users can insert own drink entries"
on public.drink_entries
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own drink entries" on public.drink_entries;
create policy "Users can update own drink entries"
on public.drink_entries
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
