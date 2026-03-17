# GlassTrail

GlassTrail is a Flutter-based drink tracking app. This repository now defaults to the live Supabase backend for the `GlassTrail Codex` project.

Two backend modes still exist:

- `Supabase` by default, using the hardcoded project URL and publishable key in [backend_config.dart](/home/joerg/Dokumente/_Code/glasstrail_codex/lib/src/backend_config.dart)
- `Local fallback` via `SharedPreferences` when a test or a custom bootstrap path injects [BackendConfig.empty](/home/joerg/Dokumente/_Code/glasstrail_codex/lib/src/backend_config.dart)

The local fallback remains useful for automated tests. The production backend path uses Supabase Auth, Postgres, row-level security, and Storage.

## Implemented Scope

- Email/password sign-up and sign-in
- Profile editing with nickname, display name, optional birthday, and optional image path
- Global drink catalog
- User-managed custom drinks
- Drink logging with optional comment and image path
- Personal feed/history
- Weekly, monthly, yearly, streak, and category statistics
- Theme, language, and unit settings
- English and German UI support
- Mobile-first shell with desktop-safe layout
- Live Supabase backend integration with a test-only local fallback

## Backend Architecture

### Supabase

By default, the app uses:

- `supabase_flutter` for client bootstrapping and auth session persistence
- Postgres tables for profiles, settings, custom drinks, and drink entries
- RLS policies so users only access their own private data
- Supabase Storage bucket `user-media` for user-owned media uploads

The repository implementation is in:

- [supabase_app_repository.dart](/home/joerg/Dokumente/_Code/glasstrail_codex/lib/src/repository/supabase_app_repository.dart)

The schema and policies are in:

- [202603180001_initial_schema.sql](/home/joerg/Dokumente/_Code/glasstrail_codex/supabase/migrations/202603180001_initial_schema.sql)
- [202603180002_optimize_policies.sql](/home/joerg/Dokumente/_Code/glasstrail_codex/supabase/migrations/202603180002_optimize_policies.sql)

### Local Fallback

Automated tests and explicitly injected empty backend configs use:

- [local_app_repository.dart](/home/joerg/Dokumente/_Code/glasstrail_codex/lib/src/repository/local_app_repository.dart)

This is what the automated tests use.

## Supabase Setup

The repository is already wired to the hosted `GlassTrail Codex` project and will connect to it by default.

You only need Dart defines if you want to override the baked-in project URL or public key:

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
```

If you want a fully local run, keep using the test harness or inject `BackendConfig.empty` in code.

## Local Tooling

Flutter was bootstrapped locally at:

```bash
/home/joerg/.local/lib/flutter
```

Additional local desktop build tools were installed at:

```bash
/home/joerg/.local/bin/cmake
/home/joerg/.local/bin/ninja
```

Use those binaries if the tools are not on your `PATH`.

## Install Dependencies

```bash
/home/joerg/.local/lib/flutter/bin/flutter pub get
```

## Run The App

With the baked-in live Supabase project:

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux
```

With an override Supabase project:

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
```

## Verification

Static analysis:

```bash
/home/joerg/.local/lib/flutter/bin/flutter analyze
```

Unit, widget, and repository integration tests:

```bash
/home/joerg/.local/lib/flutter/bin/flutter test
```

End-to-end journey test:

```bash
/home/joerg/.local/lib/flutter/bin/flutter test integration_test -d linux
```

## Repository History

The work is split into logical commits:

1. `chore: bootstrap Flutter project`
2. `feat: add the GlassTrail MVP app`
3. `test: add automated app coverage`
4. `docs: add project README`
5. `docs: clarify e2e test command`
6. `feat: integrate Supabase backend support`
7. `docs: document Supabase setup`
8. `fix(supabase): optimize policies and indexes`
