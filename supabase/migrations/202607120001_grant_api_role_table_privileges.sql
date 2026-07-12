-- Newer Supabase stacks no longer grant data privileges on public tables to
-- the API roles by default, so a fresh `supabase db reset` yielded
-- "permission denied" for every table. The hosted production project was
-- provisioned with the old defaults (full data grants for anon and
-- authenticated), so this migration is a no-op there and restores parity
-- locally. Row access remains restricted by the RLS policies; tables with
-- RLS enabled and no policies stay inaccessible to these roles.
grant usage on schema public to anon, authenticated;

grant select, insert, update, delete
  on all tables in schema public
  to anon, authenticated;

grant usage, select
  on all sequences in schema public
  to anon, authenticated;

alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to anon, authenticated;

alter default privileges for role postgres in schema public
  grant usage, select on sequences to anon, authenticated;
