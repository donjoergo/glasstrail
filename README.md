# GlassTrail

GlassTrail is a Flutter-based drink tracking app. This repository now supports two backend modes:

- `Supabase` when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided
- `Local fallback` via `SharedPreferences` when Supabase is not configured

The local fallback keeps the app runnable and fully testable in this environment. The production-oriented backend path is implemented with Supabase Auth, Postgres, row-level security, and Storage.

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
- Supabase-ready backend integration with automatic local fallback

## Backend Architecture

### Supabase

When configured, the app uses:

- `supabase_flutter` for client bootstrapping and auth session persistence
- Postgres tables for profiles, settings, custom drinks, and drink entries
- RLS policies so users only access their own private data
- Supabase Storage bucket `user-media` for user-owned media uploads

The repository implementation is in:

- [supabase_app_repository.dart](/home/joerg/Dokumente/_Code/glasstrail_codex/lib/src/repository/supabase_app_repository.dart)

The schema and policies are in:

- [202603180001_initial_schema.sql](/home/joerg/Dokumente/_Code/glasstrail_codex/supabase/migrations/202603180001_initial_schema.sql)

### Local Fallback

If no Supabase environment is provided, the app uses:

- [local_app_repository.dart](/home/joerg/Dokumente/_Code/glasstrail_codex/lib/src/repository/local_app_repository.dart)

This is what the automated tests use.

## Supabase Setup

1. Create a Supabase project.
2. Apply the SQL migration from [202603180001_initial_schema.sql](/home/joerg/Dokumente/_Code/glasstrail_codex/supabase/migrations/202603180001_initial_schema.sql).
3. Copy your project URL and anon key from the Supabase dashboard.
4. Run the app with Dart defines:

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If you do not pass those defines, the app will start in local fallback mode.

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

Without Supabase:

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux
```

With Supabase:

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
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

The next commit adds Supabase integration and backend setup documentation.
