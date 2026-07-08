# Achievements Coding Checklist: UI and Navigation

This checklist covers screens, routes, tab integration, detail sheets, settings, and celebration UX.

## Primary Touchpoints

- `lib/src/app_routes.dart`
- `lib/src/screens/home_shell.dart`
- `lib/src/screens/profile_screen.dart`
- `lib/src/screens/friend_*`
- `lib/src/app_controller.dart`
- new achievements screen and widget files

## Main Navigation

- [ ] Add the `Achievements` tab to the authenticated shell.
- [ ] Increase the main tab count from 4 to 5.
- [ ] Keep the existing shared add-drink FAB visible on the Achievements tab.
- [ ] Preserve current shell behavior for the existing tabs.

## Achievements Screen

- [ ] Build the grouped family screen with the fixed category order.
- [ ] Add visible filters: `All`, `Unlocked`, `Locked`.
- [ ] Default sort by category grouping, not dynamic relevance.
- [ ] Show total earned levels in the summary area.
- [ ] Show a compact `Recently unlocked` section with the latest 5 earned levels.
- [ ] Keep completed families mixed into the normal grid.
- [ ] Show greyed-out family motifs for locked cards.

## Session Memory

- [ ] Add achievements-specific lightweight state memory for filter state.
- [ ] Add achievements-specific lightweight state memory for scroll position.
- [ ] Restore the Achievements tab root state while the app stays alive.
- [ ] Do not restore an open detail sheet across cold restart.

## Detail Sheet

- [ ] Open detail as an in-tab sheet/overlay, not a full pushed page.
- [ ] Allow normal sheet dismissal gestures and explicit close affordance.
- [ ] Show full ladder for the owner view.
- [ ] Show unlock history with date-only timestamps.
- [ ] Show exact rule text and requirement state.
- [ ] Show `Earnable today` pill when relevant.
- [ ] Do not add a dedicated `Log drink` CTA inside the detail.
- [ ] Keep the global FAB visible instead.

## Setup-Required UX

- [ ] Show explicit setup-required states for missing birthday/home/work prerequisites.
- [ ] Add `Set up now` actions in the detail sheet.
- [ ] Deep-link birthday setup to the relevant profile edit flow.
- [ ] Deep-link home/work setup to the dedicated `Places` screen with the right section focused.

## Places Screen

- [ ] Add a dedicated `Places` screen under `Profile > Settings`.
- [ ] Show active `Home`.
- [ ] Show active `Work`.
- [ ] Show archived saved places.
- [ ] Allow deleting older saved places.
- [ ] Require confirmation before replacing the active place.

## Profile and Friend Surfaces

- [ ] Add a compact achievements preview to the user’s profile screen.
- [ ] Derive the preview from already loaded in-memory achievement state.
- [ ] Keep the existing friend stats route as the entry point.
- [ ] Add an achievements section below the “stats not shared” empty state when achievements are shared.
- [ ] Lazy-load friend shared achievements when the section is opened.
- [ ] Show friend detail sheets with earned levels only.

## Deep Links and Auth Redirect

- [ ] Add a first-class achievements deep-link target.
- [ ] Handle cold-start push opens into the Achievements tab.
- [ ] Open the relevant detail sheet automatically from the push.
- [ ] Preserve the destination through auth redirect when signed out.

## Celebration UI

- [ ] Add the real-time unlock celebration queue.
- [ ] Cap animated cards at 3.
- [ ] Add a generic overflow summary for `+N more unlocked`.
- [ ] Add a lightweight startup summary for catalog-version backfill.
- [ ] Add compact import/history-edit summaries instead of full celebrations.

## Haptics, Sound, and Accessibility

- [ ] Add one haptic pulse per whole unlock sequence.
- [ ] Add one unlock sound per whole unlock sequence.
- [ ] Scope sound to Android and Web only.
- [ ] Respect DND and system haptics-disabled behavior.
- [ ] Add reduced-motion fallback to a mostly static success card.

## Strings and Localization

- [ ] Add Achievements UI strings to ARB files.
- [ ] Add all achievement titles, descriptions, labels, and reminder copy to ARB files.
- [ ] Regenerate localization code after ARB changes.
- [ ] Regenerate push l10n helper after ARB changes.

## Acceptance

- [ ] A user can browse Achievements, open details, manage setup prerequisites, and handle push deep links without losing the shared FAB flow.
- [ ] Friend views respect the sharing rules while remaining navigationally simple.
- [ ] Celebration UX works for normal logs, imports, backfill, and reduced-motion users.
