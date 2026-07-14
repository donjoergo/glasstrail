alter table public.user_settings
  add column if not exists global_category_order jsonb not null default '[]'::jsonb;

alter table public.user_settings
  drop constraint if exists user_settings_global_category_order_is_array,
  add constraint user_settings_global_category_order_is_array
    check (jsonb_typeof(global_category_order) = 'array');
