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
    when 'friend_request_accepted' then 'https://glasstrail-git-codex-friend-notifications-donjoergos-projects.vercel.app//notification-assets/cheers.png'
    when 'friend_request_rejected' then 'https://glasstrail-git-codex-friend-notifications-donjoergos-projects.vercel.app//notification-assets/sad.jpg'
    when 'friend_removed' then 'https://glasstrail-git-codex-friend-notifications-donjoergos-projects.vercel.app//notification-assets/sad.jpg'
    else nullif(btrim(fallback_image_path), '')
  end;
$$;

update public.notifications
set image_path = public.notification_image_path_for_type(type, image_path)
where type in (
  'friend_request_accepted',
  'friend_request_rejected',
  'friend_removed'
)
and image_path is distinct from public.notification_image_path_for_type(type, image_path);

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
    public.notification_image_path_for_type(
      notification_type,
      sender_profile_image_path
    ),
    notification_metadata
  );
end;
$$;

revoke all on function public.notification_image_path_for_type(text, text) from public;
revoke all on function public.create_friend_notification(uuid, uuid, text, jsonb) from public;
