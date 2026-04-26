do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'actor_user_id'
  ) then
    alter table public.notifications
      rename column actor_user_id to sender_user_id;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'actor_display_name'
  ) then
    alter table public.notifications
      rename column actor_display_name to sender_display_name;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'actor_profile_image_path'
  ) then
    alter table public.notifications
      rename column actor_profile_image_path to image_path;
  end if;
end;
$$;

alter table public.notifications
  drop constraint if exists notifications_type_check,
  drop constraint if exists notifications_title_i18n_check,
  drop constraint if exists notifications_text_i18n_check;

alter table public.notifications
  add column if not exists template_args jsonb;

update public.notifications
set template_args = case
  when template_args is null or jsonb_typeof(template_args) <> 'object' then '{}'::jsonb
  else template_args
end;

update public.notifications
set template_args = template_args || jsonb_build_object(
  'senderDisplayName',
  coalesce(nullif(btrim(sender_display_name), ''), 'Glass Trail User')
)
where not (template_args ? 'senderDisplayName');

alter table public.notifications
  alter column template_args set default '{}'::jsonb,
  alter column template_args set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'notifications_template_args_check'
      and conrelid = 'public.notifications'::regclass
  ) then
    alter table public.notifications
      add constraint notifications_template_args_check
      check (jsonb_typeof(template_args) = 'object');
  end if;
end;
$$;

drop function if exists public.load_notifications();
drop function if exists public.mark_notifications_read(uuid[]);
drop function if exists public.create_friend_notification(uuid, uuid, text, jsonb);
drop function if exists public.create_notification(uuid, uuid, text, jsonb, jsonb, text, jsonb);
drop function if exists public.create_notification(uuid, uuid, text, jsonb, text, jsonb);

alter table public.notifications
  drop column if exists title_i18n,
  drop column if exists text_i18n;

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

revoke all on function public.load_notifications() from public;
revoke all on function public.mark_notifications_read(uuid[]) from public;
revoke all on function public.create_notification(uuid, uuid, text, jsonb, text, jsonb) from public;
revoke all on function public.create_friend_notification(uuid, uuid, text, jsonb) from public;

grant execute on function public.load_notifications() to authenticated;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;
