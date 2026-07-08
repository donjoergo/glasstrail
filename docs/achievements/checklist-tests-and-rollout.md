# Achievements Coding Checklist: Tests and Rollout

This checklist covers unit, widget, integration, backend, and rollout verification.

## Unit Tests

- [ ] Catalog tests for stable IDs and thresholds.
- [ ] Evaluator tests for total drinks.
- [ ] Evaluator tests for each drink type family.
- [ ] Evaluator tests for best historical streak vs current streak progress.
- [ ] Evaluator tests for home/work with archived and deleted places.
- [ ] Evaluator tests for travel country counting.
- [ ] Evaluator tests for all one-off occasion windows.
- [ ] Evaluator tests for `Feb 29 -> Feb 28` fallback.
- [ ] Evaluator tests for earliest-known drink anchor changes after import and deletion.
- [ ] Unlock merge tests keeping earliest `qualifiedAt` and `grantedAt`.
- [ ] Surfaced-once tests preventing repeated summaries.

## Repository Tests

- [ ] Local repository tests for unlock persistence.
- [ ] Local repository tests for saved places.
- [ ] Local repository tests for new settings flags.
- [ ] Supabase repository tests for idempotent unlock upserts.
- [ ] Supabase repository tests for friend shared-achievement visibility.
- [ ] Supabase repository tests for `shareAchievements` independent from `shareStatsWithFriends`.

## Widget Tests

- [ ] Main shell test for 5-tab navigation.
- [ ] Achievements screen test for grouped cards and filter toggles.
- [ ] Detail sheet test for in-tab overlay behavior.
- [ ] Detail sheet test for `Earnable today` pill visibility.
- [ ] Setup-required test for birthday/home/work states.
- [ ] Profile preview test.
- [ ] Friend shared achievements section test.
- [ ] Places screen test for replace confirmation and delete behavior.

## Integration Tests

- [ ] Real-time log unlocking one badge.
- [ ] Real-time log unlocking multiple badges with 3-card cap.
- [ ] Import/backfill summary flow.
- [ ] App startup after catalog version bump with lightweight summary.
- [ ] Deep-link from reminder push into Achievements detail.
- [ ] Post-auth return to achievement detail from push target.
- [ ] Home/work change affecting future progress without revoking earned levels.

## Backend / Function Tests

- [ ] Reminder evaluator tests for 09:00 first-attempt logic.
- [ ] Reminder evaluator tests for same-day retry until 23:00.
- [ ] Reminder evaluator tests for multiple same-day reminders with stagger.
- [ ] Reminder evaluator tests for stale-token exclusion.
- [ ] Reminder evaluator tests for timezone fallback to UTC.
- [ ] Reminder evaluator tests for no duplicate send markers after retry.

## Localization Verification

- [ ] Verify all strings from `docs/achievements/strings.md` are represented in ARB files.
- [ ] Run `flutter gen-l10n` after ARB changes.
- [ ] Run `dart run tool/generate_notification_push_l10n.dart` after ARB changes.
- [ ] Verify friend view, profile preview, and push strings all resolve correctly in `en` and `de`.

## Rollout and Backfill Checks

- [ ] Verify catalog-version backfill runs once per version.
- [ ] Verify already surfaced retroactive unlocks do not reappear on restart.
- [ ] Verify old local-only users do not accidentally inherit cloud achievement state.
- [ ] Verify deleting entries re-anchors reminders and progress correctly.
- [ ] Verify birthday removal stops future reminders immediately.

## Manual QA Sweep

- [ ] Normal logging flow
- [ ] History edit flow
- [ ] Entry deletion flow
- [ ] Import flow
- [ ] Home/work setup flow
- [ ] Friend shared-achievements view
- [ ] Toggle privacy on/off
- [ ] Toggle reminders on/off
- [ ] Reminder push open path
- [ ] Reduced-motion behavior
- [ ] Android sound/haptic behavior
- [ ] Web sound graceful fallback

## Release Readiness

- [ ] Confirm changelog needs a user-visible entry only when implementation actually lands.
- [ ] Confirm any Supabase migration review includes RLS impact.
- [ ] Confirm placeholder art coverage for all families and level variants before shipping the UI.
- [ ] Confirm all docs remain aligned with any implementation adjustments before merge.
