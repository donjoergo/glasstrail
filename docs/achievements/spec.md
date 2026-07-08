# Achievements Spec

This document is the implementation contract for the achievements feature.

## Goals

- Add a dedicated `Achievements` feature to the authenticated app experience.
- Keep achievement unlocks permanent once granted.
- Recompute live progress from current data without revoking earned levels.
- Support both local mode and Supabase mode without cross-mode migration.
- Keep the catalog built-in, versioned, and append-only.

## Catalog Model

- The achievement catalog is built into app code.
- The catalog has a monotonic `catalogVersion`.
- Achievement definitions are append-only after release.
- Existing shipped family IDs, thresholds, and unlock rules are immutable.
- Titles, descriptions, and artwork resolve from localization and asset keys at display time.

Each definition needs:

- `familyId`
- `category`
- `kind`
- `level`
- `threshold` when applicable
- `titleKey`
- `descriptionKey`
- `artKey`

`kind` values:

- `ladder`
- `one_off_occasion`
- `one_off_country`

## Category Order

Internal family grouping and visible section order is fixed:

1. `totals`
2. `streaks`
3. `drink_types`
4. `occasions`
5. `places`
6. `travel`
7. `countries`

Visible top-level filters in v1 stay simple:

- `all`
- `unlocked`
- `locked`

## Stable Family IDs

### Ladder Families

- `total_drinks`
- `streaks`
- `type_beer`
- `type_wine`
- `type_sparkling_wines`
- `type_longdrinks`
- `type_spirits`
- `type_shots`
- `type_cocktails`
- `type_apple_wines`
- `type_non_alcoholic`
- `place_home`
- `place_work`
- `travel_countries`

### One-Off Occasion Families

- `occasion_birthday`
- `occasion_first_sip_anniversary`
- `occasion_new_year`
- `occasion_christmas`
- `occasion_easter`
- `occasion_halloween`
- `occasion_st_patricks_day`
- `occasion_oktoberfest`
- `occasion_carnival`

### One-Off Country Families

- `country_de`
- `country_nl`
- `country_be`
- `country_lu`
- `country_fr`
- `country_es`
- `country_pt`
- `country_it`
- `country_at`
- `country_ch`
- `country_pl`
- `country_cz`
- `country_ie`
- `country_gb`
- `country_dk`
- `country_se`
- `country_no`
- `country_fi`
- `country_gr`
- `country_hr`
- `country_hu`
- `country_ro`
- `country_tr`
- `country_us`
- `country_jp`
- `country_si`
- `country_mc`

For ladder families, the persisted `level` value equals the `threshold` value, so the effective level identity is `familyId + threshold`.
For one-off families, the effective level identity is `familyId + level=1`.

## Thresholds

### Total Drinks

- `1`
- `10`
- `25`
- `50`
- `100`
- `200`
- `300`
- `400`
- `500`
- `1000`

### Streaks

- `3`
- `7`
- `14`
- `30`
- `60`
- `90`
- `180`
- `365`

### Drink Type Families

The following families all use the same ladder:

- `type_beer`
- `type_wine`
- `type_sparkling_wines`
- `type_longdrinks`
- `type_spirits`
- `type_shots`
- `type_cocktails`
- `type_apple_wines`
- `type_non_alcoholic`

Thresholds:

- `10`
- `25`
- `50`
- `100`
- `200`
- `300`
- `400`
- `500`
- `1000`

### Home / Work

- `1`
- `10`
- `25`
- `50`
- `100`

### Travel Countries

- `3`
- `5`
- `10`
- `15`
- `20`
- `30`
- `50`

## Progress and Permanence

- Unlock records are explicit persisted records, not derived-only state.
- Earned levels remain unlocked permanently once granted.
- Current progress is always computed live from current history and settings.
- If current data drops below a previously earned threshold, the earned level stays earned.
- A family card should still show current progress toward the next unearned level even if that is numerically below an already earned tier.

### Streak Rule

- Unlock basis: `best historical streak`
- Live progress basis: `current active streak`

## Entry Data Required For Achievement Evaluation

New or updated entry-level achievement context should persist:

- `achievementLocalDate`
- `achievementUtcOffsetMinutes`
- optional `achievementTimeZone`
- normalized `countryCode` when derivable
- `locationPrecision` or equivalent precise-vs-approximate flag

Achievement evaluation for historical entries must use entry-stored drink semantics:

- stored category at log time
- stored alcohol-free flag at log time

Catalog changes must not rewrite historical category semantics.

BeerWithMe imports must preserve the calendar day implied by the source timestamp, not the importing device timezone.

Legacy pre-feature entries remain best-effort for date-sensitive backfill.

### Legacy Evaluation Fallback

For entries persisted before the achievement metadata existed:

- derive the achievement local date from the stored timestamp interpreted in the device's current timezone at evaluation time
- a missing `countryCode` means the entry does not count for country badges or travel counting
- missing precise-location metadata means the entry does not count for home/work families
- day shifts near midnight for old cross-timezone logs are accepted as best-effort

## Occasion Rules

- `occasion_birthday`: any drink on the user birthday
- `occasion_first_sip_anniversary`: any drink on the anniversary of the earliest-known drink
- `occasion_new_year`: any drink on Dec 31 or Jan 1
- `occasion_christmas`: any drink from Dec 24 through Dec 26
- `occasion_easter`: any drink from Good Friday through Easter Monday
- `occasion_halloween`: any drink on Oct 31
- `occasion_st_patricks_day`: beer on Mar 17
- `occasion_oktoberfest`: beer during the official Oktoberfest date range
- `occasion_carnival`: any drink from Fat Thursday through Mardi Gras

Date specifics already locked:

- `Feb 29` falls back to `Feb 28` in non-leap years for birthday and anniversary logic.
- `Easter` and `Carnival` are algorithmic calendar windows computed with the Western (Gregorian) computus.
- `Oktoberfest` follows the official Munich date range each year, resolved from a hardcoded table shared by app catalog and reminder backend:
  - `2026`: `Sep 19 - Oct 4`
  - `2027`: `Sep 18 - Oct 3`
  - `2028`: `Sep 16 - Oct 3`
  - `2029`: `Sep 22 - Oct 7`
  - `2030`: `Sep 21 - Oct 6`

## Place and Country Rules

### Home / Work

- `place_home` and `place_work` are separate ladder families.
- Users have one active `Home` and one active `Work` place at a time.
- Old saved places are archived history, not concurrent active places.
- Radius is fixed at `50 m`.
- Users do not get a radius editor.
- If saved coordinates change later, past entries are re-evaluated for future progress.
- Earned levels remain permanent after place changes.
- Replacing an active place requires confirmation and archives the previous one.
- Deleting a saved place removes its future contribution but does not revoke earned levels.
- Home/work achievement matching requires precise location.

### Travel and Countries

- `travel_countries` counts unique identifiable countries worldwide, not just the curated 27.
- Country-specific badges unlock from any qualifying drink in that country.
- Country badges use the curated 27-country catalog.
- Approximate location can count for country and travel if the country is unambiguous.

### Visibility and Catalog Preferences

- Hidden global drinks still count.
- Hidden categories still count.
- Custom drinks count fully based on the category stored on each entry.

## Unlock Evaluation Triggers

Evaluate achievements after:

- a successful drink log
- an achievement-relevant entry edit
- an entry deletion
- BeerWithMe import completion
- startup when `catalogVersion` increased
- relevant profile/settings changes

Do not evaluate on every screen open.

Relevant settings changes include:

- birthday changes
- home/work changes
- place deletion
- earliest-known first drink anchor changes caused by import or deletion

## Unlock Record Behavior

Unlock records are deduplicated by:

- `user`
- `familyId`
- `level`

On multi-device unlock conflicts:

- keep earliest `qualifiedAt`
- keep earliest `grantedAt`

Store enough state to ensure each newly granted level is surfaced only once in unlock summaries.

## Sharing and Privacy

- `shareAchievements` is separate from `shareStatsWithFriends`.
- `shareAchievements` defaults to `on`.
- No disclosure flow is shown on rollout.
- Friends can see shared achievements only if they are friends.
- No public profile or share-link surface is added.

Friend view rules:

- show unlocked earned badges only
- show no locked future levels
- show no current progress
- show no unlock timestamps
- show full localized title and description

Turning `shareAchievements` off:

- removes achievement visibility on the next fetch

Turning it back on:

- restores the full currently unlocked set on the next fetch

## Reminder Model

- Reminders are supported only for eligible Supabase-backed Android devices in v1.
- The toggle is account-level and defaults to `on`.
- No dedicated disclosure is shown.
- Reminder sends use a dedicated reminder-delivery path, not the `notifications` table.
- Reminder sends are per device token, not a single canonical user timezone.
- Delivery checks use the current device-reported timezone.
- Timezone changes should be re-synced on app startup and foreground refresh.

### Scheduler Rules

- Evaluator cadence: hourly
- First attempt: `09:00` local time
- Retry / catch-up window: until `23:00` local time
- Multiple same-day reminders are sent as separate push notifications
- Same-day multiple reminders are staggered deterministically: ordered by the fixed category/family catalog order, `15 minutes` apart starting from the first send
- Missing or invalid timezone metadata falls back to `UTC`
- Only active devices seen within `30 days` are eligible

### Reminder Semantics

- Occasion reminders are once per occasion/year: at most one successful push per device per occasion year
- For multi-day windows, an unsent reminder rolls over to the next window day until it is sent once or the window ends
- The occasion year is the calendar year of the window's first day (New Year uses the year of Dec 31)
- One-time lifetime badges continue receiving yearly reminders until earned once
- If a prerequisite becomes valid on the same eligible day before the `23:00` cutoff, the reminder can still fire that day
- Reminder pushes deep-link into the `Achievements` tab and open the relevant detail sheet
- If auth is required, the app must return to the exact achievement detail after sign-in
- If the target badge was already earned elsewhere before open, still open the same detail

Store reminder-delivery state as sent markers only.

## UI Behavior

- Add a dedicated `Achievements` tab to the authenticated main shell.
- Main navigation grows from 4 tabs to 5 tabs.
- The profile screen keeps a compact achievements preview.
- That profile preview is derived from already-loaded in-memory achievement state.
- The Achievements tab remembers filter and scroll state while the app process stays alive.
- On cold restart, it resets to the default root state.

### Achievements Screen

- grouped by fixed category order
- visible top-level filters only: `All`, `Unlocked`, `Locked`
- summary headline uses `total earned levels`
- compact `Recently unlocked` section shows the latest `5` granted levels
- completed families stay in the normal grid
- locked cards still show the actual greyed-out family motif

### Detail View

- own achievement detail opens as an in-tab sheet / overlay, not a full pushed page
- global floating add-drink action remains visible
- no dedicated `Log drink` CTA inside the sheet
- if currently earnable from a reminder flow, show an `Earnable today` pill
- ladder families show numeric progress
- one-off occasion and country badges show condition/status text
- locked annual occasion badges show the next eligible date or date window
- own detail shows full ladder, exact requirements, and unlock history
- own unlock history timestamps are displayed as `date only`

### Setup-Required States

For missing prerequisites such as birthday or saved home/work:

- the family remains visible
- card/detail shows a `setup required` state
- detail includes `Set up now`
- `Home` / `Work` setup deep-links to a dedicated `Places` screen with the relevant section focused

### Friend View

- friend stats route remains the entry point
- if stats are hidden but achievements are shared, show achievements below the stats-empty-state
- lazy-load friend shared achievements when that section opens

## Route Restoration and Push Routing

- Normal app restoration should restore only the Achievements tab root, not a previously open detail sheet.
- Push deep links should open the Achievements tab and then the exact detail sheet.

## Celebration, Haptics, and Sound

### Unlock Presentation

- Real-time drink log unlocks can show the full celebration queue.
- Import/backfill/history-edit unlocks use a compact summary instead.
- Unlocks granted by settings-change re-evaluation (`settings_change` source: birthday set, home/work place set or changed, place deletion, first-drink anchor changes) also use the compact summary, never the full celebration queue.
- Startup unlocks caused by a new catalog version use a lightweight summary.
- A single drink log can animate at most `3` achievement cards before switching to a generic overflow summary.

### Haptics

- buzz once per whole unlock sequence
- no separate in-app vibration toggle
- silent mode may still buzz if the platform allows it
- respect DND
- respect system-wide haptics-disabled settings

### Sound

- play once per whole unlock sequence
- supported on Android and Web only in v1
- Android should use media-volume behavior as implemented by the chosen audio approach
- Web should use normal browser/media rules and fail silently if blocked

### Accessibility

- if reduced motion or accessibility navigation is active, use a mostly static success card instead of the full motion-heavy celebration

## Data Isolation

- Local mode and Supabase mode remain fully isolated.
- No one-time local-to-cloud migration flow is added.
- Achievement state, reminders state, and related settings do not carry over between backends.

## Naming and Localization

- Feature/screen language uses `Achievements`.
- Collectible/count language uses `Badges`.
- English and German strings are transcreated, not literal translations.
- Titles, descriptions, and country labels live in localization keys.
- Unlock records do not snapshot titles or descriptions.

The exact locked strings catalog is maintained in [strings.md](./strings.md).
