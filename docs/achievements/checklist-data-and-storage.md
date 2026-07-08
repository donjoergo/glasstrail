# Achievements Coding Checklist: Data and Storage

This checklist covers domain models, local persistence, and database schema work.

## Primary Touchpoints

- `lib/src/models.dart`
- `lib/src/repository/local_app_repository.dart`
- `lib/src/repository/supabase_app_repository.dart`
- `lib/src/repository/app_repository.dart`
- `supabase/migrations/*.sql`

## Domain Models

- [ ] Add achievement domain models instead of overloading existing generic structures.
- [ ] Add catalog-facing types for family definitions, levels, categories, and kinds.
- [ ] Add persisted unlock model with `familyId`, `level`, `qualifiedAt`, `grantedAt`, and surfaced state.
- [ ] Add a place model for saved `Home` / `Work` locations and archived history.
- [ ] Add a type for location precision or equivalent exact-vs-approximate matching.
- [ ] Add any needed deep-link payload model for opening a specific achievement detail.

## Entry Model Extensions

- [ ] Extend `DrinkEntry` persistence with `achievementLocalDate`.
- [ ] Extend `DrinkEntry` persistence with `achievementUtcOffsetMinutes`.
- [ ] Add optional `achievementTimeZone` if it simplifies future evaluation or debugging.
- [ ] Persist normalized `countryCode` when derivable.
- [ ] Persist location precision metadata for exact place matching vs best-effort country matching.
- [ ] Confirm entry-stored drink category and alcohol-free semantics remain the source of truth for historical evaluation.

## User Settings Extensions

- [ ] Add `shareAchievements` to settings.
- [ ] Add `achievementRemindersEnabled` or equivalent synced account-level toggle.
- [ ] Keep both new toggles separate from `shareStatsWithFriends`.
- [ ] Make sure defaults align with the spec:
  - `shareAchievements = true`
  - `achievementRemindersEnabled = true`

## Local Persistence

- [ ] Add local serialization for unlock records.
- [ ] Add local serialization for saved places and archived places.
- [ ] Add local serialization for new settings flags.
- [ ] Keep local-mode achievement state fully isolated from Supabase-mode state.
- [ ] Do not add local-to-cloud migration state or one-time merge scaffolding.

## Supabase Schema

- [ ] Add a table for achievement unlock records.
- [ ] Add uniqueness on `user_id + family_id + level`.
- [ ] Add indexes for user-level fetches ordered by `granted_at`.
- [ ] Add a table for saved places with `home` / `work` typing and archive state.
- [ ] Add a reminder-delivery table with uniqueness on `device_token_id + family_id + occasion_year` per `db-schema-contract.md`.
- [ ] Extend notification device token storage with last-known timezone metadata if not already sufficient.
- [ ] Extend token storage with the timestamps needed for the `last_seen_at within 30 days` rule if not already present.

## Recommended Supabase Columns

### Achievement unlocks

- [ ] `id`
- [ ] `user_id`
- [ ] `family_id`
- [ ] `level`
- [ ] `qualified_at`
- [ ] `granted_at`
- [ ] `surfaced_at` or equivalent surfaced-once marker
- [ ] `source` such as `realtime_log`, `import`, `backfill`, `history_edit`, `settings_change`

### Saved places

- [ ] `id`
- [ ] `user_id`
- [ ] `place_type`
- [ ] `latitude`
- [ ] `longitude`
- [ ] `is_active`
- [ ] `archived_at`
- [ ] `created_at`
- [ ] `updated_at`

### Reminder deliveries

- [ ] `id`
- [ ] `user_id`
- [ ] `device_token_id`
- [ ] `family_id`
- [ ] `occasion_year`
- [ ] `eligible_local_date`
- [ ] `time_zone_used`
- [ ] `sent_at`

## RLS and Access

- [ ] Add owner-only policies for unlock reads and writes.
- [ ] Add owner-only policies for saved places.
- [ ] Add owner-only policies for reminder-delivery rows.
- [ ] Add friend-read access only where shared achievements must be exposed.
- [ ] Keep friend sharing read paths narrow and explicit.

## Data Constraints

- [ ] Enforce append-only semantics for the catalog in app code, not by mutating stored unlocks.
- [ ] Prevent duplicate unlock rows for the same user and level.
- [ ] Make sure deleting a saved place does not delete unlock rows.
- [ ] Make sure place deletion only affects future evaluation inputs.

## Resolved Implementation Decisions

- Achievement models live in `lib/src/achievements/models.dart`; entry-level metadata extensions stay on the existing entry model in `lib/src/models.dart`.
- Local persistence uses separate storage keys per concern (unlocks, saved places, achievement settings) instead of growing existing repository blobs.
- Reminder-delivery rows store both `occasion_year` (dedupe key) and `eligible_local_date` (debugging).

## Acceptance

- [ ] A fresh install can store and read achievement settings, saved places, unlocks, and entry-level achievement metadata locally.
- [ ] Supabase schema supports owner reads, deduplicated unlock writes, saved places, and reminder-delivery logging.
- [ ] No storage shape requires copying localized titles or descriptions into unlock rows.
