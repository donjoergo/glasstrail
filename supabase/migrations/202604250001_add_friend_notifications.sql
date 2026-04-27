create table if not exists public.notifications (
  id uuid primary key default extensions.gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  sender_user_id uuid references public.profiles(id) on delete set null,
  sender_display_name text not null default 'Glass Trail User',
  image_path text,
  type text not null,
  template_args jsonb not null default '{}'::jsonb check (jsonb_typeof(template_args) = 'object'),
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
  sender_user_id uuid,
  sender_display_name text,
  image_path text,
  notification_type text,
  template_args jsonb,
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
    notifications.sender_user_id,
    notifications.sender_display_name,
    notifications.image_path,
    notifications.type as notification_type,
    notifications.template_args,
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
  sender_user_id uuid,
  sender_display_name text,
  image_path text,
  notification_type text,
  template_args jsonb,
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
    notifications.sender_user_id,
    notifications.sender_display_name,
    notifications.image_path,
    notifications.type as notification_type,
    notifications.template_args,
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

create or replace function public.create_notification(
  target_recipient_user_id uuid,
  target_sender_user_id uuid,
  notification_type text,
  notification_template_args jsonb default '{}'::jsonb,
  notification_image_path text default null,
  notification_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_display_name text := 'Glass Trail User';
  created_notification_id uuid;
begin
  if target_recipient_user_id is null
      or btrim(coalesce(notification_type, '')) = ''
      or notification_template_args is null
      or jsonb_typeof(notification_template_args) <> 'object' then
    return null;
  end if;

  if target_sender_user_id is not null then
    select coalesce(nullif(btrim(profiles.display_name), ''), 'Glass Trail User')
    into sender_display_name
    from public.profiles
    where profiles.id = target_sender_user_id;

    if not found then
      return null;
    end if;
  end if;

  insert into public.notifications (
    recipient_user_id,
    sender_user_id,
    sender_display_name,
    image_path,
    type,
    template_args,
    metadata
  )
  values (
    target_recipient_user_id,
    target_sender_user_id,
    sender_display_name,
    nullif(btrim(notification_image_path), ''),
    btrim(notification_type),
    notification_template_args,
    coalesce(notification_metadata, '{}'::jsonb)
  )
  returning id into created_notification_id;

  return created_notification_id;
end;
$$;

create or replace function public.create_friend_notification(
  target_recipient_user_id uuid,
  target_sender_user_id uuid,
  notification_type text,
  notification_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_display_name text;
  sender_profile_image_path text;
begin
  if target_recipient_user_id is null
      or target_sender_user_id is null
      or target_recipient_user_id = target_sender_user_id then
    return null;
  end if;

  select
    coalesce(nullif(btrim(profiles.display_name), ''), 'Glass Trail User'),
    profiles.profile_image_path
  into sender_display_name, sender_profile_image_path
  from public.profiles
  where profiles.id = target_sender_user_id;

  if not found then
    return null;
  end if;

  return public.create_notification(
    target_recipient_user_id,
    target_sender_user_id,
    notification_type,
    jsonb_build_object('senderDisplayName', sender_display_name),
    sender_profile_image_path,
    notification_metadata
  );
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
  relationship_id uuid;
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

  -- Let the unique pair index serialize concurrent requests for the same pair.
  insert into public.friend_relationships (requester_id, addressee_id, status)
  values (requesting_user_id, target_user_id, 'pending')
  on conflict (
    (least(requester_id, addressee_id)),
    (greatest(requester_id, addressee_id))
  )
  do update set
    requester_id = excluded.requester_id,
    addressee_id = excluded.addressee_id,
    status = 'pending'
  where public.friend_relationships.status = 'rejected'
  returning id into relationship_id;

  if relationship_id is not null then
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
revoke all on function public.create_notification(uuid, uuid, text, jsonb, text, jsonb) from public;
revoke all on function public.create_friend_notification(uuid, uuid, text, jsonb) from public;

grant execute on function public.load_notifications() to authenticated;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;
grant execute on function public.register_notification_device_token(text, text) to authenticated;
grant execute on function public.unregister_notification_device_token(text) to authenticated;
