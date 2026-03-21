# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app entry point and all runtime code. Most app logic lives under `lib/src/`, with screens in `lib/src/screens/`, repository implementations in `lib/src/repository/`, and shared models, theme, routing, and controller code alongside them. Unit and widget tests live in `test/`, shared test helpers in `test/support/`, and end-to-end coverage in `integration_test/`. Database changes belong in `supabase/migrations/`, with seed data in `supabase/seed.sql`. Treat `android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/` as platform scaffolding; change them only for platform-specific integration work.

## Build, Test, and Development Commands
Run `flutter pub get` after changing dependencies. Use `flutter run` for local development, or pass backend overrides with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`. Run `flutter analyze` before opening a PR to enforce the configured lints. Use `flutter test` for unit and widget tests, and `flutter test integration_test` for end-to-end flows. For database work, use `supabase db reset` to reapply migrations and seed data locally.

## Coding Style & Naming Conventions
This repository follows `flutter_lints` from `analysis_options.yaml`. Keep Dart code formatted with `dart format .`; use 2-space indentation, trailing commas where Flutter formatting benefits, `PascalCase` for types, and `lower_snake_case.dart` for files. Prefer small, focused widgets and keep domain logic in controllers, repositories, or helpers instead of page build methods.

## Testing Guidelines
Add or update tests for every behavior change. Keep test files next to the existing pattern, for example `test/app_controller_test.dart` or `integration_test/app_flow_test.dart`. Name tests as clear behavior statements in single quotes. There is no enforced coverage threshold in the repo, so contributors are expected to cover controller logic, repository behavior, and user-visible UI changes directly.

## Commit & Pull Request Guidelines
Recent history uses Conventional Commits such as `feat(statistics): ...` and `fix(profile): ...`; follow that format for new commits. Keep each commit scoped to one logical change. PRs should explain user-visible impact, note any schema or seed changes, link the relevant issue when available, and include screenshots for UI updates. Call out new `supabase/migrations/*.sql` files explicitly so reviewers can verify backend impact.

## Security & Configuration Tips
Do not commit live Supabase secrets or ad hoc environment files. Production defaults come from `lib/src/backend_config.dart`; temporary local overrides should stay in command-line `--dart-define` flags. Review row-level-security implications whenever you add or modify migrations.

## Agent-Specific Instructions
For Dart and Flutter work in this repository, prefer Dart MCP tools over shell commands whenever possible.

Call `mcp__dart__add_roots` for this repository before other Dart MCP calls when needed. Prefer `mcp__dart__analyze_files` over `flutter analyze`, `mcp__dart__run_tests` over `flutter test`, and `mcp__dart__dart_format` over `dart format`. Use shell `dart` or `flutter` commands only when the Dart MCP cannot perform the task or when the user explicitly asks for shell commands.
