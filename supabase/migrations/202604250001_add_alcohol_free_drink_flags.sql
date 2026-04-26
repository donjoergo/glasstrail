alter table public.global_drinks
  add column if not exists is_alcohol_free boolean not null default false;

alter table public.user_drinks
  add column if not exists is_alcohol_free boolean not null default false;

alter table public.drink_entries
  add column if not exists is_alcohol_free boolean not null default false;

update public.global_drinks
set is_alcohol_free = true
where category_slug = 'nonAlcoholic'
   or id = 'beer-non-alcoholic';

update public.user_drinks
set is_alcohol_free = true
where category_slug = 'nonAlcoholic';

update public.drink_entries
set is_alcohol_free = true
where category_slug = 'nonAlcoholic';
