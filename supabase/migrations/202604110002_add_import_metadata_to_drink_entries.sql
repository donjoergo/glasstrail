alter table public.drink_entries
  add column if not exists import_source text,
  add column if not exists import_source_id text;

create unique index if not exists drink_entries_user_id_import_source_source_id_idx
  on public.drink_entries (user_id, import_source, import_source_id)
  where import_source is not null and import_source_id is not null;
