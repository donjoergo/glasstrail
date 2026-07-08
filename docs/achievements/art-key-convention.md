# Achievements Art Key Convention

This document locks the naming convention for achievement artwork keys and asset organization.

## Goals

- Keep art keys stable even if the underlying file format changes later.
- Match the append-only catalog model.
- Support separate family cover art and level-specific badge variants.
- Avoid separate locked-state assets.

## Core Rule

Catalog entries should store extensionless `artKey` strings.

Do not store raw asset filenames such as `.png` or `.webp` in the catalog.

## Asset Root

All achievement art should live under:

```text
assets/achievements/
```

## Key Shapes

### Ladder Family Cover

Used for:

- family cards
- profile preview
- setup-required card state

Pattern:

```text
achievements/ladder/<family_id>/cover
```

Examples:

- `achievements/ladder/total_drinks/cover`
- `achievements/ladder/type_beer/cover`
- `achievements/ladder/place_home/cover`

### Ladder Level Badge

Used for:

- earned-level history
- unlock celebration
- recently unlocked section
- detail ladder rows

Pattern:

```text
achievements/ladder/<family_id>/level_<threshold>
```

Examples:

- `achievements/ladder/total_drinks/level_1`
- `achievements/ladder/total_drinks/level_1000`
- `achievements/ladder/travel_countries/level_50`

### Occasion Badge

Pattern:

```text
achievements/occasion/<occasion_stem>/badge
```

Examples:

- `achievements/occasion/birthday/badge`
- `achievements/occasion/first_sip_anniversary/badge`
- `achievements/occasion/oktoberfest/badge`

### Country Badge

Pattern:

```text
achievements/country/<iso_code>/badge
```

Examples:

- `achievements/country/de/badge`
- `achievements/country/us/badge`
- `achievements/country/jp/badge`

## Family Inventory

### Ladder Families

Family cover keys:

- `achievements/ladder/total_drinks/cover`
- `achievements/ladder/streaks/cover`
- `achievements/ladder/type_beer/cover`
- `achievements/ladder/type_wine/cover`
- `achievements/ladder/type_sparkling_wines/cover`
- `achievements/ladder/type_longdrinks/cover`
- `achievements/ladder/type_spirits/cover`
- `achievements/ladder/type_shots/cover`
- `achievements/ladder/type_cocktails/cover`
- `achievements/ladder/type_apple_wines/cover`
- `achievements/ladder/type_non_alcoholic/cover`
- `achievements/ladder/place_home/cover`
- `achievements/ladder/place_work/cover`
- `achievements/ladder/travel_countries/cover`

### Occasion Families

- `achievements/occasion/birthday/badge`
- `achievements/occasion/first_sip_anniversary/badge`
- `achievements/occasion/new_year/badge`
- `achievements/occasion/christmas/badge`
- `achievements/occasion/easter/badge`
- `achievements/occasion/halloween/badge`
- `achievements/occasion/st_patricks_day/badge`
- `achievements/occasion/oktoberfest/badge`
- `achievements/occasion/carnival/badge`

### Country Families

- `achievements/country/de/badge`
- `achievements/country/nl/badge`
- `achievements/country/be/badge`
- `achievements/country/lu/badge`
- `achievements/country/fr/badge`
- `achievements/country/es/badge`
- `achievements/country/pt/badge`
- `achievements/country/it/badge`
- `achievements/country/at/badge`
- `achievements/country/ch/badge`
- `achievements/country/pl/badge`
- `achievements/country/cz/badge`
- `achievements/country/ie/badge`
- `achievements/country/gb/badge`
- `achievements/country/dk/badge`
- `achievements/country/se/badge`
- `achievements/country/no/badge`
- `achievements/country/fi/badge`
- `achievements/country/gr/badge`
- `achievements/country/hr/badge`
- `achievements/country/hu/badge`
- `achievements/country/ro/badge`
- `achievements/country/tr/badge`
- `achievements/country/us/badge`
- `achievements/country/jp/badge`
- `achievements/country/si/badge`
- `achievements/country/mc/badge`

## Rendering Rules

- Locked cards use the same art with UI tint / desaturation.
- Do not create separate `locked` assets in v1.
- Celebration uses the same earned badge art as detail/recent history.
- Friend views reuse the same art as owner views.

## Placeholder Phase

Placeholder art must still use the final production key structure.

That means even temporary generated art should be placed under the same key layout, so catalog definitions do not change later.

## Non-Goals

- No generic bronze/silver/gold asset layer
- No per-platform art-key differences
- No duplicate `@2x`-style key suffixes in the catalog

## Acceptance

- Every catalog family can point to a stable art key before final art exists.
- The UI can render family cards and earned-level badges without inventing ad hoc path logic.
