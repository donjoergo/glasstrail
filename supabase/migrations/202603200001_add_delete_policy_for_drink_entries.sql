drop policy if exists "Users can delete own drink entries" on public.drink_entries;
create policy "Users can delete own drink entries"
on public.drink_entries
for delete
to authenticated
using ((select auth.uid()) = user_id);
