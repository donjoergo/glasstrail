alter table public.user_settings
  add column if not exists hidden_global_drink_categories jsonb not null default '[]'::jsonb;

alter table public.user_settings
  drop constraint if exists user_settings_hidden_global_drink_categories_is_array,
  add constraint user_settings_hidden_global_drink_categories_is_array
    check (jsonb_typeof(hidden_global_drink_categories) = 'array');
