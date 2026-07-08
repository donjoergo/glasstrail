# Achievements Coding Checklist: Reminders Backend

This checklist covers backend scheduling and push delivery for achievement reminders.

## Primary Touchpoints

- `supabase/functions/`
- existing push functions such as `send-notification-push`
- any Supabase scheduler or cron configuration already used in the project
- reminder-related localization generation once push copy is added

## Delivery Architecture

- [ ] Create a dedicated reminder evaluator path separate from the in-app notifications table.
- [ ] Do not create hidden `notifications` rows for reminders.
- [ ] Add a durable reminder-delivery log using the dedicated schema.
- [ ] Keep reminder send markers separate from social/friend notifications.

## Evaluator Cadence

- [ ] Add an hourly evaluator job.
- [ ] Ensure each run can find devices whose local time crossed the eligible reminder window since the last run.
- [ ] Keep evaluation idempotent across retries and overlapping runs.

## Eligibility Rules

- [ ] Only consider users with `achievementRemindersEnabled = true`.
- [ ] Only consider active Android device tokens in v1.
- [ ] Only consider devices seen within `30 days`.
- [ ] Use each device’s current timezone metadata.
- [ ] Fall back to `UTC` if timezone metadata is missing or invalid.
- [ ] Apply a first-attempt target of `09:00` local.
- [ ] Allow retry/catch-up until `23:00` local.

## Occasion and Anniversary Scheduling

- [ ] Birthday reminders
- [ ] First sip anniversary reminders
- [ ] New Year reminders
- [ ] Christmas reminders
- [ ] Easter reminders
- [ ] Halloween reminders
- [ ] St. Patrick’s Day reminders
- [ ] Oktoberfest reminders
- [ ] Carnival reminders

- [ ] Only one successful send per device per occasion year, deduplicated by `occasion_year`.
- [ ] For multi-day windows, roll an unsent reminder over to the next window day until sent once or the window ends.
- [ ] Continue yearly reminders until the one-time badge is earned.
- [ ] If the prerequisite becomes valid on the same eligible day before `23:00`, allow same-day send.

## Multiple Reminder Handling

- [ ] If multiple occasion reminders are eligible on the same day, send multiple push notifications.
- [ ] Stagger them by deterministic minute offsets.
- [ ] Keep each reminder’s sent marker separate.

## Failure Handling

- [ ] Retry later the same day if a send fails.
- [ ] Only mark a reminder as sent after a successful delivery attempt.
- [ ] Stop retrying after the local `23:00` cutoff.

## Push Payload Contract

- [ ] Include enough payload to deep-link to the Achievements tab.
- [ ] Include enough payload to open the exact achievement detail sheet.
- [ ] Make the payload robust if the user already earned the badge elsewhere before opening it.
- [ ] Preserve the target through auth redirect if the session is missing or expired.

## Copy and Localization

- [ ] Add reminder push copy for all reminder-based achievements.
- [ ] Keep copy action-oriented but consistent with the chosen detail-first flow.
- [ ] Regenerate l10n output after ARB changes.
- [ ] Run `dart run tool/generate_notification_push_l10n.dart` after ARB changes.

## Backend Data Dependencies

The hourly evaluator reads:

- [ ] Birthday: from the existing user profile settings.
- [ ] Earliest-known drink date (anniversary date and `{years}` placeholder): computed from `drink_entries`, including imports; must match the app-side earliest-drink logic.
- [ ] Earned state per family: from `achievement_unlocks` (skip already earned one-time badges).
- [ ] Reminder toggle: `user_settings.achievement_reminders_enabled`.
- [ ] Device timezone and `last_seen_at`: from `notification_device_tokens`.
- [ ] Oktoberfest dates: the hardcoded 2026-2030 table from `spec.md`, identical to the app catalog.
- [ ] Beer prerequisite awareness for St. Patrick's Day and Oktoberfest same-day validity.

## Operational Logging

- [ ] Log evaluator runs enough to debug skipped sends and duplicates.
- [ ] Log device eligibility reasons such as stale token, disabled reminders, or missing date eligibility.
- [ ] Do not add broad analytics scope beyond operational logging.

## Acceptance

- [ ] An hourly evaluator can send the right reminder to the right device once per occasion/year.
- [ ] Retries do not create duplicate sends after a successful delivery.
- [ ] Deep links always resolve to the intended achievement detail, including post-auth.
