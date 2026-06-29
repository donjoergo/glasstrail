alter table public.user_drinks
add column if not exists accent_color_hex text;

alter table public.user_drinks
drop constraint if exists user_drinks_accent_color_hex_format;

alter table public.user_drinks
add constraint user_drinks_accent_color_hex_format
check (
  accent_color_hex is null
  or accent_color_hex ~ '^#[0-9A-F]{6}$'
);
