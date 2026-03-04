# Codex Guidelines For This Flutter Repo

This file is the actionable, condensed version of `rules.md` for day-to-day
Codex work in this project.

## Project Layout
- App code: `lib/`
- Entry/app shell: `lib/main.dart`, `lib/app.dart`,
  `lib/pages/app_shell.dart`
- State/controller layer: `lib/state/app_controller.dart`
- Data/model/API: `lib/data/`, `lib/models/`, `lib/api/backend_api.dart`
- Feature UI: `lib/pages/`, `lib/onboarding/`, `lib/theme/`, `lib/l10n/`
- Tests: `test/`

## Core Workflow
- Install deps: `flutter pub get`
- Local run (mock data): `flutter run -d chrome`
- Local run (backend): `flutter run -d chrome --dart-define=USE_REMOTE_API=true --dart-define=API_BASE_URL=http://localhost:3000`
- Static checks: `flutter analyze`
- Tests: `flutter test`
- Format before finalizing: `dart format .`
- After replacing `assets/icon/app_icon.png`, regenerate launcher icons:
  `dart run flutter_launcher_icons`
- Pre-PR baseline: `flutter analyze && flutter test`

## Coding Standards
- Follow Effective Dart and `flutter_lints` from `analysis_options.yaml`.
- Keep code concise, explicit, and readable; avoid clever/obscure constructs.
- Use 2-space indentation and keep lines near 80 chars when practical.
- Naming:
  - `PascalCase`: classes/widgets/enums
  - `camelCase`: methods/fields/variables
  - `snake_case`: files
- Prefer immutability and `const` constructors/literals.
- Separate UI from business logic and data access.
- Avoid `print`; prefer structured logging (`dart:developer` `log`).
- Avoid force null assertions (`!`) unless guaranteed safe.

## Architecture
- Keep concerns separated:
  - Presentation (widgets/pages)
  - Domain/state (controllers/use-cases)
  - Data (models/api/repositories)
  - Core/shared utilities
- Prefer composition over inheritance for widgets and logic.
- Keep functions small and single-purpose.
- Break large `build()` methods into smaller private widgets.

## State, Async, And Navigation
- Prefer built-in Flutter state tools unless user explicitly requests otherwise:
  - `ValueNotifier` for simple local state
  - `ChangeNotifier`/`Listenable` for shared mutable UI state
  - `Future`/`FutureBuilder` for one-shot async
  - `Stream`/`StreamBuilder` for event streams
- Use constructor injection for dependencies.
- Routing default:
  - Prefer `go_router` for app-level declarative routing/deep links.
  - Use `Navigator` for short-lived flows (dialogs/temporary screens).

## Data And Serialization
- Use typed model classes; avoid loose untyped maps in app logic.
- If JSON model generation is introduced, use:
  - `json_serializable` + `json_annotation`
  - `fieldRename: FieldRename.snake` when API expects snake_case
- Run codegen when needed:
  - `dart run build_runner build --delete-conflicting-outputs`

## UI, Theme, And Accessibility
- Use centralized `ThemeData`; prefer Material 3 patterns.
- Support light/dark mode via `theme`, `darkTheme`, and `themeMode`.
- Prefer `ColorScheme.fromSeed` to generate coherent palettes.
- Ensure responsive layouts (`LayoutBuilder`, `MediaQuery`,
  flexible/scroll-safe widgets).
- Keep long lists lazy (`ListView.builder`/`SliverList`).
- Accessibility requirements:
  - Text contrast target: WCAG AA (4.5:1 normal text)
  - Respect dynamic text scaling
  - Add semantic labels where needed

## Testing
- Use `flutter_test` for unit/widget tests.
- Test naming: `*_test.dart`.
- Keep tests deterministic and readable (Arrange-Act-Assert).
- Prefer fakes/stubs over mocks.
- Add/update tests for behavior changes in state/data/UI.

## Documentation
- Use `///` doc comments for public APIs.
- Explain "why" and non-obvious decisions, not trivial "what".
- Keep docs concise and consistent with actual behavior.

## Dependencies And Security
- Prefer Flutter/Dart SDK and built-in solutions first.
- Add third-party packages only when justified by clear need.
- When adding a dependency, state why it is needed and tradeoffs.
- Never hardcode secrets/tokens; use `--dart-define`.
- Keep `API_BASE_URL` environment-specific.

## PR And Commit Expectations
- Conventional Commits (for example `feat(api): ...`, `fix(map): ...`).
- Keep commits focused to one logical change.
- In PR notes include:
  - concise summary
  - test/analyze commands run
  - backend flags/assumptions (`--dart-define` values)
  - screenshots/video for UI changes
