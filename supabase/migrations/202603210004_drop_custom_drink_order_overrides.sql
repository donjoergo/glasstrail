alter table public.user_settings
  drop constraint if exists user_settings_custom_drink_order_overrides_is_object,
  drop column if exists custom_drink_order_overrides;
