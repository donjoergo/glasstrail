# Achievements Coding Checklist: Evaluator Engine

This checklist covers catalog definition, rule evaluation, backfill, and unlock grant flow.

## Suggested New Module Area

Recommended new folder:

- `lib/src/achievements/`

Possible files:

- `catalog.dart`
- `catalog_models.dart`
- `evaluator.dart`
- `occasion_rules.dart`
- `streaks.dart`
- `country_matching.dart`
- `progress_snapshot.dart`
- `unlock_service.dart`

## Primary Touchpoints

- `lib/src/app_controller.dart`
- `lib/src/models.dart`
- import and history-edit flows
- any existing streak/statistics helpers that can be reused safely

## Catalog Definition

- [ ] Encode the catalog version in app code.
- [ ] Encode every family ID from the spec.
- [ ] Encode every threshold from the spec.
- [ ] Encode occasion families and country families as one-off achievements.
- [ ] Encode category ordering and family grouping.
- [ ] Encode string keys and artwork keys, not copied display strings.

## Evaluation Inputs

- [ ] Evaluate from current repository history plus current saved settings.
- [ ] Use entry-stored category and alcohol-free semantics.
- [ ] Use `achievementLocalDate` for date-sensitive matching.
- [ ] Use normalized `countryCode` when available.
- [ ] Use saved places plus exact location matching for home/work.

## Ladder Evaluators

- [ ] Total drinks evaluator
- [ ] Streak evaluator
- [ ] Beer evaluator
- [ ] Wine evaluator
- [ ] Sparkling wines evaluator
- [ ] Longdrinks evaluator
- [ ] Spirits evaluator
- [ ] Shots evaluator
- [ ] Cocktails evaluator
- [ ] Apple wines evaluator
- [ ] Non-alcoholic evaluator
- [ ] Home evaluator
- [ ] Work evaluator
- [ ] Travel countries evaluator

## One-Off Evaluators

- [ ] Birthday evaluator
- [ ] First sip anniversary evaluator
- [ ] New Year evaluator
- [ ] Christmas evaluator
- [ ] Easter evaluator
- [ ] Halloween evaluator
- [ ] St. Patrick’s Day evaluator
- [ ] Oktoberfest evaluator
- [ ] Carnival evaluator
- [ ] All 27 country evaluators

## Streak Rules

- [ ] Compute `best historical streak` for unlock eligibility.
- [ ] Compute `current active streak` for live progress.
- [ ] Make sure deleting entries recalculates both correctly.

## Place Rules

- [ ] Match home/work using fixed `50 m`.
- [ ] Include all currently saved historical places for future progress.
- [ ] Stop counting entries near a deleted saved place for future progress.
- [ ] Keep already earned levels permanent.

## Occasion Rules

- [ ] Implement exact windows from the spec.
- [ ] Implement `Feb 29 -> Feb 28` fallback in non-leap years.
- [ ] Implement yearly re-eligibility until a one-time badge is earned once.
- [ ] Keep currently earnable detection separate from already-earned state.

## Country and Travel Rules

- [ ] Travel counts unique countries worldwide.
- [ ] Curated country badges only exist for the locked 27 countries.
- [ ] Country-specific badges unlock on any qualifying drink in that country.
- [ ] Approximate country detection can count only when the country is unambiguous.

## Grant Flow

- [ ] Compare live evaluation against persisted unlock rows.
- [ ] Grant missing earned levels only once.
- [ ] Preserve earlier timestamps on conflicts.
- [ ] Mark real-time unlocks differently from import/backfill/history-edit unlocks for UI presentation if needed.
- [ ] Mark surfaced-once state so summaries do not repeat the same unlock later.

## Trigger Integration

- [ ] Run evaluation after drink add.
- [ ] Run evaluation after entry edit that can affect achievements.
- [ ] Run evaluation after entry delete.
- [ ] Run evaluation after import completion.
- [ ] Run evaluation after relevant settings changes.
- [ ] Run idempotent startup backfill when catalog version increases.

## Output For UI

- [ ] Return family cards with earned levels, current progress, next target, and setup-required state.
- [ ] Return recent unlocks ordered by `grantedAt`.
- [ ] Return data for “Earnable today” occasion labeling.
- [ ] Return next eligible date/window for one-off occasion details.

## Acceptance

- [ ] Re-running the evaluator is safe and idempotent.
- [ ] Deletions, imports, place changes, and birthday changes all recalculate future progress correctly.
- [ ] Earned levels never disappear once granted.
