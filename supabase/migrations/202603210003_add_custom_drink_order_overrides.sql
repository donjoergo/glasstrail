alter table public.user_settings
  add column if not exists custom_drink_order_overrides jsonb not null default '{}'::jsonb;

alter table public.user_settings
  drop constraint if exists user_settings_custom_drink_order_overrides_is_object,
  add constraint user_settings_custom_drink_order_overrides_is_object
    check (jsonb_typeof(custom_drink_order_overrides) = 'object');
