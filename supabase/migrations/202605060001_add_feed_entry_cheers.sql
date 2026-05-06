create table if not exists public.drink_entry_cheers (
  entry_id uuid not null references public.drink_entries(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (entry_id, user_id)
);

create index if not exists drink_entry_cheers_entry_id_idx
  on public.drink_entry_cheers (entry_id);

create index if not exists drink_entry_cheers_user_id_idx
  on public.drink_entry_cheers (user_id);

alter table public.drink_entry_cheers enable row level security;

create or replace function public.notification_image_path_for_type(
  notification_type text,
  fallback_image_path text
)
returns text
language sql
stable
set search_path = public
as $$
  select case btrim(coalesce(notification_type, ''))
    when 'friend_request_accepted' then 'https://glasstrail.vercel.app/notification-assets/request_accepted.png'
    when 'friend_request_rejected' then 'https://glasstrail.vercel.app/notification-assets/request_rejected.png'
    when 'friend_removed' then 'https://glasstrail.vercel.app/notification-assets/friend_removed.png'
    when 'friend_drink_cheered' then 'https://glasstrail.vercel.app/notification-assets/cheers.png'
    when 'friend_drink_logged' then coalesce(
      nullif(btrim(fallback_image_path), ''),
      'https://glasstrail.vercel.app/notification-assets/app-icon.png'
    )
    else nullif(btrim(fallback_image_path), '')
  end;
$$;

update public.notifications
set image_path = public.notification_image_path_for_type(type, image_path)
where type in (
  'friend_request_accepted',
  'friend_request_rejected',
  'friend_removed',
  'friend_drink_cheered',
  'friend_drink_logged'
)
and image_path is distinct from public.notification_image_path_for_type(type, image_path);

drop function if exists public.load_feed_drink_posts(integer, timestamptz, uuid);

create or replace function public.load_feed_drink_posts(
  page_limit integer default 20,
  cursor_consumed_at timestamptz default null,
  cursor_id uuid default null
)
returns table (
  id uuid,
  user_id uuid,
  source_drink_id text,
  drink_name text,
  category_slug text,
  volume_ml numeric,
  is_alcohol_free boolean,
  comment text,
  image_path text,
  location_latitude double precision,
  location_longitude double precision,
  location_address text,
  import_source text,
  import_source_id text,
  consumed_at timestamptz,
  author_profile_id uuid,
  author_email text,
  author_display_name text,
  author_profile_image_path text,
  author_profile_share_code text,
  is_own_entry boolean,
  cheers_count integer,
  has_current_user_cheered boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  sanitized_page_limit integer := least(greatest(coalesce(page_limit, 20), 1), 50);
begin
  if requesting_user_id is null then
    return;
  end if;

  return query
  with visible_profiles as (
    select requesting_user_id as profile_id
    union
    select case
      when relationships.requester_id = requesting_user_id then relationships.addressee_id
      else relationships.requester_id
    end as profile_id
    from public.friend_relationships relationships
    where relationships.status = 'accepted'
      and (
        relationships.requester_id = requesting_user_id
        or relationships.addressee_id = requesting_user_id
      )
  )
  select
    entries.id,
    entries.user_id,
    entries.source_drink_id,
    entries.drink_name,
    entries.category_slug,
    entries.volume_ml,
    entries.is_alcohol_free,
    entries.comment,
    entries.image_path,
    entries.location_latitude,
    entries.location_longitude,
    entries.location_address,
    entries.import_source,
    entries.import_source_id,
    entries.consumed_at,
    author.id as author_profile_id,
    author.email as author_email,
    coalesce(nullif(btrim(author.display_name), ''), 'Glass Trail User') as author_display_name,
    author.profile_image_path as author_profile_image_path,
    author.profile_share_code as author_profile_share_code,
    entries.user_id = requesting_user_id as is_own_entry,
    coalesce((
      select count(*)::integer
      from public.drink_entry_cheers cheers
      where cheers.entry_id = entries.id
    ), 0) as cheers_count,
    exists(
      select 1
      from public.drink_entry_cheers cheers
      where cheers.entry_id = entries.id
        and cheers.user_id = requesting_user_id
    ) as has_current_user_cheered
  from public.drink_entries entries
  join visible_profiles
    on visible_profiles.profile_id = entries.user_id
  join public.profiles author
    on author.id = entries.user_id
  where cursor_consumed_at is null
    or cursor_id is null
    or entries.consumed_at < cursor_consumed_at
    or (
      entries.consumed_at = cursor_consumed_at
      and entries.id < cursor_id
    )
  order by entries.consumed_at desc, entries.id desc
  limit sanitized_page_limit + 1;
end;
$$;

create or replace function public.set_feed_entry_cheers(
  target_entry_id uuid,
  should_cheer boolean
)
returns table (
  cheers_count integer,
  has_current_user_cheered boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  entry_owner_user_id uuid;
  inserted_row_count integer := 0;
begin
  if requesting_user_id is null or target_entry_id is null then
    raise exception 'The cheers could not be updated.';
  end if;

  select user_id
  into entry_owner_user_id
  from public.drink_entries
  where id = target_entry_id;

  if entry_owner_user_id is null or entry_owner_user_id = requesting_user_id then
    raise exception 'The cheers could not be updated.';
  end if;

  if not exists (
    select 1
    from public.friend_relationships relationships
    where relationships.status = 'accepted'
      and (
        (relationships.requester_id = requesting_user_id and relationships.addressee_id = entry_owner_user_id)
        or (relationships.requester_id = entry_owner_user_id and relationships.addressee_id = requesting_user_id)
      )
  ) then
    raise exception 'The cheers could not be updated.';
  end if;

  if coalesce(should_cheer, false) then
    insert into public.drink_entry_cheers (
      entry_id,
      user_id
    )
    values (
      target_entry_id,
      requesting_user_id
    )
    on conflict (entry_id, user_id) do nothing;

    get diagnostics inserted_row_count = row_count;

    if inserted_row_count > 0 then
      perform public.create_friend_notification(
        entry_owner_user_id,
        requesting_user_id,
        'friend_drink_cheered',
        jsonb_build_object('entryId', target_entry_id, 'route', '/feed')
      );
    end if;
  else
    delete from public.drink_entry_cheers
    where entry_id = target_entry_id
      and user_id = requesting_user_id;

    delete from public.notifications
    where type = 'friend_drink_cheered'
      and recipient_user_id = entry_owner_user_id
      and sender_user_id = requesting_user_id
      and metadata ->> 'entryId' = target_entry_id::text;
  end if;

  return query
  select
    coalesce((
      select count(*)::integer
      from public.drink_entry_cheers cheers
      where cheers.entry_id = target_entry_id
    ), 0),
    exists(
      select 1
      from public.drink_entry_cheers cheers
      where cheers.entry_id = target_entry_id
        and cheers.user_id = requesting_user_id
    );
end;
$$;

create or replace function public.delete_friend_drink_cheered_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.notifications
  where type = 'friend_drink_cheered'
    and metadata ->> 'entryId' = old.id::text;

  return old;
end;
$$;

create or replace function public.cleanup_feed_cheers_for_deleted_friendship()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status <> 'accepted' then
    return old;
  end if;

  delete from public.drink_entry_cheers cheers
  using public.drink_entries entries
  where cheers.entry_id = entries.id
    and (
      (entries.user_id = old.requester_id and cheers.user_id = old.addressee_id)
      or (entries.user_id = old.addressee_id and cheers.user_id = old.requester_id)
    );

  delete from public.notifications
  where type = 'friend_drink_cheered'
    and (
      (recipient_user_id = old.requester_id and sender_user_id = old.addressee_id)
      or (recipient_user_id = old.addressee_id and sender_user_id = old.requester_id)
    );

  return old;
end;
$$;

drop trigger if exists friend_drink_cheered_notifications_cleanup on public.drink_entries;
create trigger friend_drink_cheered_notifications_cleanup
after delete on public.drink_entries
for each row execute function public.delete_friend_drink_cheered_notifications();

drop trigger if exists cleanup_feed_cheers_for_deleted_friendship on public.friend_relationships;
create trigger cleanup_feed_cheers_for_deleted_friendship
after delete on public.friend_relationships
for each row execute function public.cleanup_feed_cheers_for_deleted_friendship();

revoke all on function public.notification_image_path_for_type(text, text) from public;
revoke all on function public.load_feed_drink_posts(integer, timestamptz, uuid) from public;
revoke all on function public.set_feed_entry_cheers(uuid, boolean) from public;
revoke all on function public.delete_friend_drink_cheered_notifications() from public;
revoke all on function public.cleanup_feed_cheers_for_deleted_friendship() from public;

grant execute on function public.load_feed_drink_posts(integer, timestamptz, uuid) to authenticated;
grant execute on function public.set_feed_entry_cheers(uuid, boolean) to authenticated;
