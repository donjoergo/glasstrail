alter table public.profiles
  add column if not exists profile_share_code text;

update public.profiles
set profile_share_code = replace(extensions.gen_random_uuid()::text, '-', '')
where profile_share_code is null or btrim(profile_share_code) = '';

alter table public.profiles
  alter column profile_share_code set default replace(extensions.gen_random_uuid()::text, '-', ''),
  alter column profile_share_code set not null;

create unique index if not exists profiles_profile_share_code_idx
  on public.profiles (profile_share_code);

create table if not exists public.friend_relationships (
  id uuid primary key default extensions.gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (requester_id <> addressee_id)
);

create unique index if not exists friend_relationships_unique_pair_idx
  on public.friend_relationships (
    (least(requester_id, addressee_id)),
    (greatest(requester_id, addressee_id))
  );

create index if not exists friend_relationships_requester_status_idx
  on public.friend_relationships (requester_id, status);

create index if not exists friend_relationships_addressee_status_idx
  on public.friend_relationships (addressee_id, status);

drop trigger if exists friend_relationships_touch_updated_at on public.friend_relationships;
create trigger friend_relationships_touch_updated_at
before update on public.friend_relationships
for each row execute procedure public.touch_updated_at();

alter table public.friend_relationships enable row level security;

drop policy if exists "Users can read their friend relationships" on public.friend_relationships;
create policy "Users can read their friend relationships"
on public.friend_relationships
for select
to authenticated
using (
  (select auth.uid()) = requester_id
  or (select auth.uid()) = addressee_id
);

drop policy if exists "Users can create outgoing friend requests" on public.friend_relationships;
create policy "Users can create outgoing friend requests"
on public.friend_relationships
for insert
to authenticated
with check (
  (select auth.uid()) = requester_id
  and requester_id <> addressee_id
  and status = 'pending'
);

drop policy if exists "Users can update incoming friend requests" on public.friend_relationships;
create policy "Users can update incoming friend requests"
on public.friend_relationships
for update
to authenticated
using ((select auth.uid()) = addressee_id)
with check ((select auth.uid()) = addressee_id);

drop policy if exists "Users can delete accepted friend relationships" on public.friend_relationships;
create policy "Users can delete accepted friend relationships"
on public.friend_relationships
for delete
to authenticated
using (
  status = 'accepted'
  and (
    (select auth.uid()) = requester_id
    or (select auth.uid()) = addressee_id
  )
);

create or replace function public.are_friends(left_user_id uuid, right_user_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.friend_relationships
    where status = 'accepted'
      and (
        (requester_id = left_user_id and addressee_id = right_user_id)
        or (requester_id = right_user_id and addressee_id = left_user_id)
      )
  );
$$;

create or replace function public.load_friend_connections()
returns table (
  relationship_id uuid,
  profile_id uuid,
  email text,
  display_name text,
  profile_image_path text,
  profile_share_code text,
  status text,
  direction text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
begin
  if requesting_user_id is null then
    return;
  end if;

  return query
  select
    relationships.id as relationship_id,
    other_profile.id as profile_id,
    other_profile.email,
    other_profile.display_name,
    other_profile.profile_image_path,
    other_profile.profile_share_code,
    relationships.status,
    case
      when relationships.status = 'accepted' then 'none'
      when relationships.addressee_id = requesting_user_id then 'incoming'
      else 'outgoing'
    end as direction
  from public.friend_relationships relationships
  join public.profiles other_profile
    on other_profile.id = case
      when relationships.requester_id = requesting_user_id then relationships.addressee_id
      else relationships.requester_id
    end
  where relationships.status <> 'rejected'
    and (
      relationships.requester_id = requesting_user_id
      or relationships.addressee_id = requesting_user_id
    )
  order by
    case
      when relationships.status = 'accepted' then 0
      when relationships.addressee_id = requesting_user_id then 1
      else 2
    end,
    lower(other_profile.display_name);
end;
$$;

create or replace function public.resolve_friend_profile_link(target_share_code text)
returns table (
  profile_id uuid,
  email text,
  display_name text,
  profile_image_path text,
  profile_share_code text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select auth.uid()) is null then
    return;
  end if;

  return query
  select
    profiles.id as profile_id,
    profiles.email,
    profiles.display_name,
    profiles.profile_image_path,
    profiles.profile_share_code
  from public.profiles profiles
  where profiles.profile_share_code = btrim(target_share_code)
  limit 1;
end;
$$;

create or replace function public.send_friend_request_to_profile(target_share_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  target_user_id uuid;
begin
  if requesting_user_id is null then
    raise exception 'The profile link is invalid.';
  end if;

  select id
  into target_user_id
  from public.profiles
  where profile_share_code = btrim(target_share_code);

  if target_user_id is null then
    raise exception 'The profile link is invalid.';
  end if;

  if target_user_id = requesting_user_id then
    raise exception 'You cannot add yourself as a friend.';
  end if;

  insert into public.friend_relationships (requester_id, addressee_id, status)
  values (requesting_user_id, target_user_id, 'pending')
  on conflict (
    (least(requester_id, addressee_id)),
    (greatest(requester_id, addressee_id))
  )
  do update set
    requester_id = case
      when public.friend_relationships.status = 'rejected' then excluded.requester_id
      else public.friend_relationships.requester_id
    end,
    addressee_id = case
      when public.friend_relationships.status = 'rejected' then excluded.addressee_id
      else public.friend_relationships.addressee_id
    end,
    status = case
      when public.friend_relationships.status = 'rejected' then 'pending'
      else public.friend_relationships.status
    end;
end;
$$;

create or replace function public.accept_friend_request(target_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_id uuid;
begin
  update public.friend_relationships
  set status = 'accepted'
  where id = target_relationship_id
    and addressee_id = (select auth.uid())
    and status = 'pending'
  returning id into updated_id;

  if updated_id is null then
    raise exception 'The friend request could not be accepted.';
  end if;
end;
$$;

create or replace function public.reject_friend_request(target_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_id uuid;
begin
  update public.friend_relationships
  set status = 'rejected'
  where id = target_relationship_id
    and addressee_id = (select auth.uid())
    and status = 'pending'
  returning id into updated_id;

  if updated_id is null then
    raise exception 'The friend request could not be rejected.';
  end if;
end;
$$;

create or replace function public.remove_friend(target_friend_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  deleted_id uuid;
begin
  delete from public.friend_relationships
  where status = 'accepted'
    and (
      (requester_id = requesting_user_id and addressee_id = target_friend_user_id)
      or (requester_id = target_friend_user_id and addressee_id = requesting_user_id)
    )
  returning id into deleted_id;

  if deleted_id is null then
    raise exception 'The friend could not be removed.';
  end if;
end;
$$;

revoke all on function public.are_friends(uuid, uuid) from public;
revoke all on function public.load_friend_connections() from public;
revoke all on function public.resolve_friend_profile_link(text) from public;
revoke all on function public.send_friend_request_to_profile(text) from public;
revoke all on function public.accept_friend_request(uuid) from public;
revoke all on function public.reject_friend_request(uuid) from public;
revoke all on function public.remove_friend(uuid) from public;

grant execute on function public.are_friends(uuid, uuid) to authenticated;
grant execute on function public.load_friend_connections() to authenticated;
grant execute on function public.resolve_friend_profile_link(text) to authenticated;
grant execute on function public.send_friend_request_to_profile(text) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;
grant execute on function public.reject_friend_request(uuid) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;

drop policy if exists "Users can read own media" on storage.objects;
drop policy if exists "Users can read own and friends media" on storage.objects;
create policy "Users can read own and friends media"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-media'
  and (
    coalesce((storage.foldername(name))[1], '') = (select auth.uid())::text
    or (
      coalesce((storage.foldername(name))[1], '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and public.are_friends(
        (select auth.uid()),
        coalesce((storage.foldername(name))[1], '')::uuid
      )
    )
  )
);
