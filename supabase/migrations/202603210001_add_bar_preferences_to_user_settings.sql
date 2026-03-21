alter table public.user_settings
  add column if not exists hidden_global_drink_ids jsonb not null default '[]'::jsonb,
  add column if not exists global_drink_order_overrides jsonb not null default '{}'::jsonb;

alter table public.user_settings
  drop constraint if exists user_settings_hidden_global_drink_ids_is_array,
  add constraint user_settings_hidden_global_drink_ids_is_array
    check (jsonb_typeof(hidden_global_drink_ids) = 'array'),
  drop constraint if exists user_settings_global_drink_order_overrides_is_object,
  add constraint user_settings_global_drink_order_overrides_is_object
    check (jsonb_typeof(global_drink_order_overrides) = 'object');
