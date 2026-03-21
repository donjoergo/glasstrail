create extension if not exists pgcrypto with schema extensions;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.drink_categories (
  slug text primary key,
  sort_order integer not null,
  name_en text not null,
  name_de text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.global_drinks (
  id text primary key,
  category_slug text not null references public.drink_categories(slug) on delete restrict,
  name_en text not null,
  name_de text not null,
  default_volume_ml numeric(10,2),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  nickname text not null,
  display_name text not null,
  birthday date,
  profile_image_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  theme_preference text not null default 'system' check (theme_preference in ('system', 'light', 'dark')),
  locale_code text not null default 'en' check (locale_code in ('en', 'de')),
  unit text not null default 'ml' check (unit in ('ml', 'oz')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_drinks (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  category_slug text not null references public.drink_categories(slug) on delete restrict,
  volume_ml numeric(10,2),
  image_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists user_drinks_user_id_name_idx
  on public.user_drinks (user_id, lower(name));

create table if not exists public.drink_entries (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_type text not null check (source_type in ('global', 'custom')),
  source_drink_id text not null,
  drink_name text not null,
  category_slug text not null references public.drink_categories(slug) on delete restrict,
  volume_ml numeric(10,2),
  comment text,
  image_path text,
  consumed_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists drink_entries_user_id_consumed_at_idx
  on public.drink_entries (user_id, consumed_at desc);

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute procedure public.touch_updated_at();

drop trigger if exists user_settings_touch_updated_at on public.user_settings;
create trigger user_settings_touch_updated_at
before update on public.user_settings
for each row execute procedure public.touch_updated_at();

drop trigger if exists user_drinks_touch_updated_at on public.user_drinks;
create trigger user_drinks_touch_updated_at
before update on public.user_drinks
for each row execute procedure public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    nickname,
    display_name,
    birthday,
    profile_image_path
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'nickname', split_part(coalesce(new.email, 'glasstrail-user@example.com'), '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, 'GlassTrail User'), '@', 1)),
    case
      when nullif(new.raw_user_meta_data ->> 'birthday', '') is null then null
      else (new.raw_user_meta_data ->> 'birthday')::date
    end,
    new.raw_user_meta_data ->> 'profile_image_path'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    nickname = excluded.nickname,
    display_name = excluded.display_name,
    birthday = excluded.birthday,
    profile_image_path = coalesce(excluded.profile_image_path, public.profiles.profile_image_path);

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.drink_categories enable row level security;
alter table public.global_drinks enable row level security;
alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.user_drinks enable row level security;
alter table public.drink_entries enable row level security;

drop policy if exists "Global categories are readable" on public.drink_categories;
create policy "Global categories are readable"
on public.drink_categories
for select
using (true);

drop policy if exists "Global drinks are readable" on public.global_drinks;
create policy "Global drinks are readable"
on public.global_drinks
for select
using (true);

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can read own settings" on public.user_settings;
create policy "Users can read own settings"
on public.user_settings
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own settings" on public.user_settings;
create policy "Users can insert own settings"
on public.user_settings
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own settings" on public.user_settings;
create policy "Users can update own settings"
on public.user_settings
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can read own custom drinks" on public.user_drinks;
create policy "Users can read own custom drinks"
on public.user_drinks
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own custom drinks" on public.user_drinks;
create policy "Users can insert own custom drinks"
on public.user_drinks
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own custom drinks" on public.user_drinks;
create policy "Users can update own custom drinks"
on public.user_drinks
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can read own drink entries" on public.drink_entries;
create policy "Users can read own drink entries"
on public.drink_entries
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own drink entries" on public.drink_entries;
create policy "Users can insert own drink entries"
on public.drink_entries
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own drink entries" on public.drink_entries;
create policy "Users can update own drink entries"
on public.drink_entries
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('user-media', 'user-media', false)
on conflict (id) do nothing;

drop policy if exists "Users can upload own media" on storage.objects;
create policy "Users can upload own media"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'user-media'
  and coalesce((storage.foldername(name))[1], '') = auth.uid()::text
);

drop policy if exists "Users can read own media" on storage.objects;
create policy "Users can read own media"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-media'
  and coalesce((storage.foldername(name))[1], '') = auth.uid()::text
);

drop policy if exists "Users can update own media" on storage.objects;
create policy "Users can update own media"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'user-media'
  and coalesce((storage.foldername(name))[1], '') = auth.uid()::text
)
with check (
  bucket_id = 'user-media'
  and coalesce((storage.foldername(name))[1], '') = auth.uid()::text
);

drop policy if exists "Users can delete own media" on storage.objects;
create policy "Users can delete own media"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'user-media'
  and coalesce((storage.foldername(name))[1], '') = auth.uid()::text
);
