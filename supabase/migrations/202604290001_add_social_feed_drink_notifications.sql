create index if not exists drink_entries_feed_order_idx
  on public.drink_entries (consumed_at desc, id desc);

create or replace function public.notification_image_path_for_type(
  notification_type text,
  fallback_image_path text
)
returns text
language sql
stable
as $$
  select case btrim(coalesce(notification_type, ''))
    when 'friend_request_accepted' then 'https://glasstrail.vercel.app/notification-assets/cheers.png'
    when 'friend_request_rejected' then 'https://glasstrail.vercel.app/notification-assets/request_rejected.png'
    when 'friend_removed' then 'https://glasstrail.vercel.app/notification-assets/friend_removed.png'
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
  'friend_drink_logged'
)
and image_path is distinct from public.notification_image_path_for_type(type, image_path);

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
  is_own_entry boolean
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
    entries.user_id = requesting_user_id as is_own_entry
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

create or replace function public.create_friend_drink_logged_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_user_id uuid;
  sender_display_name text := 'Glass Trail User';
  sender_profile_image_path text;
  notification_image_path text;
  notification_template_args jsonb;
begin
  if new.user_id is null
      or nullif(btrim(coalesce(new.import_source, '')), '') is not null then
    return new;
  end if;

  select
    coalesce(nullif(btrim(profiles.display_name), ''), 'Glass Trail User'),
    nullif(btrim(profiles.profile_image_path), '')
  into sender_display_name, sender_profile_image_path
  from public.profiles
  where profiles.id = new.user_id;

  if not found then
    return new;
  end if;

  notification_image_path = coalesce(
    nullif(btrim(new.image_path), ''),
    sender_profile_image_path,
    'https://glasstrail.vercel.app/notification-assets/app-icon.png'
  );

  notification_template_args = jsonb_build_object(
    'senderDisplayName', sender_display_name,
    'drinkId', new.source_drink_id,
    'drinkName', new.drink_name
  );

  if nullif(btrim(coalesce(new.comment, '')), '') is not null then
    notification_template_args = notification_template_args ||
      jsonb_build_object('comment', btrim(new.comment));
  end if;

  if nullif(btrim(coalesce(new.location_address, '')), '') is not null then
    notification_template_args = notification_template_args ||
      jsonb_build_object('locationAddress', btrim(new.location_address));
  end if;

  for recipient_user_id in
    select case
      when relationships.requester_id = new.user_id then relationships.addressee_id
      else relationships.requester_id
    end
    from public.friend_relationships relationships
    where relationships.status = 'accepted'
      and (
        relationships.requester_id = new.user_id
        or relationships.addressee_id = new.user_id
      )
  loop
    perform public.create_notification(
      recipient_user_id,
      new.user_id,
      'friend_drink_logged',
      notification_template_args,
      notification_image_path,
      jsonb_build_object('entryId', new.id, 'route', '/feed')
    );
  end loop;

  return new;
end;
$$;

create or replace function public.delete_friend_drink_logged_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.user_id is null then
    return old;
  end if;

  delete from public.notifications
  where type = 'friend_drink_logged'
    and sender_user_id = old.user_id
    and metadata ->> 'entryId' = old.id::text;

  return old;
end;
$$;

create or replace function public.update_friend_drink_logged_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  current_sender_display_name text := 'Glass Trail User';
  current_sender_profile_image_path text;
  notification_image_path text;
  notification_template_args jsonb;
begin
  if old.user_id is null then
    return new;
  end if;

  if new.user_id is null
      or nullif(btrim(coalesce(new.import_source, '')), '') is not null then
    delete from public.notifications
    where type = 'friend_drink_logged'
      and sender_user_id = old.user_id
      and metadata ->> 'entryId' = old.id::text;
    return new;
  end if;

  select
    coalesce(nullif(btrim(profiles.display_name), ''), 'Glass Trail User'),
    nullif(btrim(profiles.profile_image_path), '')
  into current_sender_display_name, current_sender_profile_image_path
  from public.profiles
  where profiles.id = new.user_id;

  if not found then
    return new;
  end if;

  notification_image_path = coalesce(
    nullif(btrim(new.image_path), ''),
    current_sender_profile_image_path,
    'https://glasstrail.vercel.app/notification-assets/app-icon.png'
  );

  notification_template_args = jsonb_build_object(
    'senderDisplayName', current_sender_display_name,
    'drinkId', new.source_drink_id,
    'drinkName', new.drink_name
  );

  if nullif(btrim(coalesce(new.comment, '')), '') is not null then
    notification_template_args = notification_template_args ||
      jsonb_build_object('comment', btrim(new.comment));
  end if;

  if nullif(btrim(coalesce(new.location_address, '')), '') is not null then
    notification_template_args = notification_template_args ||
      jsonb_build_object('locationAddress', btrim(new.location_address));
  end if;

  update public.notifications
  set sender_display_name = current_sender_display_name,
      image_path = public.notification_image_path_for_type(
        'friend_drink_logged',
        notification_image_path
      ),
      template_args = notification_template_args
  where type = 'friend_drink_logged'
    and sender_user_id = old.user_id
    and metadata ->> 'entryId' = old.id::text;

  return new;
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

  delete from public.notifications
  where type = 'friend_drink_logged'
    and (
      (recipient_user_id = requesting_user_id and sender_user_id = target_friend_user_id)
      or (recipient_user_id = target_friend_user_id and sender_user_id = requesting_user_id)
    );

  perform public.create_friend_notification(
    target_friend_user_id,
    requesting_user_id,
    'friend_removed',
    jsonb_build_object('relationshipId', deleted_id)
  );
end;
$$;

drop trigger if exists friend_drink_logged_notifications on public.drink_entries;
create trigger friend_drink_logged_notifications
after insert on public.drink_entries
for each row execute function public.create_friend_drink_logged_notifications();

drop trigger if exists friend_drink_logged_notifications_update on public.drink_entries;
create trigger friend_drink_logged_notifications_update
after update on public.drink_entries
for each row execute function public.update_friend_drink_logged_notifications();

drop trigger if exists friend_drink_logged_notifications_cleanup on public.drink_entries;
create trigger friend_drink_logged_notifications_cleanup
after delete on public.drink_entries
for each row execute function public.delete_friend_drink_logged_notifications();

revoke all on function public.notification_image_path_for_type(text, text) from public;
revoke all on function public.load_feed_drink_posts(integer, timestamptz, uuid) from public;
revoke all on function public.create_friend_drink_logged_notifications() from public;
revoke all on function public.update_friend_drink_logged_notifications() from public;
revoke all on function public.delete_friend_drink_logged_notifications() from public;

grant execute on function public.load_feed_drink_posts(integer, timestamptz, uuid) to authenticated;
