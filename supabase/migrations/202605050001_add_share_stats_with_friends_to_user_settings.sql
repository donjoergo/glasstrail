alter table public.user_settings
  add column if not exists share_stats_with_friends boolean not null default true;
