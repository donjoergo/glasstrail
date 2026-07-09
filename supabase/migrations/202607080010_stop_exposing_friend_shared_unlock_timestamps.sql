-- docs/achievements/checklist-repository-and-sync.md's Friend View Data
-- Contract says "Do not expose unlock timestamps". The original
-- load_friend_shared_achievements (202607080007) returned granted_at over
-- the wire; the Dart client already discarded it before reaching the UI,
-- but the RPC payload itself still carried it. Recreate the function
-- without that column -- Postgres requires DROP before a return-type
-- change, CREATE OR REPLACE cannot alter output columns.
drop function if exists public.load_friend_shared_achievements(uuid);

create function public.load_friend_shared_achievements(
  target_friend_user_id uuid
)
returns table (
  friend_user_id uuid,
  family_id text,
  level integer
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
    unlocks.level
  from public.achievement_unlocks unlocks
  where unlocks.user_id = target_friend_user_id
  order by unlocks.granted_at desc;
end;
$$;

revoke all on function public.load_friend_shared_achievements(uuid) from public;
grant execute on function public.load_friend_shared_achievements(uuid) to authenticated;
