-- Security hardening:
--   1. Restrict pending-friendship media reads to profile avatars only, so a
--      one-sided (unaccepted) friend request can no longer read the target's
--      drink-entry photos. Accepted friends keep full folder access, and
--      pending-request avatars keep rendering.
--   2. Add explicit owner-scoped policies to drink_entry_cheers and
--      notification_device_tokens. Both had RLS enabled with no policy (safe
--      only implicitly, via SECURITY DEFINER access); this states the intent.
--   3. Revoke REST execute on trigger-only / internal SECURITY DEFINER
--      functions so they are not callable via /rest/v1/rpc/. Trigger execution
--      is unaffected.

-- ============================================================
-- 1. Pending friendship: profile avatars only, never entry photos.
-- ============================================================
drop policy if exists "Users can read own media" on storage.objects;
drop policy if exists "Users can read own and friends media" on storage.objects;
create policy "Users can read own and friends media"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-media'
  and (
    coalesce((storage.foldername(name))[1], '') = (select auth.uid())::text
    or (
      coalesce((storage.foldername(name))[1], '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and exists (
        select 1
        from public.friend_relationships relationships
        where (
              (
                relationships.requester_id = (select auth.uid())
                and relationships.addressee_id = coalesce((storage.foldername(name))[1], '')::uuid
              )
              or (
                relationships.requester_id = coalesce((storage.foldername(name))[1], '')::uuid
                and relationships.addressee_id = (select auth.uid())
              )
            )
          and (
            relationships.status = 'accepted'
            or (
              relationships.status = 'pending'
              and coalesce((storage.foldername(name))[2], '') = 'profiles'
            )
          )
      )
    )
  )
);

-- ============================================================
-- 2. Make the function-only access intent explicit.
-- ============================================================
drop policy if exists "Users can read own cheers" on public.drink_entry_cheers;
create policy "Users can read own cheers"
on public.drink_entry_cheers
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can manage own device tokens" on public.notification_device_tokens;
create policy "Users can manage own device tokens"
on public.notification_device_tokens
for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- ============================================================
-- 3. Revoke REST execute on trigger-only / internal functions.
-- ============================================================
revoke all on function public.handle_new_user() from anon, authenticated;
revoke all on function public.prune_expired_notifications() from anon, authenticated;
revoke all on function public.create_notification(uuid, uuid, text, jsonb, text, jsonb) from anon, authenticated;
revoke all on function public.create_friend_notification(uuid, uuid, text, jsonb) from anon, authenticated;
revoke all on function public.create_friend_drink_logged_notifications() from anon, authenticated;
revoke all on function public.update_friend_drink_logged_notifications() from anon, authenticated;
revoke all on function public.delete_friend_drink_logged_notifications() from anon, authenticated;
revoke all on function public.delete_friend_drink_cheered_notifications() from anon, authenticated;
revoke all on function public.cleanup_feed_cheers_for_deleted_friendship() from anon, authenticated;
revoke all on function public.are_friends(uuid, uuid) from anon, authenticated;
