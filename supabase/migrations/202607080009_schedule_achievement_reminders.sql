-- Schedules the achievement-reminders Edge Function to run hourly via
-- pg_cron + pg_net, matching the 09:00-23:00 local-time retry window the
-- function itself evaluates per device (see
-- supabase/functions/achievement-reminders/index.ts).
--
-- MANUAL POST-DEPLOY STEP (required, cannot be done from a migration):
-- The function call below reads its target URL and auth header from
-- Vault secrets, because a service-role key must never be committed to a
-- portable SQL migration. After deploying this migration, run once in the
-- SQL editor (or via the CLI) for each environment:
--
--   select vault.create_secret(
--     'https://<project-ref>.supabase.co/functions/v1/achievement-reminders',
--     'achievement_reminders_function_url'
--   );
--   select vault.create_secret(
--     '<service-role-key>',
--     'achievement_reminders_service_role_key'
--   );
--
-- Until both secrets exist, the scheduled job will fail fast (the function
-- body raises if either secret is missing) rather than silently no-op.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

grant usage on schema cron to postgres;

select cron.unschedule(jobid)
from cron.job
where jobname = 'achievement-reminders-hourly';

select cron.schedule(
  'achievement-reminders-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'achievement_reminders_function_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'achievement_reminders_service_role_key')
    ),
    body := '{}'::jsonb
  );
  $$
);
