# GlassTrail

GlassTrail is a Flutter-based drink tracking app. This repository contains a usable V1 MVP focused on private drink logging, personal history, statistics, profile management, localization, theming, and custom drinks.

## Implemented Scope

- Email/password sign-up and sign-in
- Personal profile with nickname, display name, optional birthday, and optional photo attachment path
- Multi-user local persistence with user-scoped data isolation
- Seeded global drink catalog across alcoholic and non-alcoholic categories
- User-managed custom drinks
- Add-drink flow with recent drinks, search, category grouping, optional comment, optional photo attachment path, and volume entry
- Personal feed/history
- Statistics for weekly, monthly, yearly totals, streaks, and category breakdown
- Settings for theme, language, and units
- English and German UI support
- Responsive shell for mobile and wide desktop layouts

## Technical Notes

- The current implementation uses `SharedPreferences` as a local persistence backend so the app works out of the box in this environment.
- The domain structure is ready for a backend swap later. The product plan still recommends `Supabase` for hosted auth, storage, and social features.
- Photo selection stores the selected file path and surfaces it in the UI. A real upload/storage backend can be added later.

## Local Tooling

Flutter was bootstrapped locally at:

```bash
/home/joerg/.local/lib/flutter
```

Use that binary if `flutter` is not on your `PATH`.

## Install Dependencies

```bash
/home/joerg/.local/lib/flutter/bin/flutter pub get
```

## Run The App

```bash
/home/joerg/.local/lib/flutter/bin/flutter run -d linux
```

## Test Commands

Unit, widget, and repository integration tests:

```bash
/home/joerg/.local/lib/flutter/bin/flutter test
```

End-to-end journey test:

```bash
/home/joerg/.local/lib/flutter/bin/flutter test integration_test
```

Static analysis:

```bash
/home/joerg/.local/lib/flutter/bin/flutter analyze
```

## Repository History

The work is split into logical commits:

1. `chore: bootstrap Flutter project`
2. `feat: add the GlassTrail MVP app`

The next commit adds tests and documentation.
