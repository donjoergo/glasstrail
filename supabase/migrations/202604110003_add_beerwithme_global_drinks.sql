insert into public.global_drinks (
  id,
  category_slug,
  name_en,
  name_de,
  default_volume_ml
)
values
  ('beer-classic', 'beer', 'Beer', 'Bier', 500),
  ('beer-can', 'beer', 'Beer Can', 'Dosenbier', 500),
  ('shots-shot', 'shots', 'Shot', 'Shot', 20)
on conflict (id) do update
set
  category_slug = excluded.category_slug,
  name_en = excluded.name_en,
  name_de = excluded.name_de,
  default_volume_ml = excluded.default_volume_ml;
