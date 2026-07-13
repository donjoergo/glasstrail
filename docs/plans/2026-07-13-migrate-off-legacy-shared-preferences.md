# Migrate off legacy `SharedPreferences.getInstance()`

## Problem

The app hangs forever on the "Loading your drinks and settings." bootstrap
splash on Android. Logcat shows:

```
E/flutter: [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception:
MissingPluginException(No implementation found for method getAll on channel
plugins.flutter.io/shared_preferences)
```

Reproduces on every cold start, both via `flutter run` and launching the
already-installed APK normally (not a debug-attach timing race). Network
connectivity to the production Supabase host is fine, so it's not a backend
reachability issue.

## Root cause

`shared_preferences_android` `2.4.26` ("Updates internal implementation to
use Kotlin Pigeon", per its `CHANGELOG.md`) dropped native support for the
deprecated legacy `MethodChannel` (`plugins.flutter.io/shared_preferences`,
implemented in `shared_preferences_platform_interface`'s
`MethodChannelSharedPreferencesStore`). This app's code still calls the
deprecated **legacy** API, `SharedPreferences.getInstance()`, everywhere it
touches shared preferences:

- `lib/src/locale_memory.dart`
- `lib/src/repository/local_app_repository.dart`
- `lib/src/route_memory.dart`
- `lib/src/screens/feed_screen.dart` (two call sites)

`shared_preferences: ^2.5.3` in `pubspec.yaml` lets `pub get` resolve the
newest `shared_preferences_android` transitively, so any fresh
`pub get`/`pub upgrade` can pull in `2.4.26` (or later) and reintroduce this
hang with no local code change at all.

## Current state: temporary workaround

`pubspec.yaml` currently pins the transitive dependency back to the last
version before the breaking internal rewrite:

```yaml
dependency_overrides:
  shared_preferences_android: 2.4.25
```

This unblocks local development and testing but is not a real fix:

- Freezes `shared_preferences_android` on `2.4.25` indefinitely — future
  fixes/security patches on that package are missed unless someone
  remembers to revisit this override.
- `dependency_overrides` doesn't survive a `flutter pub upgrade
  --major-versions` cleanly; whoever runs that next will likely hit this
  exact hang again, without the context captured here.
- The legacy `SharedPreferences` API is explicitly deprecated upstream
  (`shared_preferences` `2.5.x`'s `CHANGELOG.md` even added "a migration
  tool to move from legacy `SharedPreferences` to `SharedPreferencesAsync`"),
  so leaving this as-is is accumulating tech debt against a codepath the
  package maintainers are actively moving away from.

## Real fix

Migrate the five call sites above from `SharedPreferences.getInstance()` to
`SharedPreferencesAsync` (the current recommended API), then drop the
`dependency_overrides` pin so `shared_preferences_android` tracks its normal
version constraint again.

Notes for whoever picks this up:
- `SharedPreferencesAsync` has no in-memory cache the way the legacy
  singleton effectively did — every read is its own async platform call.
  Check each of the five call sites for repeated synchronous-feeling reads
  that assumed a cached instance, and adjust accordingly (e.g. read once
  and hold the value locally for the scope that needs it, rather than
  re-awaiting on every access).
- `shared_preferences` ships a migration tool/guide (see its package docs)
  intended for exactly this transition — use it as the reference rather
  than hand-rolling the mapping from `getInstance()` methods to
  `SharedPreferencesAsync` equivalents.
- Cover the migrated call sites with the existing test patterns in
  `test/support/test_harness.dart` (or add to them if the harness only
  fakes the legacy API today) so a future `shared_preferences_android`
  upgrade can't silently reintroduce this class of hang.
- After migrating, verify on a real Android device (this bug did not
  reproduce in `flutter test` — the fake/mocked platform channel setup in
  tests doesn't hit the wire, so the widget tests all passed while this
  was broken on-device) before removing the `dependency_overrides` pin.
