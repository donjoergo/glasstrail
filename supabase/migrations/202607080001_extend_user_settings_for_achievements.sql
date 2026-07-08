alter table public.user_settings
  add column if not exists share_achievements boolean not null default true,
  add column if not exists achievement_reminders_enabled boolean not null default true,
  add column if not exists achievement_catalog_version_seen integer not null default 0;
