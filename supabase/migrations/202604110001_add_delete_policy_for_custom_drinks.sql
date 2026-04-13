drop policy if exists "Users can delete own custom drinks" on public.user_drinks;
create policy "Users can delete own custom drinks"
on public.user_drinks
for delete
to authenticated
using ((select auth.uid()) = user_id);
