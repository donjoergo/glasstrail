create or replace function public.cancel_friend_request(target_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_id uuid;
begin
  delete from public.friend_relationships
  where id = target_relationship_id
    and requester_id = (select auth.uid())
    and status = 'pending'
  returning id into deleted_id;

  if deleted_id is null then
    raise exception 'The friend request could not be withdrawn.';
  end if;
end;
$$;

revoke all on function public.cancel_friend_request(uuid) from public;
grant execute on function public.cancel_friend_request(uuid) to authenticated;
