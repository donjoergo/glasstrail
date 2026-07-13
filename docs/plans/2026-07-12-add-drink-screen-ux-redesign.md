# Add-drink screen UX redesign

## Context

The current "Add drink" screen (`lib/src/screens/add_drink_screen.dart` +
`lib/src/widgets/drink_picker_catalog.dart`) is a single long `ListView`:
search field, an unbounded row of recent-drink chips, an `ExpansionTile`
accordion per category (tap to expand, then tap a `ListTile` row to pick),
then — once a drink is picked — volume/location/comment/photo fields and a
Save button appended below in the *same* scroll view. On mobile this means
scrolling past a growing pile of expanded accordions to reach the details
fields; on desktop the form is just centered at a fixed width, wasting the
extra screen space.

The user prototyped a replacement in Claude Design
(`/home/joerg/Downloads/New-drink screen UX improvements/New Drink UX
Wireframes.dc.html`) and asked to implement the current hi-fi mobile and
desktop mocks from it:

- **Mobile — section `id="t4"`, option `4a`** (supersedes the file's older
  `2a`): a 3-step wizard — **Step 1: category** (search + recents chips +
  a 2-col grid of *category tiles* showing name and drink count, no
  individual drinks yet) → **Step 2: drinks in category** (a 2-col card
  grid of every drink in the chosen category, with its own local filter
  field) → **Step 3: details** (selected-drink summary with a "Change"
  action, volume, location, comment, photo, Save). Recent-chip taps and
  global search results on Step 1 skip Step 2 and jump straight to Step 3
  — in that case the step counter reads "Step 2 of 2" instead of "Step 3
  of 3" (the denominator is dynamic).
- **Desktop — section `id="t3"`, option `3a`** (unaffected by the mobile
  revision — desktop has room to show the whole catalog at once, so it
  keeps no category-narrowing step): a static two-pane layout, no stepper.
  Left pane (flex width) = search + recents + every category's drinks
  shown as an always-visible card grid (grows to more columns on the wider
  pane), selected card gets an outline instead of a checkmark. Right pane
  (fixed ~340–360px) = the details form, live-updating as soon as a drink
  is picked; before that, an empty state reads "Pick a drink to continue".

Both screens replace the accordion with an always-visible card grid and
add a search "takeover" (typing hides recents/catalog, results replace
everything below the search field, with an inline "Create custom drink
'{query}'" affordance) and capped/ellipsized recent-chips (max 4 chips /
2 rows, no "Alcohol-free" tag). The desktop/mobile split uses the existing
`AppBreakpoints.isExpanded` (≥840), matching the breakpoint already used
elsewhere in this screen's picker (`showDrinkPickerSheet`).

## Design decision: "back" always returns to Step 1

Both the AppBar back arrow (from Step 2 or Step 3) and the Step 3 "Change"
button return to Step 1 (category tiles), not to Step 2. Step 2 is
stateless in the mockup ("back arrow returns to step 1 with nothing
selected yet"), so a single `_backToCategoryStep()` rule keeps the state
machine simple instead of tracking which step a details-view was entered
from. Minor cost: re-picking a different drink in the *same* category
after reaching details takes one extra tap (through the category tile
again). Acceptable tradeoff for simplicity; easy to special-case later if
it proves annoying in practice.

## Implementation

### `lib/src/screens/add_drink_screen.dart`

Keep all existing state/logic in `_AddDrinkStateState` untouched — the
volume/location/comment/photo fields, `_save`, `_pickPhoto`,
`_openCustomDrinkDialog`, `_refreshLocation`, etc. Only `build()` and
drink-selection get restructured. Extract the existing details section
(lines ~288–489 today) into a shared `_buildDetailsForm({required bool
showChangeButton, VoidCallback? onChange})` so mobile Step 3 and the
desktop right pane call the exact same code — no duplication.

Add:

```dart
enum _AddDrinkStep { category, drinksInCategory, details }

_AddDrinkStep _mobileStep = _AddDrinkStep.category;
DrinkCategory? _selectedCategoryStep;
bool _reachedDetailsViaShortcut = false;
```

Fold the "always arrive at details" transition into the existing
`_selectDrink()` method itself (`_mobileStep = _AddDrinkStep.details`) so
every selection path — mobile category-drink tap, mobile shortcut
(recents/search), and desktop pane tap — consistently lands on Step 3/the
populated right pane. This also avoids an edge case where picking a drink
only through the desktop pane and then narrowing the window would show
Step 1 instead of the already-selected drink's details, since `_mobileStep`
would otherwise never have been touched by a desktop-only session.

Add thin wrappers around it: `_openCategoryStep(category)` (Step 1 → Step
2), `_handleCategoryDrinkSelected(drink)` (Step 2 → Step 3, non-shortcut),
`_handleShortcutDrinkSelected(drink)` (Step 1 recents/search → Step 3,
`_reachedDetailsViaShortcut = true`), and `_backToCategoryStep()` (→ Step
1, clears `_selectedCategoryStep`).

`build()` branches on `AppBreakpoints.isExpanded(context)`:

- **Desktop**: single static `AppBar(title: Text(l10n.addDrink))`, body =
  `Row(children: [Expanded(DrinkPickerCatalog(mode: flattened, onSelect:
  _selectDrink, ...)), SizedBox(width: 340, child: _selectedDrink == null
  ? _emptyState : _buildDetailsForm(showChangeButton: false))])`, wrapped
  in `AppConstrainedContent(maxWidth: AppBreakpoints.addDrinkDesktopMaxWidth)`
  (new constant, 960, added next to the other pane-width constants in
  `app_breakpoints.dart`) so it doesn't inherit the narrower default
  `formContentMaxWidth`. Empty state: a small centered `Icon` + one line
  of text via a new `addDrinkPickToContinue` string — no need to reach for
  a heavier empty-state widget for a single line.
- **Mobile**: AppBar and body switch on `_mobileStep` (table below); body
  content is `DrinkPickerCatalog(mode: categoryTiles, ...)` for
  `category`, the new `DrinkCategoryGrid` for `drinksInCategory`, or
  `_buildDetailsForm(showChangeButton: true, onChange: _backToCategoryStep)`
  for `details`.

| `_mobileStep` | leading | title | step label |
|---|---|---|---|
| `category` | pop route | `l10n.addDrink` | Step 1 of 3 |
| `drinksInCategory` | `_backToCategoryStep()` | `l10n.categoryLabel(_selectedCategoryStep!)` | Step 2 of 3 |
| `details` | `_backToCategoryStep()` | `l10n.addDrinkDetailsStepTitle` | Step 3 of 3, or Step 2 of 2 if `_reachedDetailsViaShortcut` |

Wrap the `Scaffold` in `PopScope(canPop: isExpanded || _mobileStep ==
category, onPopInvokedWithResult: ...)` so the Android back
gesture/button also routes through `_backToCategoryStep()` instead of
leaving the screen — same pattern already used in
`lib/src/beer_with_me_import_flow.dart`.

Drop the `collapseAfterSelect: true` argument passed to
`DrinkPickerCatalog` today (dead once nothing expands/collapses).

### `lib/src/widgets/drink_picker_catalog.dart`

Stays the widget for the desktop left pane, mobile Step 1's category
tiles, and `showDrinkPickerSheet` (used elsewhere, e.g. changing a
history entry's drink — that stays a flattened single-step picker, since a
modal sheet is the wrong place for a 3-step wizard and it already pops on
selection). Add a mode:

```dart
enum DrinkCatalogMode { flattened, categoryTiles }
```

with a new `mode` param (default `flattened`) and `onSelectCategory`
(required when `mode == categoryTiles`). Remove `_expandedCategory`,
`_autoExpandSearchResults`, and `collapseAfterSelect` entirely — nothing
expands/collapses anymore.

Shared in both modes:
- **Recents**: cap to `recentDrinks.take(4)`, compute chip `maxWidth` via
  `LayoutBuilder` so exactly 2 fit per row, ellipsize the name to one
  line, drop the "• Alcohol-free" suffix.
- **Search takeover**: non-empty query hides recents and whichever
  catalog UI is active, replaced by a flat results list (new
  `Key('drink-search-result-<id>')` rows) plus a trailing "Create custom
  drink '{query}'" row (`Key('drink-search-create-custom-button')`), and a
  `l10n.addDrinkSearchResultsCount(count)` label. Same in both modes since
  search always spans the full drink list, not just a category.

Mode-specific:
- `flattened`: today's per-category rendering, but the `ExpansionTile`
  header becomes a static, non-interactive label
  (`Key('drink-category-title-<category>')`) followed by a card grid of a
  new public `DrinkGridCard` (name, volume, no accordion; selected state =
  outline border, no checkmark; `Key('drink-card-<id>')`). Column count
  via a new public `drinkGridColumnsForWidth(double width)` helper
  (`(width / 150).floor().clamp(2, 5)`) so the grid densifies naturally in
  the wide desktop pane and in the narrower picker sheet alike, without
  hardcoding device breakpoints.
- `categoryTiles` (mobile Step 1 only): a 2-col grid of a new
  `_CategoryTile` (`Key('drink-category-tile-<category>')`) built from the
  same `grouped` map (skip zero-count categories), each showing
  `l10n.categoryLabel(category)` and `l10n.addDrinkCategoryDrinkCount(count)`
  ("12 drinks"). Tapping calls `onSelectCategory(category)`. Heading text
  becomes `l10n.addDrinkCategoriesHeading` ("Categories") instead of
  `l10n.catalog`; the "+ Custom drink" action pill stays.

Export `DrinkGridCard` and `drinkGridColumnsForWidth` (non-underscore) so
the new Step 2 widget can reuse them directly.

### New file: `lib/src/widgets/drink_category_grid.dart`

`DrinkCategoryGrid` — mobile Step 2 only. Stateful, owns a local filter
`TextEditingController`. Params: `category`, `drinks` (pre-filtered to
that category by the caller), `localeCode`, `unit`, `selectedDrink`,
`enabled`, `onSelect`. Renders a filter `TextFormField` (reuse
`l10n.searchDrinks` as the label rather than inventing per-category
grammar like the mockup's "Filter beers" — pluralizing arbitrary
`DrinkCategory` names into natural phrases isn't worth a new ARB key here)
plus the same `DrinkGridCard` grid via `drinkGridColumnsForWidth`,
filtered in place by the local query. No search-takeover/"create custom"
affordance here — the mockup's Step 2 doesn't have one and the list is
already small.

### `lib/src/app_breakpoints.dart`

Add `addDrinkDesktopMaxWidth = 960` alongside the other pane-width
constants.

### Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`)

Add, following existing ICU/placeholder conventions in the file
(`statisticsMapClusterTitle` for plurals, `deleteAccountVerificationLabel`
for quoted placeholders, `beerWithMeImportProgress` for `{x} of {y}`):

| Key | English | German |
|---|---|---|
| `addDrinkStepIndicator` | `Step {current} of {total}` | `Schritt {current} von {total}` |
| `addDrinkDetailsStepTitle` | `Details` | `Details` |
| `addDrinkChangeSelection` | `Change` | `Ändern` |
| `addDrinkSearchResultsCount` | `{count, plural, =0{No results} =1{1 result} other{{count} results}}` | `{count, plural, =0{Keine Ergebnisse} =1{1 Ergebnis} other{{count} Ergebnisse}}` |
| `createCustomDrinkWithQuery` | `Create custom drink "{query}"` | `Eigenes Getränk "{query}" erstellen` |
| `addDrinkPickToContinue` | `Pick a drink to continue` | `Wähle ein Getränk aus, um fortzufahren` |
| `addDrinkCategoriesHeading` | `Categories` | `Kategorien` |
| `addDrinkCategoryDrinkCount` | `{count, plural, =1{1 drink} other{{count} drinks}}` | `{count, plural, =1{1 Getränk} other{{count} Getränke}}` |

After editing both ARB files: run `flutter gen-l10n`, then `dart run
tool/generate_notification_push_l10n.dart` per `AGENTS.md`.

### Test updates

**`test/home_shell_test.dart`** — 15 existing tests depend on the old
accordion+single-scroll structure and need updating (all currently tap
`drink-category-title-<x>` to expand, then find a `ListTile` by text, or
assume details fields are reachable by scrolling the same `ListView` as
the picker): the spinner test, the unit-conversion test, three
location tests, two photo tests, four bar/reorder tests, the
localized-search test, and the sheet-based edit-from-history test. The
mechanical fix for most: replace `tap(drink-category-title-beer) [expand]
→ tap(widgetWithText(ListTile, name))` with `tap(drink-category-tile-beer)
[go to step 2] → tap(drink-card-<id> or find.text(name)) [go to step 3]`
— same tap count, screen transition instead of an expand+scroll. The four
bar/reorder tests additionally need to assert against category **tiles**
disappearing/reordering rather than `ExpansionTile`/`ListTile` state.

Two tests need more than a mechanical rename:
- **"clears the add-drink search input and restores categories"** — its
  `drink-category-title-beer` assertions become
  `drink-category-tile-beer` (since mobile Step 1 now shows tiles, not
  the flattened per-category labels).
- **"keeps add-drink categories collapsed and closes them after
  selection"** — its premise (categories start collapsed) is gone; rewrite
  as an end-to-end walk of the real 3-step flow: Step 1 shows only
  category tiles (drink names not yet visible) → tap Beer tile → Step 2
  shows only Beer's drinks → tap a drink → Step 3/Details shown, picker
  gone → tap the back arrow → back at Step 1 tiles (validates the
  "always back to Step 1" rule) → tap Wine tile → Step 2 now shows Wine's
  drinks.

Add one new test for the shortcut path: tapping a recent chip or a search
result on Step 1 jumps straight to Step 3 and shows "Step 2 of 2".

**`test/drink_picker_sheet_test.dart`** — chrome-only assertions
(sheet-vs-dialog based on width), should need no changes; verify after
the `flattened`-mode rewrite.

**`integration_test/app_flow_test.dart`** — the existing sign-up-and-log-a-drink
flow types into the search field and taps the "Water" result, which
still lands directly on Step 3 (search results always skip straight to
details) — should keep working unchanged; re-run to confirm.

## Verification

- `mcp__dart__analyze_files` on the changed/added files.
- `mcp__dart__run_tests` for the updated `test/home_shell_test.dart`,
  `test/drink_picker_sheet_test.dart`, and any new test file, plus a full
  `flutter test` pass afterward.
- Run the app (`flutter run -d chrome` or similar) and manually walk: the
  mobile 3-step flow end-to-end including the shortcut path and back
  navigation, then resize the same session past 840px to confirm the
  desktop two-pane layout and live-updating right pane, including the
  "Pick a drink to continue" empty state and the search-takeover in both
  layouts.
- `flutter test integration_test` for the existing end-to-end flow.
