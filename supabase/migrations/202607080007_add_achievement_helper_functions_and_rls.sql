drop function if exists public.register_notification_device_token(text, text);

create or replace function public.register_notification_device_token(
  device_token text,
  device_platform text,
  device_time_zone text default null,
  device_utc_offset_minutes integer default null
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
  normalized_time_zone text := nullif(btrim(coalesce(device_time_zone, '')), '');
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
    last_seen_at,
    time_zone,
    utc_offset_minutes,
    time_zone_updated_at
  )
  values (
    requesting_user_id,
    normalized_token,
    normalized_platform,
    timezone('utc', now()),
    normalized_time_zone,
    device_utc_offset_minutes,
    timezone('utc', now())
  )
  on conflict (token)
  do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    last_seen_at = timezone('utc', now()),
    time_zone = excluded.time_zone,
    utc_offset_minutes = excluded.utc_offset_minutes,
    time_zone_updated_at = timezone('utc', now());
end;
$$;

revoke all on function public.register_notification_device_token(text, text, text, integer) from public;
grant execute on function public.register_notification_device_token(text, text, text, integer) to authenticated;

-- Friend achievement reads go through this dedicated, narrow RPC instead of
-- table-wide friend RLS on achievement_unlocks.
create or replace function public.load_friend_shared_achievements(
  target_friend_user_id uuid
)
returns table (
  friend_user_id uuid,
  family_id text,
  level integer,
  granted_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  target_shares_achievements boolean;
begin
  if requesting_user_id is null or target_friend_user_id is null then
    return;
  end if;

  if not exists (
    select 1
    from public.friend_relationships relationships
    where relationships.status = 'accepted'
      and (
        (relationships.requester_id = requesting_user_id and relationships.addressee_id = target_friend_user_id)
        or (relationships.requester_id = target_friend_user_id and relationships.addressee_id = requesting_user_id)
      )
  ) then
    return;
  end if;

  select coalesce(settings.share_achievements, false)
  into target_shares_achievements
  from public.user_settings settings
  where settings.user_id = target_friend_user_id;

  if not coalesce(target_shares_achievements, false) then
    return;
  end if;

  return query
  select
    target_friend_user_id,
    unlocks.family_id,
    unlocks.level,
    unlocks.granted_at
  from public.achievement_unlocks unlocks
  where unlocks.user_id = target_friend_user_id
  order by unlocks.granted_at desc;
end;
$$;

revoke all on function public.load_friend_shared_achievements(uuid) from public;
grant execute on function public.load_friend_shared_achievements(uuid) to authenticated;
