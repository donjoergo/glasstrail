# Repository Guidelines

## Agent Quick Reference
Work on implementation tasks in a meaningful task-specific Git worktree when possible. Worktrees live as sibling checkouts of the primary `main/` checkout, named `<branch>` after a short, descriptive branch name, for example `drink-icons` on branch `drink-icons`. Use `wt switch <item-name>` to create or switch to one; `tool/rebase_worktrees_onto_main.sh` rebases existing worktrees onto `main`.

Before changing code, check the current worktree status and preserve unrelated
user changes. If the agent is already running in a meaningful task-specific worktree, it should keep using that worktree. If not, it should ask the user for approval before creating or switching to one with `wt switch`. Keep changelog updates short and only add or adjust entries when they add useful release context.

Use Conventional Commit messages when asked to commit. Keep the subject short,
around seven words or fewer, such as `fix(profile): save avatar`.

## Project Structure & Module Organization
`lib/main.dart` bootstraps `GlassTrailBootstrapApp` with the platform photo, location, deep-link, and (deferred) push notification services. Core app wiring lives in `lib/src/app.dart`, `lib/src/app_controller.dart`, `lib/src/app_scope.dart`, and `lib/src/app_routes.dart`; cold-start loading lives in `lib/src/bootstrap/app_bootstrap_loader.dart`. Visible pages live in `lib/src/screens/`; the main shell exposes feed, statistics, bar, and profile tabs. Statistics has overview, map, gallery, and history subroutes; bar has sorting and custom-drink subroutes; further dedicated routes cover auth, add-drink, edit-profile, notifications, and friend profile views (`/friends/profile/`, `/friends/view/`). Reusable UI pieces such as `app_media.dart`, `adaptive_modal.dart`, `resizable_master_detail.dart`, and `statistics_overview_content.dart` live in `lib/src/widgets/`.

Repository implementations live in `lib/src/repository/`; `createRepository()` selects `SupabaseAppRepository` when `BackendConfig` is configured — wrapped in `CachedAppRepository` with the bootstrap and media cache stores from `lib/src/cache/` — and falls back to `LocalAppRepository` otherwise. Shared models and helpers live alongside them in files such as `lib/src/models.dart`, `lib/src/stats_calculator.dart`, `lib/src/photo_service.dart`, `lib/src/location_service.dart`, `lib/src/deep_link_service.dart`, `lib/src/push_notification_service.dart`, `lib/src/beer_with_me_import.dart` (plus its flow), and `lib/src/route_memory.dart`.

Localization sources live in `lib/l10n/*.arb` (English and German). Treat `lib/l10n/app_localizations*.dart` as generated output and do not hand-edit it. Unit and widget tests live in `test/`, with reusable fakes and builders in `test/support/test_harness.dart` and cache-specific helpers in `test/support/cache_test_support.dart`; end-to-end flows live in `integration_test/`. Supabase schema changes belong in `supabase/migrations/` using timestamped SQL filenames, with seed data in `supabase/seed.sql`; Edge Functions (`delete-account`, `friend-profile-preview`, `friend-shared-profile`, `send-notification-push`, plus `_shared`) live in `supabase/functions/`. Only `android/` and `web/` are supported runtime targets. Treat `ios/`, `linux/`, `macos/`, and `windows/` as unsupported Flutter scaffolding unless the user explicitly asks for platform-specific work there; the statistics map also relies on the MapLibre registration helpers under `lib/src/maplibre_*`.

## Build, Test, and Development Commands
Run `flutter pub get` after changing dependencies. Use `flutter run` for local development. Override backend values with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`; `BackendConfig.fromEnvironment()` otherwise uses the checked-in production defaults from `lib/src/backend_config.dart`. If you change ARB files, regenerate localization output with `flutter gen-l10n` before finishing the task. After every modification to the language files in `lib/l10n/*.arb`, also run `dart run tool/generate_notification_push_l10n.dart` from the repository root to update the Supabase Edge Function push localization helper.

Prefer Dart MCP tools for Flutter work: call `mcp__dart__add_roots` first, then use `mcp__dart__analyze_files` instead of `flutter analyze`, `mcp__dart__run_tests` instead of `flutter test`, and `mcp__dart__dart_format` instead of `dart format`. When shell commands are needed, match the repository’s real verification flow: CI checks `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test --coverage`, and `flutter build web`, then runs a SonarQube scan. Use `flutter test integration_test` for end-to-end flows. For database work, use `supabase db reset` to reapply migrations and seed data locally.

For documentation-only changes, a diff review is usually enough unless the
edited document has generated output or formatting requirements.

## Coding Style & Naming Conventions
This repository follows `flutter_lints` from `analysis_options.yaml`. Keep Dart code formatted with `dart format .`; use 2-space indentation, trailing commas where Flutter formatting benefits, `PascalCase` for types, and `lower_snake_case.dart` for files. Prefer small widgets and keep non-trivial behavior in `AppController`, repository classes, service classes, or focused helpers rather than page `build` methods.

Keep routing decisions centralized in `lib/src/app_routes.dart`, bootstrap and dependency wiring in `lib/src/app.dart` and `lib/src/repository/repository_factory.dart`, and localization changes in the ARB files instead of the generated Dart output. When touching statistics or map behavior, account for both supported MapLibre platforms and the non-map fallback path.

Only Android and Web are supported application platforms. Do not broaden support to iOS, Linux, macOS, Windows, or other targets unless the user explicitly requests that scope change.

## Testing Guidelines
Add or update tests for every behavior change. Follow the existing naming pattern such as `test/app_controller_test.dart`, `test/home_shell_test.dart`, or `integration_test/app_flow_test.dart`. Name tests as clear behavior statements in single quotes. Reuse `test/support/test_harness.dart` for controller bootstrapping, local repository setup, and fake photo or location services instead of re-creating ad hoc test plumbing.

Cover controller logic, repository behavior, and user-visible UI changes directly. When a change affects route restoration, localization, location/photo flows, or repository selection, add targeted tests for those edges because they are easy to regress silently.

## Commit & Pull Request Guidelines
Use Conventional Commits such as `feat(statistics): ...`, `fix(profile): ...`, or `chore(deps): ...`. Keep each commit scoped to one logical change. Keep changelog entries concise and release-focused. Before adding a new entry, check whether the requested change is already covered by an existing unreleased entry; if it is, leave the changelog alone or refine the existing entry instead of adding another bullet. Use `cider log added ...`, `cider log changed ...`, or `cider log fixed ...` when a new entry is warranted. Prefer editing or consolidating existing unreleased entries when that keeps the changelog clearer, and do not maintain `CHANGELOG.md` manually unless the user explicitly asks for a manual edit or an existing entry needs consolidation that `cider` cannot express cleanly. PRs should summarize user-visible impact, mention any schema or seed changes, link the relevant issue when available, and include screenshots for UI work. Call out new `supabase/migrations/*.sql` files explicitly so reviewers can verify backend and RLS impact.

This repository also has release automation: any pushed tag triggers the Android release workflow, and CI runs on pushes and pull requests targeting `main`. Keep `pubspec.yaml` version updates and release-related changes consistent with that flow.

## Security & Configuration Tips
Do not commit live secrets, ad hoc environment files, Android keystores, or `android/key.properties`. Temporary local backend overrides should stay in command-line `--dart-define` flags. `lib/src/backend_config.dart` contains the production Supabase URL and publishable key, so treat changes there as production-impacting.

Review row-level-security implications whenever you add or modify Supabase migrations. Storage, auth, and database changes in `SupabaseAppRepository` should be reviewed together because the app syncs profile, drink catalog, entries, and media across devices. Changes to `CachedAppRepository` and `lib/src/cache/` affect what is persisted on-device, so review them alongside repository changes.

## Agent-Specific Instructions
For Dart and Flutter work in this repository, prefer Dart MCP tools over shell
commands whenever possible.

Start implementation work by checking whether the current checkout is already a meaningful task-specific worktree, usually a sibling checkout named like `<branch>`. If it is, keep using it. Do not create a new worktree automatically. If the
current checkout is not a meaningful task worktree, ask the user for approval before creating or switching to one with `wt switch <item-name>`. Do not make feature or fix edits directly in the primary checkout unless the user explicitly asks for that.

Call `mcp__dart__add_roots` for this repository before other Dart MCP calls when needed. Prefer `mcp__dart__analyze_files` over `flutter analyze`, `mcp__dart__run_tests` over `flutter test`, and `mcp__dart__dart_format` over `dart format`. Use shell `dart` or `flutter` commands only when the Dart MCP cannot perform the task or when the user explicitly asks for shell commands.

For changelog updates, keep entries short and avoid one-entry-per-request churn.
First check whether the change is already covered by an existing unreleased
entry. Add a new `cider` entry only when the change has distinct release value
for users or reviewers. It is acceptable to refine or consolidate existing
unreleased entries when that makes the changelog clearer.

Do not hand-edit generated localization files under `lib/l10n/`. When changing strings, edit the ARB sources and regenerate; after every ARB modification, also run `dart run tool/generate_notification_push_l10n.dart` from the repository root so push notification strings stay in sync. Prefer existing test helpers in `test/support/test_harness.dart`. Preserve the repository bootstrap split between Supabase-backed and `SharedPreferences`-backed execution, and do not remove the local fallback unless the user explicitly asks for that architectural change.
