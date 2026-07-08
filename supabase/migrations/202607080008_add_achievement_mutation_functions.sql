-- Upserts a batch of achievement unlock grants for the calling user,
-- keeping the earliest qualified_at/granted_at on conflict (multi-device
-- races should never move either timestamp later). Returns the resulting
-- rows for exactly the (family_id, level) pairs requested.
create or replace function public.upsert_achievement_unlocks(
  grants jsonb
)
returns setof public.achievement_unlocks
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  grant_record jsonb;
  requested_family_ids text[] := '{}';
  requested_levels integer[] := '{}';
begin
  if requesting_user_id is null then
    return;
  end if;

  for grant_record in select * from jsonb_array_elements(coalesce(grants, '[]'::jsonb))
  loop
    insert into public.achievement_unlocks (
      user_id,
      family_id,
      level,
      qualified_at,
      granted_at,
      source
    )
    values (
      requesting_user_id,
      grant_record ->> 'familyId',
      (grant_record ->> 'level')::integer,
      (grant_record ->> 'qualifiedAt')::timestamptz,
      (grant_record ->> 'grantedAt')::timestamptz,
      grant_record ->> 'source'
    )
    on conflict (user_id, family_id, level) do update set
      qualified_at = least(achievement_unlocks.qualified_at, excluded.qualified_at),
      granted_at = least(achievement_unlocks.granted_at, excluded.granted_at);

    requested_family_ids := requested_family_ids || (grant_record ->> 'familyId');
    requested_levels := requested_levels || (grant_record ->> 'level')::integer;
  end loop;

  return query
  select unlocks.*
  from public.achievement_unlocks unlocks
  join unnest(requested_family_ids, requested_levels) as requested(family_id, level)
    on unlocks.family_id = requested.family_id and unlocks.level = requested.level
  where unlocks.user_id = requesting_user_id;
end;
$$;

revoke all on function public.upsert_achievement_unlocks(jsonb) from public;
grant execute on function public.upsert_achievement_unlocks(jsonb) to authenticated;

-- Atomically archives the caller's current active place of the given type
-- (if any) and inserts the new active place, avoiding a select-then-insert
-- race between two devices replacing Home/Work at once.
create or replace function public.replace_active_saved_place(
  target_place_type text,
  target_latitude double precision,
  target_longitude double precision
)
returns public.saved_places
language plpgsql
security definer
set search_path = public
as $$
declare
  requesting_user_id uuid := (select auth.uid());
  normalized_place_type text := lower(btrim(coalesce(target_place_type, '')));
  new_row public.saved_places;
begin
  if requesting_user_id is null or normalized_place_type not in ('home', 'work') then
    raise exception 'The place could not be saved.';
  end if;

  update public.saved_places
  set is_active = false,
      archived_at = timezone('utc', now())
  where user_id = requesting_user_id
    and place_type = normalized_place_type
    and is_active = true;

  insert into public.saved_places (
    user_id,
    place_type,
    latitude,
    longitude,
    is_active
  )
  values (
    requesting_user_id,
    normalized_place_type,
    target_latitude,
    target_longitude,
    true
  )
  returning * into new_row;

  return new_row;
end;
$$;

revoke all on function public.replace_active_saved_place(text, double precision, double precision) from public;
grant execute on function public.replace_active_saved_place(text, double precision, double precision) to authenticated;
