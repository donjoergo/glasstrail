# Repository Guidelines

## Project Structure & Module Organization
`lib/main.dart` bootstraps `GlassTrailBootstrapApp` with the platform photo and location services. Core app wiring lives in `lib/src/app.dart`, `lib/src/app_controller.dart`, `lib/src/app_scope.dart`, and `lib/src/app_routes.dart`. Visible pages live in `lib/src/screens/`; the main shell currently exposes feed/history, statistics, bar, and profile tabs, plus dedicated auth, add-drink, and edit-profile routes. Repository implementations live in `lib/src/repository/`; `createRepository()` selects `SupabaseAppRepository` when `BackendConfig` is configured and falls back to `LocalAppRepository` otherwise. Shared models and helpers live alongside them in files such as `lib/src/models.dart`, `lib/src/stats_calculator.dart`, `lib/src/photo_service.dart`, `lib/src/location_service.dart`, and `lib/src/route_memory.dart`.

Localization sources live in `lib/l10n/*.arb`. Treat `lib/l10n/app_localizations*.dart` as generated output and do not hand-edit it. Unit and widget tests live in `test/`, with reusable fakes and builders in `test/support/test_harness.dart`; end-to-end flows live in `integration_test/`. Supabase schema changes belong in `supabase/migrations/` using timestamped SQL filenames, with seed data in `supabase/seed.sql`. Treat `android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/` as platform scaffolding unless the work is explicitly platform-specific; the statistics map also relies on the MapLibre registration helpers under `lib/src/maplibre_*`.

## Build, Test, and Development Commands
Run `flutter pub get` after changing dependencies. Use `flutter run` for local development. Override backend values with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`; `BackendConfig.fromEnvironment()` otherwise uses the checked-in production defaults from `lib/src/backend_config.dart`. If you change ARB files, regenerate localization output with `flutter gen-l10n` before finishing the task.

Prefer Dart MCP tools for Flutter work: call `mcp__dart__add_roots` first, then use `mcp__dart__analyze_files` instead of `flutter analyze`, `mcp__dart__run_tests` instead of `flutter test`, and `mcp__dart__dart_format` instead of `dart format`. When shell commands are needed, match the repository’s real verification flow: CI checks `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test`. Use `flutter test integration_test` for end-to-end flows. For database work, use `supabase db reset` to reapply migrations and seed data locally.

## Coding Style & Naming Conventions
This repository follows `flutter_lints` from `analysis_options.yaml`. Keep Dart code formatted with `dart format .`; use 2-space indentation, trailing commas where Flutter formatting benefits, `PascalCase` for types, and `lower_snake_case.dart` for files. Prefer small widgets and keep non-trivial behavior in `AppController`, repository classes, service classes, or focused helpers rather than page `build` methods.

Keep routing decisions centralized in `lib/src/app_routes.dart`, bootstrap and dependency wiring in `lib/src/app.dart` and `lib/src/repository/repository_factory.dart`, and localization changes in the ARB files instead of the generated Dart output. When touching statistics or map behavior, account for both supported MapLibre platforms and the non-map fallback path.

## Testing Guidelines
Add or update tests for every behavior change. Follow the existing naming pattern such as `test/app_controller_test.dart`, `test/home_shell_test.dart`, or `integration_test/app_flow_test.dart`. Name tests as clear behavior statements in single quotes. Reuse `test/support/test_harness.dart` for controller bootstrapping, local repository setup, and fake photo or location services instead of re-creating ad hoc test plumbing.

Cover controller logic, repository behavior, and user-visible UI changes directly. When a change affects route restoration, localization, location/photo flows, or repository selection, add targeted tests for those edges because they are easy to regress silently.

## Commit & Pull Request Guidelines
Use Conventional Commits such as `feat(statistics): ...`, `fix(profile): ...`, or `chore(deps): ...`. Keep each commit scoped to one logical change. For every change, also add a changelog entry with a `cider` command such as `cider log added ...`, `cider log changed ...`, or `cider log fixed ...`; do not maintain `CHANGELOG.md` manually. PRs should summarize user-visible impact, mention any schema or seed changes, link the relevant issue when available, and include screenshots for UI work. Call out new `supabase/migrations/*.sql` files explicitly so reviewers can verify backend and RLS impact.

This repository also has release automation: tags matching `v*` trigger the Android release workflow, and CI runs on pushes and pull requests targeting `main`. Keep `pubspec.yaml` version updates and release-related changes consistent with that flow.

## Security & Configuration Tips
Do not commit live secrets, ad hoc environment files, Android keystores, or `android/key.properties`. Temporary local backend overrides should stay in command-line `--dart-define` flags. `lib/src/backend_config.dart` contains the production Supabase URL and publishable key, so treat changes there as production-impacting.

Review row-level-security implications whenever you add or modify Supabase migrations. Storage, auth, and database changes in `SupabaseAppRepository` should be reviewed together because the app syncs profile, drink catalog, entries, and media across devices.

## Agent-Specific Instructions
For Dart and Flutter work in this repository, prefer Dart MCP tools over shell commands whenever possible.

Call `mcp__dart__add_roots` for this repository before other Dart MCP calls when needed. Prefer `mcp__dart__analyze_files` over `flutter analyze`, `mcp__dart__run_tests` over `flutter test`, and `mcp__dart__dart_format` over `dart format`. Use shell `dart` or `flutter` commands only when the Dart MCP cannot perform the task or when the user explicitly asks for shell commands.

For every repository change, add a changelog entry via a `cider` command and do not edit `CHANGELOG.md` by hand unless the user explicitly asks for a manual edit.

Do not hand-edit generated localization files under `lib/l10n/`. When changing strings, edit the ARB sources and regenerate. Prefer existing test helpers in `test/support/test_harness.dart`. Preserve the repository bootstrap split between Supabase-backed and `SharedPreferences`-backed execution, and do not remove the local fallback unless the user explicitly asks for that architectural change.
