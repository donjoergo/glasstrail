alter table if exists public.user_settings
add column if not exists handedness text;

update public.user_settings
set handedness = 'right'
where handedness is null;

alter table public.user_settings
alter column handedness set default 'right';

alter table public.user_settings
alter column handedness set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_settings_handedness_check'
  ) then
    alter table public.user_settings
    add constraint user_settings_handedness_check
    check (handedness in ('right', 'left'));
  end if;
end
$$;
