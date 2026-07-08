# Achievements Implementation Chunks

This file splits the achievements feature into manageable chunks for another agent to implement. Each chunk should be small enough to review independently and should leave runnable checks behind.

## Rules For Agents

- Work in the `Suggested PR Order` at the bottom of this file unless the user explicitly reprioritizes.
- Do not start Supabase, UI, or reminder work before the pure catalog/evaluator chunks exist.
- Keep each chunk independently testable.
- Prefer existing app patterns over new architecture.
- Update these docs only when implementation discovers a real mismatch.

## Chunk 1: Catalog And Core Models

Goal:

- Add the built-in achievement catalog and pure Dart model types.

Scope:

- Add catalog IDs, categories, thresholds, string keys, and art keys.
- Add models for catalog definitions, unlock refs, unlock grants, progress snapshots, and saved places.
- Do not wire persistence, UI, or evaluation yet.

Likely files:

- `lib/src/achievements/catalog.dart`
- `lib/src/achievements/models.dart`
- `test/achievement_catalog_test.dart`

Checks:

- Catalog has no duplicate `familyId + level` pairs.
- Category order matches `spec.md`.
- Thresholds match `spec.md`.
- Every catalog entry has a title key, description key, and art key.
- Country catalog contains exactly the 27 curated country badges.

Done when:

- Tests can prove the catalog is internally consistent.

## Chunk 2: Pure Evaluator For Simple Ladders

Goal:

- Evaluate totals and drink-type ladders from in-memory entries.

Scope:

- Total drinks.
- Beer, wine, sparkling wines, longdrinks, spirits, shots, cocktails, apple wines, non-alcoholic.
- Use entry-stored drink category and alcohol-free flags.
- Return current progress and earned candidate levels.

Likely files:

- `lib/src/achievements/evaluator.dart`
- `lib/src/achievements/progress.dart`
- `test/achievement_evaluator_ladders_test.dart`

Checks:

- Total-drink thresholds unlock correctly.
- Each drink type counts only matching entries.
- Hidden drinks/categories still count if represented in entry data.
- Editing an entry category changes future progress in the evaluator result.

Done when:

- Pure tests cover all simple ladder families without repository or UI dependencies.

## Chunk 3: Streak And Travel Evaluators

Goal:

- Add the harder pure evaluators for streaks and countries.

Scope:

- Streak unlocks from best historical streak.
- Streak live progress uses current active streak.
- Travel counts unique identifiable countries worldwide.
- Curated country badges unlock from the 27 locked country codes.

Likely files:

- `lib/src/achievements/evaluator.dart`
- `lib/src/achievements/streaks.dart`
- `test/achievement_evaluator_streaks_test.dart`
- `test/achievement_evaluator_countries_test.dart`

Checks:

- Broken streak remains earned but current progress drops.
- Deleting an entry can move current streak and best streak correctly.
- Travel starts at 3 countries, not 1.
- Non-curated countries count for travel but do not create country badges.

Done when:

- Streak and country behavior is covered with in-memory tests.

## Chunk 3b: Place Evaluator

Goal:

- Evaluate home/work ladders from saved places and entry location metadata.

Scope:

- Match entries against active and archived saved places with the fixed `50 m` radius.
- Require precise location metadata for home/work matching.
- Include all currently saved places for future progress.
- Exclude entries near deleted places from future progress.
- Keep earned levels permanent regardless of place changes.

Likely files:

- `lib/src/achievements/evaluator.dart`
- `lib/src/achievements/place_matching.dart`
- `test/achievement_evaluator_places_test.dart`

Checks:

- Entry within 50 m of active Home counts; 51 m does not.
- Approximate-location entries never match home/work.
- Replacing Home re-evaluates future progress against the new coordinates.
- Deleting a place removes its future contribution without revoking earned levels.

Done when:

- Home/work ladder behavior is covered with pure in-memory tests.

## Chunk 4: Occasion Evaluators

Goal:

- Add date-window and annual occasion evaluation.

Scope:

- Birthday.
- First Sip Anniversary.
- New Year.
- Christmas.
- Easter.
- Halloween.
- St. Patrick's Day.
- Oktoberfest.
- Carnival.

Likely files:

- `lib/src/achievements/occasion_rules.dart`
- `lib/src/achievements/evaluator.dart`
- `test/achievement_evaluator_occasions_test.dart`

Checks:

- Good Friday through Easter Monday works for multiple years.
- Carnival runs from Fat Thursday through Mardi Gras.
- Oktoberfest uses the hardcoded 2026-2030 date table from `spec.md`.
- Feb 29 falls back to Feb 28 in non-leap years.
- St. Patrick's Day and Oktoberfest require beer.
- Other occasion badges accept any drink.
- BeerWithMe-style imported historical dates evaluate from stored local dates.

Done when:

- Occasion tests pass across at least one leap year and one non-leap year.

## Chunk 5: Local Persistence And Grant Flow

Goal:

- Persist unlocks and run grants in local mode.

Scope:

- Store unlock rows locally.
- Store surfaced state locally.
- Store catalog version seen locally.
- Store achievement-related settings locally.
- Store saved places locally (active and archived home/work).
- Wire evaluator into add/edit/delete flows for local repository/controller.
- Keep local and Supabase state isolated.

Likely files:

- `lib/src/repository/local_app_repository.dart`
- `lib/src/app_controller.dart`
- `test/app_controller_achievements_test.dart`
- `test/local_repository_achievements_test.dart`

Checks:

- Add drink grants new unlocks.
- Re-running evaluation is idempotent.
- Deleting an entry recomputes future progress without revoking earned levels.
- Surfaced unlocks do not appear twice.
- Catalog-version backfill runs once.

Done when:

- Local mode can earn and persist badges without UI work.

## Chunk 6: Entry Metadata

Goal:

- Persist achievement-aware entry metadata for new logs and imports.

Scope:

- Add `achievementLocalDate`.
- Add `achievementUtcOffsetMinutes`.
- Add optional `achievementTimeZone`.
- Add normalized `countryCode`.
- Add location precision metadata.
- Update BeerWithMe import to preserve the source timestamp calendar day.

Likely files:

- `lib/src/models.dart`
- `lib/src/repository/local_app_repository.dart`
- `lib/src/repository/supabase_app_repository.dart`
- BeerWithMe import files
- `test/beer_with_me_import_test.dart`

Checks:

- New manual logs store local achievement date.
- Imported rows preserve the source timestamp's calendar day.
- Legacy rows still deserialize.
- Existing entries without metadata still evaluate with the v1 fallback.

Done when:

- New metadata is present for new data and legacy data still works.

## Chunk 7: Supabase Schema And Repository

Goal:

- Add the Supabase persistence layer.

Scope:

- Add migrations from `db-schema-contract.md`.
- Add Supabase repository methods from `repository-and-deeplink-contract.md`.
- Add RLS and RPCs for friend shared achievements.
- Extend notification device token registration with timezone data.

Likely files:

- `supabase/migrations/*.sql`
- `lib/src/repository/app_repository.dart`
- `lib/src/repository/supabase_app_repository.dart`
- `test/supabase_repository_*` if existing patterns support it

Checks:

- Unlock upsert keeps earliest `qualifiedAt` and `grantedAt`.
- `shareAchievements` gates friend reads.
- `shareStatsWithFriends` does not gate achievements.
- Saved places support one active home and one active work.
- Device token registration updates timezone metadata.

Done when:

- Supabase-backed app can persist and read achievement state.

## Chunk 8: Achievements Tab And Detail Sheet

Goal:

- Add the main user-facing achievements UI.

Scope:

- Add the Achievements tab.
- Add grouped cards.
- Add `All`, `Unlocked`, `Locked` filters.
- Add summary and latest 5 recently unlocked levels.
- Add in-tab detail sheet.
- Keep global FAB visible.

Likely files:

- `lib/src/screens/home_shell.dart`
- `lib/src/screens/achievements_screen.dart`
- `lib/src/app_routes.dart`
- `test/home_shell_test.dart`
- `test/achievements_screen_test.dart`

Checks:

- Main shell has five tabs.
- Filters work.
- Detail opens without hiding the FAB.
- Locked families show setup/progress state.
- Own detail shows full ladder.

Done when:

- A user can browse achievements in local mode.

## Chunk 9: Places Screen

Goal:

- Add setup and management for Home and Work places.

Scope:

- Add `Profile > Settings > Places`.
- Show active Home and Work.
- Show archived places.
- Replace active place with confirmation.
- Delete saved places.
- Deep-link setup actions from achievement details.
- Add the `shareAchievements` and achievement reminders toggles to profile settings.

Likely files:

- `lib/src/screens/places_screen.dart`
- `lib/src/screens/profile_screen.dart`
- `lib/src/app_routes.dart`
- `test/places_screen_test.dart`

Checks:

- Setting a new Home archives the old Home.
- Replacing Home/Work requires confirmation.
- Deleting a saved place affects future progress only.
- Setup-required achievement detail opens the relevant section.
- Both settings toggles persist and default to on.

Done when:

- Home/Work achievements can be set up without manual data hacks.

## Chunk 10: Celebration And Profile Preview

Goal:

- Add reward presentation around already-working unlock state.

Scope:

- Add unlock celebration queue.
- Cap animated cards at 3.
- Add overflow summary.
- Add compact backfill/import summary.
- Add profile preview from in-memory state.
- Add haptic and Android/Web sound hooks.
- Add reduced-motion fallback.

Likely files:

- `lib/src/app_controller.dart`
- `lib/src/screens/profile_screen.dart`
- new celebration widgets/services
- `test/app_controller_achievements_test.dart`
- widget tests for celebration output

Checks:

- One unlock shows one card.
- Four unlocks show three cards plus overflow.
- Backfill uses compact summary.
- Profile preview shows earned count and latest badge.
- Reduced-motion path skips heavy animation.

Done when:

- Unlocks feel visible without changing evaluator behavior.

## Chunk 11: Friend Sharing UI

Goal:

- Show shared achievements on friend profiles.

Scope:

- Add lazy-loaded shared achievements section.
- Respect `shareAchievements`.
- Keep friend stats route as entry point.
- Friend detail shows earned levels only.
- No timestamps or progress in friend view.

Likely files:

- `lib/src/friend_stats_profile.dart`
- friend profile screen files
- `lib/src/repository/app_repository.dart`
- `test/friend_profile_achievements_test.dart`

Checks:

- Achievements show when `shareAchievements = true`.
- Achievements hide when `shareAchievements = false`.
- Stats hidden and achievements shared works.
- Friend view does not show progress, locked levels, or timestamps.

Done when:

- Friend sharing behavior matches the privacy spec.

## Chunk 12: Reminder Backend And Push Deep Links

Goal:

- Add reminder delivery and push open behavior.

Scope:

- Add reminder delivery log.
- Add hourly backend evaluator.
- Add reminder push copy.
- Add deep-link payloads.
- Add Achievements post-auth redirect route.
- Add timezone refresh on app startup/foreground.

Likely files:

- `supabase/functions/achievement-reminders/index.ts`
- `supabase/functions/_shared/notification_l10n.ts`
- `lib/src/deep_link_service.dart`
- `lib/src/app_routes.dart`
- `test/deep_link_service_test.dart`
- `supabase/functions/achievement-reminders/index_test.ts`

Checks:

- Sends once per device/family/eligible date.
- Retries until local 23:00 only if not yet sent.
- Multiple reminders on the same day are separate and staggered.
- Missing timezone falls back to UTC.
- Push route opens Achievements detail after auth if needed.

Done when:

- Reminder pushes can be generated and opened into the correct detail sheet.

## Suggested PR Order

This order is authoritative; chunk numbers are stable names, not the execution order.

1. Chunk 1: Catalog and core models
2. Chunk 2: Pure evaluator for simple ladders
3. Chunk 3: Streak and travel evaluators
4. Chunk 3b: Place evaluator
5. Chunk 4: Occasion evaluators
6. Chunk 6: Entry metadata (before the grant flow so occasion evaluation uses stored local dates)
7. Chunk 5: Local persistence and grant flow
8. Chunk 8: Achievements tab and detail sheet
9. Chunk 9: Places screen and settings toggles
10. Chunk 7: Supabase schema and repository
11. Chunk 10: Celebration and profile preview
12. Chunk 11: Friend sharing
13. Chunk 12: Reminder backend and push deep links

## Deliberately Deferred

- Final production badge artwork
- Alcohol-free beer family
- Public achievement sharing
- OS app-icon badges
- Full analytics/telemetry
