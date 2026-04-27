create or replace function public.prune_expired_notifications()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.notifications
  where (
      read_at is not null
      and read_at < now() - interval '30 days'
    )
    or (
      read_at is null
      and created_at < now() - interval '90 days'
    );
$$;

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

  perform public.prune_expired_notifications();

  return query
  select
    n.id as notification_id,
    n.recipient_user_id,
    n.sender_user_id,
    n.sender_display_name,
    n.image_path,
    n.type as notification_type,
    n.template_args,
    n.created_at,
    n.read_at,
    n.metadata
  from public.notifications n
  where n.recipient_user_id = requesting_user_id
  order by n.created_at desc;
end;
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

  perform public.prune_expired_notifications();

  if coalesce(array_length(notification_ids, 1), 0) > 0 then
    update public.notifications as n
    set read_at = coalesce(n.read_at, now())
    where n.recipient_user_id = requesting_user_id
      and n.id = any(notification_ids);
  end if;

  return query
  select
    n.id as notification_id,
    n.recipient_user_id,
    n.sender_user_id,
    n.sender_display_name,
    n.image_path,
    n.type as notification_type,
    n.template_args,
    n.created_at,
    n.read_at,
    n.metadata
  from public.notifications n
  where n.recipient_user_id = requesting_user_id
  order by n.created_at desc;
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

  perform public.prune_expired_notifications();

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

create or replace function public.cancel_friend_request(target_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requester_user_id uuid;
  addressee_user_id uuid;
  deleted_id uuid;
begin
  delete from public.friend_relationships
  where id = target_relationship_id
    and requester_id = (select auth.uid())
    and status = 'pending'
  returning id, requester_id, addressee_id
  into deleted_id, requester_user_id, addressee_user_id;

  if deleted_id is null then
    raise exception 'The friend request could not be withdrawn.';
  end if;

  delete from public.notifications
  where type = 'friend_request_sent'
    and recipient_user_id = addressee_user_id
    and sender_user_id = requester_user_id
    and metadata->>'relationshipId' = deleted_id::text;
end;
$$;

revoke all on function public.prune_expired_notifications() from public;
revoke all on function public.load_notifications() from public;
revoke all on function public.mark_notifications_read(uuid[]) from public;
revoke all on function public.create_notification(uuid, uuid, text, jsonb, text, jsonb) from public;
revoke all on function public.cancel_friend_request(uuid) from public;

grant execute on function public.load_notifications() to authenticated;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;
grant execute on function public.cancel_friend_request(uuid) to authenticated;
