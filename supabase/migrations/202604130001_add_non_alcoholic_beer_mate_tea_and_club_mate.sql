insert into public.global_drinks (
  id,
  category_slug,
  name_en,
  name_de,
  default_volume_ml
)
values
  (
    'beer-non-alcoholic',
    'beer',
    'Non-alcoholic Beer',
    'Alkoholfreies Bier',
    500
  ),
  (
    'nonAlcoholic-mate-tea',
    'nonAlcoholic',
    'Mate Tea',
    'Mate Tee',
    300
  ),
  (
    'nonAlcoholic-club-mate',
    'nonAlcoholic',
    'Club-Mate',
    'Club-Mate',
    500
  )
on conflict (id) do update
set
  category_slug = excluded.category_slug,
  name_en = excluded.name_en,
  name_de = excluded.name_de,
  default_volume_ml = excluded.default_volume_ml;
