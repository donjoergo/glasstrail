-- Drop the old set_feed_entry_cheers function that accepts should_cheer
drop function if exists public.set_feed_entry_cheers(uuid, boolean);

-- Recreate set_feed_entry_cheers as a one-way action
create or replace function public.set_feed_entry_cheers(
  target_entry_id uuid
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

revoke all on function public.set_feed_entry_cheers(uuid) from public;
grant execute on function public.set_feed_entry_cheers(uuid) to authenticated;
