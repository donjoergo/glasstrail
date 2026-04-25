create table if not exists public.notifications (
  id uuid primary key default extensions.gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  actor_display_name text not null default 'Glass Trail User',
  actor_profile_image_path text,
  type text not null check (
    type in (
      'friend_request_sent',
      'friend_request_accepted',
      'friend_request_rejected',
      'friend_removed'
    )
  ),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  read_at timestamptz
);

create index if not exists notifications_recipient_created_at_idx
  on public.notifications (recipient_user_id, created_at desc);

create index if not exists notifications_recipient_unread_idx
  on public.notifications (recipient_user_id, read_at)
  where read_at is null;

alter table public.notifications enable row level security;

drop policy if exists "Users can read their notifications" on public.notifications;
create policy "Users can read their notifications"
on public.notifications
for select
to authenticated
using ((select auth.uid()) = recipient_user_id);

create table if not exists public.notification_device_tokens (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists notification_device_tokens_token_idx
  on public.notification_device_tokens (token);

create index if not exists notification_device_tokens_user_id_idx
  on public.notification_device_tokens (user_id);

drop trigger if exists notification_device_tokens_touch_updated_at on public.notification_device_tokens;
create trigger notification_device_tokens_touch_updated_at
before update on public.notification_device_tokens
for each row execute procedure public.touch_updated_at();

alter table public.notification_device_tokens enable row level security;

create or replace function public.load_notifications()
returns table (
  notification_id uuid,
  recipient_user_id uuid,
  actor_user_id uuid,
  actor_display_name text,
  actor_profile_image_path text,
  notification_type text,
  created_at timestamptz,
  read_at timestamptz,
  metadata jsonb
)
language sql
security definer
set search_path = public
as $$
  select
    notifications.id as notification_id,
    notifications.recipient_user_id,
    notifications.actor_user_id,
    notifications.actor_display_name,
    notifications.actor_profile_image_path,
    notifications.type as notification_type,
    notifications.created_at,
    notifications.read_at,
    notifications.metadata
  from public.notifications
  where notifications.recipient_user_id = (select auth.uid())
  order by notifications.created_at desc;
$$;

create or replace function public.mark_notifications_read(notification_ids uuid[])
returns table (
  notification_id uuid,
  recipient_user_id uuid,
  actor_user_id uuid,
  actor_display_name text,
  actor_profile_image_path text,
  notification_type text,
  created_at timestamptz,
  read_at timestamptz,
  metadata jsonb
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

  if coalesce(array_length(notification_ids, 1), 0) > 0 then
    update public.notifications
    set read_at = coalesce(read_at, timezone('utc', now()))
    where recipient_user_id = requesting_user_id
      and id = any(notification_ids);
  end if;

  return query
  select
    notifications.id as notification_id,
    notifications.recipient_user_id,
    notifications.actor_user_id,
    notifications.actor_display_name,
    notifications.actor_profile_image_path,
    notifications.type as notification_type,
    notifications.created_at,
    notifications.read_at,
    notifications.metadata
  from public.notifications
  where notifications.recipient_user_id = requesting_user_id
  order by notifications.created_at desc;
end;
$$;

create or replace function public.register_notification_device_token(
  device_token text,
  device_platform text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  normalized_token text := btrim(coalesce(device_token, ''));
  normalized_platform text := lower(btrim(coalesce(device_platform, '')));
begin
  if requesting_user_id is null
      or normalized_token = ''
      or normalized_platform <> 'android' then
    return;
  end if;

  insert into public.notification_device_tokens (
    user_id,
    token,
    platform,
    last_seen_at
  )
  values (
    requesting_user_id,
    normalized_token,
    normalized_platform,
    timezone('utc', now())
  )
  on conflict (token)
  do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    last_seen_at = timezone('utc', now());
end;
$$;

create or replace function public.unregister_notification_device_token(
  device_token text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  normalized_token text := btrim(coalesce(device_token, ''));
begin
  if requesting_user_id is null or normalized_token = '' then
    return;
  end if;

  delete from public.notification_device_tokens
  where user_id = requesting_user_id
    and token = normalized_token;
end;
$$;

create or replace function public.create_friend_notification(
  target_recipient_user_id uuid,
  target_actor_user_id uuid,
  notification_type text,
  notification_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_display_name text;
  actor_profile_image_path text;
  created_notification_id uuid;
begin
  if target_recipient_user_id is null
      or target_actor_user_id is null
      or target_recipient_user_id = target_actor_user_id then
    return null;
  end if;

  select
    profiles.display_name,
    profiles.profile_image_path
  into actor_display_name, actor_profile_image_path
  from public.profiles
  where profiles.id = target_actor_user_id;

  if not found then
    return null;
  end if;

  insert into public.notifications (
    recipient_user_id,
    actor_user_id,
    actor_display_name,
    actor_profile_image_path,
    type,
    metadata
  )
  values (
    target_recipient_user_id,
    target_actor_user_id,
    coalesce(nullif(btrim(actor_display_name), ''), 'Glass Trail User'),
    actor_profile_image_path,
    notification_type,
    coalesce(notification_metadata, '{}'::jsonb)
  )
  returning id into created_notification_id;

  return created_notification_id;
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
  existing_relationship_id uuid;
  existing_status text;
  relationship_id uuid;
  should_notify boolean := false;
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

  select id, status
  into existing_relationship_id, existing_status
  from public.friend_relationships
  where (
    requester_id = requesting_user_id
    and addressee_id = target_user_id
  ) or (
    requester_id = target_user_id
    and addressee_id = requesting_user_id
  )
  for update;

  if existing_relationship_id is null then
    insert into public.friend_relationships (requester_id, addressee_id, status)
    values (requesting_user_id, target_user_id, 'pending')
    returning id into relationship_id;
    should_notify := true;
  elsif existing_status = 'rejected' then
    update public.friend_relationships
    set
      requester_id = requesting_user_id,
      addressee_id = target_user_id,
      status = 'pending'
    where id = existing_relationship_id
    returning id into relationship_id;
    should_notify := true;
  else
    relationship_id := existing_relationship_id;
  end if;

  if should_notify then
    perform public.create_friend_notification(
      target_user_id,
      requesting_user_id,
      'friend_request_sent',
      jsonb_build_object('relationshipId', relationship_id)
    );
  end if;
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
  requester_user_id uuid;
  addressee_user_id uuid;
begin
  update public.friend_relationships
  set status = 'accepted'
  where id = target_relationship_id
    and addressee_id = (select auth.uid())
    and status = 'pending'
  returning id, requester_id, addressee_id
  into updated_id, requester_user_id, addressee_user_id;

  if updated_id is null then
    raise exception 'The friend request could not be accepted.';
  end if;

  perform public.create_friend_notification(
    requester_user_id,
    addressee_user_id,
    'friend_request_accepted',
    jsonb_build_object('relationshipId', updated_id)
  );
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
  requester_user_id uuid;
  addressee_user_id uuid;
begin
  update public.friend_relationships
  set status = 'rejected'
  where id = target_relationship_id
    and addressee_id = (select auth.uid())
    and status = 'pending'
  returning id, requester_id, addressee_id
  into updated_id, requester_user_id, addressee_user_id;

  if updated_id is null then
    raise exception 'The friend request could not be rejected.';
  end if;

  perform public.create_friend_notification(
    requester_user_id,
    addressee_user_id,
    'friend_request_rejected',
    jsonb_build_object('relationshipId', updated_id)
  );
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

  perform public.create_friend_notification(
    target_friend_user_id,
    requesting_user_id,
    'friend_removed',
    jsonb_build_object('relationshipId', deleted_id)
  );
end;
$$;

create or replace function public.enqueue_notification_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  push_url text := nullif(
    btrim(coalesce(current_setting('app.settings.notification_push_url', true), '')),
    ''
  );
  push_secret text := nullif(
    btrim(coalesce(current_setting('app.settings.notification_push_secret', true), '')),
    ''
  );
  request_headers jsonb := jsonb_build_object('Content-Type', 'application/json');
begin
  if push_url is null then
    return new;
  end if;

  if push_secret is not null then
    request_headers := request_headers ||
      jsonb_build_object('x-glasstrail-push-secret', push_secret);
  end if;

  begin
    execute
      'select net.http_post(url := $1, headers := $2, body := $3, timeout_milliseconds := 1000)'
      using push_url, request_headers, jsonb_build_object('notificationId', new.id);
  exception
    when others then
      raise log 'Notification push enqueue failed for %: %', new.id, sqlerrm;
  end;

  return new;
end;
$$;

drop trigger if exists notifications_enqueue_push on public.notifications;
create trigger notifications_enqueue_push
after insert on public.notifications
for each row execute procedure public.enqueue_notification_push();

do $$
begin
  if exists (
    select 1
    from pg_catalog.pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;

revoke all on function public.load_notifications() from public;
revoke all on function public.mark_notifications_read(uuid[]) from public;
revoke all on function public.register_notification_device_token(text, text) from public;
revoke all on function public.unregister_notification_device_token(text) from public;
revoke all on function public.create_friend_notification(uuid, uuid, text, jsonb) from public;
revoke all on function public.enqueue_notification_push() from public;

grant execute on function public.load_notifications() to authenticated;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;
grant execute on function public.register_notification_device_token(text, text) to authenticated;
grant execute on function public.unregister_notification_device_token(text) to authenticated;
