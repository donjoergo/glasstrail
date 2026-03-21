insert into public.drink_categories (slug, sort_order, name_en, name_de)
values
  ('beer', 1, 'Beer', 'Bier'),
  ('wine', 2, 'Wine', 'Wein'),
  ('spirits', 3, 'Spirits', 'Spirituosen'),
  ('cocktails', 4, 'Cocktails', 'Cocktails'),
  ('nonAlcoholic', 5, 'Non-alcoholic', 'Alkoholfrei')
on conflict (slug) do update
set
  sort_order = excluded.sort_order,
  name_en = excluded.name_en,
  name_de = excluded.name_de;

insert into public.global_drinks (id, category_slug, name_en, name_de, default_volume_ml)
values
  ('beer-pils', 'beer', 'Pils', 'Pils', 330),
  ('beer-helles', 'beer', 'Helles', 'Helles', 500),
  ('beer-weizen', 'beer', 'Weizen', 'Weizen', 500),
  ('beer-kellerbier', 'beer', 'Kellerbier', 'Kellerbier', 500),
  ('beer-kölsch', 'beer', 'Kölsch', 'Kölsch', 200),
  ('beer-alt', 'beer', 'Alt', 'Alt', 250),
  ('beer-ipa', 'beer', 'IPA', 'IPA', 330),
  ('wine-red-wine', 'wine', 'Red Wine', 'Rotwein', 150),
  ('wine-white-wine', 'wine', 'White Wine', 'Weißwein', 150),
  ('wine-rosé-wine', 'wine', 'Rosé Wine', 'Roséwein', 150),
  ('wine-sparkling-wine', 'wine', 'Sparkling Wine', 'Sekt', 120),
  ('wine-aperol-spritz', 'wine', 'Aperol Spritz', 'Aperol Spritz', 200),
  ('spirits-vodka', 'spirits', 'Vodka', 'Wodka', 40),
  ('spirits-gin', 'spirits', 'Gin', 'Gin', 40),
  ('spirits-rum', 'spirits', 'Rum', 'Rum', 40),
  ('spirits-whiskey', 'spirits', 'Whiskey', 'Whiskey', 40),
  ('spirits-tequila', 'spirits', 'Tequila', 'Tequila', 40),
  ('cocktails-mojito', 'cocktails', 'Mojito', 'Mojito', 250),
  ('cocktails-margarita', 'cocktails', 'Margarita', 'Margarita', 180),
  ('cocktails-martini', 'cocktails', 'Martini', 'Martini', 160),
  ('nonAlcoholic-water', 'nonAlcoholic', 'Water', 'Wasser', 250),
  ('nonAlcoholic-juice', 'nonAlcoholic', 'Juice', 'Saft', 250),
  ('nonAlcoholic-sparkling-water', 'nonAlcoholic', 'Sparkling Water', 'Sprudelwasser', 250),
  ('nonAlcoholic-tea', 'nonAlcoholic', 'Tea', 'Tee', 300),
  ('nonAlcoholic-coffee', 'nonAlcoholic', 'Coffee', 'Kaffee', 200),
  ('nonAlcoholic-energy-drink', 'nonAlcoholic', 'Energy Drink', 'Energy Drink', 250),
  ('nonAlcoholic-cola', 'nonAlcoholic', 'Cola', 'Cola', 330),
  ('nonAlcoholic-lemonade', 'nonAlcoholic', 'Lemonade', 'Limonade', 330)
on conflict (id) do update
set
  category_slug = excluded.category_slug,
  name_en = excluded.name_en,
  name_de = excluded.name_de,
  default_volume_ml = excluded.default_volume_ml;
