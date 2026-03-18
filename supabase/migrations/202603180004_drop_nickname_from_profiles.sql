update public.profiles
set display_name = coalesce(
  nullif(display_name, ''),
  nullif(nickname, ''),
  split_part(coalesce(email, 'glasstrail-user@example.com'), '@', 1)
)
where nullif(display_name, '') is null;

alter table public.profiles
drop column if exists nickname;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    display_name,
    birthday,
    profile_image_path
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      nullif(new.raw_user_meta_data ->> 'nickname', ''),
      split_part(coalesce(new.email, 'glasstrail-user@example.com'), '@', 1)
    ),
    case
      when nullif(new.raw_user_meta_data ->> 'birthday', '') is null then null
      else (new.raw_user_meta_data ->> 'birthday')::date
    end,
    new.raw_user_meta_data ->> 'profile_image_path'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    display_name = excluded.display_name,
    birthday = excluded.birthday,
    profile_image_path = coalesce(
      excluded.profile_image_path,
      public.profiles.profile_image_path
    );

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;
