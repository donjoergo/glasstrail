alter table public.user_settings
  drop constraint if exists user_settings_locale_code_check;

alter table public.user_settings
  add constraint user_settings_locale_code_check
    check (locale_code in ('en', 'de', 'de_QM'));
