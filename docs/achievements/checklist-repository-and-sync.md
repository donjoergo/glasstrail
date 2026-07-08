# Achievements Coding Checklist: Repository and Sync

This checklist covers repository contracts and local/Supabase behavior.

## Primary Touchpoints

- `lib/src/repository/app_repository.dart`
- `lib/src/repository/local_app_repository.dart`
- `lib/src/repository/supabase_app_repository.dart`
- `lib/src/repository/repository_factory.dart`
- any friend-profile or notification repository helpers already in use

## Repository Surface

- [ ] Add repository methods to load the built achievement state for the signed-in user.
- [ ] Add repository methods to persist unlock grants idempotently.
- [ ] Add repository methods to mark unlocks as surfaced.
- [ ] Add repository methods to load recent unlocks for the Achievements screen and profile preview.
- [ ] Add repository methods for saved `Home` / `Work` place management.
- [ ] Add repository methods for achievement-related settings reads and writes.
- [ ] Add repository methods to load friend shared achievements lazily.
- [ ] Add repository methods needed for reminder device metadata updates.

## Local Repository

- [ ] Implement the full achievements feature for `LocalAppRepository`, not a partial stub.
- [ ] Keep local achievements isolated from future Supabase sign-in state.
- [ ] Persist saved places locally.
- [ ] Persist unlock history locally.
- [ ] Persist surfaced state locally.
- [ ] Persist the settings toggles locally.

## Supabase Repository

- [ ] Implement unlock write semantics with upsert or conflict handling based on `user + family + level`.
- [ ] Keep earliest `qualifiedAt` and earliest `grantedAt` on conflict.
- [ ] Load shared achievements only when the UI requests them.
- [ ] Respect `shareAchievements` independently from `shareStatsWithFriends`.
- [ ] When `shareAchievements` is off, friend reads must return no shared achievements.
- [ ] When `shareAchievements` is on again, friend reads should return the current full earned set.

## Friend View Data Contract

- [ ] Return unlocked earned levels only.
- [ ] Do not expose current progress.
- [ ] Do not expose locked future levels.
- [ ] Do not expose unlock timestamps.
- [ ] Return enough data to show titles, descriptions, country labels, and earned-level detail.

## Places Management Contract

- [ ] Support loading the active `Home` and archived home history.
- [ ] Support loading the active `Work` and archived work history.
- [ ] Support replacing the active place while archiving the old one.
- [ ] Support deleting an archived place.
- [ ] Support deleting an active place if the product flow allows it.
- [ ] Do not expose user-editable radius methods.

## Notification Device Metadata

- [ ] Make sure device registration persists the current timezone data needed by the reminder evaluator.
- [ ] Refresh device timezone metadata on startup and foreground resume.
- [ ] Keep reminders enabled as an account-level setting while delivery remains per device token.

## Isolation Rules

- [ ] Do not build a local-to-cloud migration bridge.
- [ ] Do not merge local unlocks into Supabase state automatically.
- [ ] Do not merge local settings into Supabase state automatically.
- [ ] Do not let Supabase-side achievement state leak into local mode.

## Error and Retry Behavior

- [ ] Treat unlock writes as idempotent operations.
- [ ] Make history edits and deletions safe to replay.
- [ ] Make reminder-device metadata updates safe to repeat.
- [ ] Keep partial failures from creating duplicate unlock rows or duplicate surfaced summaries.

## Acceptance

- [ ] Both repositories can load and persist achievement state without diverging behavior.
- [ ] Supabase friend views respect sharing rules exactly.
- [ ] Local and Supabase modes remain separate products from an achievements perspective.
