# Backend Setup

GlassTrail uses Supabase for auth, database, storage, and Edge Functions.
This guide covers the environment model, local development, configuration
overrides, the smoke check, and the hosted-project checklist.

## Environment model

| Environment | Backend | Source of truth |
| ----------- | ------- | --------------- |
| local/test  | Local Supabase CLI stack | `supabase/config.toml`, `supabase/migrations/`, `supabase/seed.sql` |
| production  | Hosted project **GlassTrail** (`lzuxlcfjnekgjukqxoza`, eu-west-1) | Supabase dashboard + applied schema |

There is no hosted staging environment. Ad hoc hosted test projects can be
targeted with the same `--dart-define` overrides described below, but they are
not part of the official model.

Release builds intentionally ship with the production Supabase URL and the
**publishable** key as defaults in `lib/src/backend_config.dart`. The
publishable (anon) key is safe to embed in clients: all data access is
enforced by row-level security and storage policies. Never commit the
service-role key or other project secrets. Treat any change to
`lib/src/backend_config.dart` as production-impacting.

If no Supabase configuration is available at all, the app falls back to the
on-device `LocalAppRepository` (`SharedPreferences`-backed) — see
`lib/src/repository/repository_factory.dart`.

## Local development stack

Install the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)
(requires Docker), then from the repository root:

```bash
supabase start      # boots the local stack using supabase/config.toml
supabase db reset   # applies supabase/migrations/ and supabase/seed.sql
supabase status     # prints the local API URL and keys
```

`supabase db reset` is the reproducibility check: it must succeed from a
clean stack (`supabase stop --no-backup && supabase start`) with no manual
steps. Migrations use `if exists` / `if not exists` / `on conflict` /
policy-recreation patterns, so keep new migrations re-runnable in the same
style.

Local defaults from `supabase/config.toml`:

- API: `http://127.0.0.1:54321`, DB: port `54322`, Studio: `http://127.0.0.1:54323`
- Email/password auth enabled, email confirmations **disabled** locally so
  sign-up works immediately.
- The private `user-media` storage bucket and its per-user RLS policies are
  created by `supabase/migrations/202603180001_initial_schema.sql`. Media
  paths are `<user-id>/profiles/…`, `<user-id>/custom-drinks/…`, and
  `<user-id>/entries/…`; policies only allow access when the first path
  segment equals the authenticated user id.

## Pointing the app at a backend

`BackendConfig.fromEnvironment()` reads `SUPABASE_URL` and
`SUPABASE_ANON_KEY` at build time and falls back to the production defaults.

Local web/desktop:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local anon key from `supabase status`>
```

Android emulator (the emulator reaches the host via `10.0.2.2`):

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local anon key>
```

Production: no defines required. Any temporary hosted project: pass its URL
and publishable key via the same defines. Keep overrides on the command line
or in a git-ignored `.env` (see `.env.example`); never commit real keys.

## Smoke check

`tool/supabase_smoke_check.dart` verifies a running backend end to end using
only `dart:io` HTTP — no extra dependencies. Copy `.env.example` to `.env`,
fill in values, export them, then:

```bash
dart run tool/supabase_smoke_check.dart
```

- `SUPABASE_URL` + `SUPABASE_ANON_KEY` are required.
- With `GT_SMOKE_USER_A_*`/`GT_SMOKE_USER_B_*` set, it signs in both users and
  checks catalog reads, own profile/settings/custom-drink/entry access, and
  that user B cannot read, update, or delete user A's rows or media.
- Write checks (create + clean up one custom drink, one drink entry, and tiny
  image uploads under `profiles/`, `custom-drinks/`, and `entries/`) run only
  with `GT_SMOKE_ALLOW_WRITES=1`.
- Writes against the production URL are refused unless
  `GT_SMOKE_I_KNOW_THIS_IS_PROD=1` is also set. Use dedicated test users for
  hosted runs.

The env-gated repository tests in `test/supabase_local_repository_test.dart`
cover the same ground through the app's real repository code — see the
"Local Supabase smoke tests" section in the README.

## Migration history vs. hosted production

**Status (checked 2026-07-12):** the hosted project's recorded migration
history diverges from this repository.

- Hosted history contains 11 entries with real-timestamp versions
  (`20260317232638 initial_glasstrail_schema` …
  `20260407211653 extend_global_drinks_catalog`).
- The repository contains 23 migration files named `2026MMDD000N_*.sql` up to
  `202607110001_make_feed_entry_cheers_one_way.sql`.
- The hosted schema **does** contain objects from the later migrations (for
  example the feed-cheers tables), so post-April changes were applied without
  migration records.

Consequences:

- Do **not** run `supabase db push` against production until the history is
  reconciled — it would try to re-apply migrations that are effectively
  already live.
- To reconcile: verify schema parity first, back up production metadata, then
  use `supabase migration list --linked` and
  [`supabase migration repair`](https://supabase.com/docs/reference/cli/supabase-migration-repair)
  to mark the local versions as applied.
- App deployment does **not** apply database migrations automatically. Any
  release that depends on schema changes requires applying and verifying the
  schema separately, before the app release.

## Hosted-project checklist (dashboard-only settings)

These settings live only in the Supabase dashboard and must be checked
manually after project changes:

- **Auth providers:** email/password enabled; confirm the current
  email-confirmation setting. Until the app implements confirmation
  deep-link handling, the app-aligned setting is confirmations disabled.
- **URL configuration:** Site URL and redirect URLs for
  `https://glasstrail.vercel.app/**` and
  `https://glasstrailtest.vercel.app/**` (plus local web URLs if needed).
- **Leaked-password protection:** currently **disabled** (security advisor
  warning). Enabling it is recommended; it only affects new sign-ups and
  password changes.
- **Storage:** private `user-media` bucket exists with the per-user policies.
- **Advisor observations (2026-07-12, non-blocking):** most `public` schema
  `SECURITY DEFINER` functions (friend/notification/feed RPCs) are executable
  by the `anon` role; `drink_entry_cheers` and `notification_device_tokens`
  have RLS enabled without policies (access goes through `SECURITY DEFINER`
  RPCs). Review with `supabase`'s security advisors after schema changes.
