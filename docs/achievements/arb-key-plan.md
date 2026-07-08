# Achievements ARB Key Plan

This document defines the localization-key structure for the achievements feature.

The exact human-facing copy stays locked in [strings.md](./strings.md). This file defines how that copy should be keyed in `app_en.arb` and `app_de.arb`.

## Conventions

- Use `lowerCamelCase` to match the existing `app_en.arb` style.
- Keep keys explicit instead of relying on runtime-generated achievement strings.
- Do not build ladder descriptions from plural placeholders at runtime.
- Store a fully expanded title and description key for every shipped achievement level.
- Keep `@metadata` entries only where translator notes or placeholders are needed.

## Key Groups

### Screen and UI Keys

Use a small dedicated achievements UI namespace:

- `achievementsTab`
- `achievementsTitle`
- `achievementsBadgesEarned`
- `achievementsFilterAll`
- `achievementsFilterUnlocked`
- `achievementsFilterLocked`
- `achievementsRecentlyUnlocked`
- `achievementsViewAll`
- `achievementsSetupRequired`
- `achievementsSetUpNow`
- `achievementsEarnableToday`
- `achievementsNextEligible`
- `achievementsUnlocked`
- `achievementsLocked`
- `achievementsCompleted`
- `achievementsSummaryBackfillTitle`
- `achievementsSummaryBackfillBody`
- `achievementsOverflowUnlocked`
- `shareAchievements`
- `shareAchievementsBody`
- `achievementReminders`
- `achievementRemindersBody`
- `savedPlacesTitle`
- `savedPlacesHome`
- `savedPlacesWork`
- `savedPlacesArchived`

### Ladder Family Keys

Pattern:

- family title: `achievementFamily<Stem>Title`
- level title: `achievementFamily<Stem>Level<Threshold>Title`
- level description: `achievementFamily<Stem>Level<Threshold>Description`

Example:

- `achievementFamilyTotalDrinksTitle`
- `achievementFamilyTotalDrinksLevel100Title`
- `achievementFamilyTotalDrinksLevel100Description`

### Occasion Keys

Pattern:

- title: `achievementOccasion<Stem>Title`
- description: `achievementOccasion<Stem>Description`

Example:

- `achievementOccasionBirthdayTitle`
- `achievementOccasionBirthdayDescription`

### Country Keys

Pattern:

- title: `achievementCountry<Stem>Title`
- country label: `achievementCountry<Stem>Label`
- description: `achievementCountry<Stem>Description`

Example:

- `achievementCountryDeTitle`
- `achievementCountryDeLabel`
- `achievementCountryDeDescription`

## Stem Map

### Ladder Family Stems

- `total_drinks` -> `TotalDrinks`
- `streaks` -> `Streaks`
- `type_beer` -> `Beer`
- `type_wine` -> `Wine`
- `type_sparkling_wines` -> `SparklingWines`
- `type_longdrinks` -> `Longdrinks`
- `type_spirits` -> `Spirits`
- `type_shots` -> `Shots`
- `type_cocktails` -> `Cocktails`
- `type_apple_wines` -> `AppleWines`
- `type_non_alcoholic` -> `NonAlcoholic`
- `place_home` -> `Home`
- `place_work` -> `Work`
- `travel_countries` -> `TravelCountries`

### Occasion Stems

- `occasion_birthday` -> `Birthday`
- `occasion_first_sip_anniversary` -> `FirstSipAnniversary`
- `occasion_new_year` -> `NewYear`
- `occasion_christmas` -> `Christmas`
- `occasion_easter` -> `Easter`
- `occasion_halloween` -> `Halloween`
- `occasion_st_patricks_day` -> `StPatricksDay`
- `occasion_oktoberfest` -> `Oktoberfest`
- `occasion_carnival` -> `Carnival`

### Country Stems

- `country_de` -> `De`
- `country_nl` -> `Nl`
- `country_be` -> `Be`
- `country_lu` -> `Lu`
- `country_fr` -> `Fr`
- `country_es` -> `Es`
- `country_pt` -> `Pt`
- `country_it` -> `It`
- `country_at` -> `At`
- `country_ch` -> `Ch`
- `country_pl` -> `Pl`
- `country_cz` -> `Cz`
- `country_ie` -> `Ie`
- `country_gb` -> `Gb`
- `country_dk` -> `Dk`
- `country_se` -> `Se`
- `country_no` -> `No`
- `country_fi` -> `Fi`
- `country_gr` -> `Gr`
- `country_hr` -> `Hr`
- `country_hu` -> `Hu`
- `country_ro` -> `Ro`
- `country_tr` -> `Tr`
- `country_us` -> `Us`
- `country_jp` -> `Jp`
- `country_si` -> `Si`
- `country_mc` -> `Mc`

## Exact UI Strings

These values are not already covered in [strings.md](./strings.md) and should be added explicitly.

- `achievementsTab`: `Achievements` / `Achievements`
- `achievementsTitle`: `Achievements` / `Achievements`
- `achievementsBadgesEarned`: `Badges earned` / `Badges verdient`
- `achievementsFilterAll`: `All` / `Alle`
- `achievementsFilterUnlocked`: `Unlocked` / `Freigeschaltet`
- `achievementsFilterLocked`: `Locked` / `Gesperrt`
- `achievementsRecentlyUnlocked`: `Recently unlocked` / `Kürzlich freigeschaltet`
- `achievementsViewAll`: `View all` / `Alle ansehen`
- `achievementsSetupRequired`: `Setup required` / `Einrichtung erforderlich`
- `achievementsSetUpNow`: `Set up now` / `Jetzt einrichten`
- `achievementsEarnableToday`: `Earnable today` / `Heute erreichbar`
- `achievementsNextEligible`: `Next eligible` / `Nächstes Zeitfenster`
- `achievementsUnlocked`: `Unlocked` / `Freigeschaltet`
- `achievementsLocked`: `Locked` / `Gesperrt`
- `achievementsCompleted`: `Completed` / `Abgeschlossen`
- `achievementsSummaryBackfillTitle`: `Achievements unlocked` / `Achievements freigeschaltet`
- `achievementsSummaryBackfillBody`: `You unlocked {count} badges from your history.` / `Du hast {count} Badges aus deinem Verlauf freigeschaltet.`
- `achievementsOverflowUnlocked`: `+{count} more unlocked` / `+{count} weitere freigeschaltet`
- `shareAchievements`: `Share achievements with friends` / `Achievements mit Freunden teilen`
- `shareAchievementsBody`: `Accepted friends can see your earned badges inside the app.` / `Bestätigte Freunde können deine verdienten Badges in der App sehen.`
- `achievementReminders`: `Achievement reminders` / `Achievement-Erinnerungen`
- `achievementRemindersBody`: `Get push reminders for annual and occasion-based badges.` / `Erhalte Push-Erinnerungen für jährliche und anlassbezogene Badges.`
- `savedPlacesTitle`: `Places` / `Orte`
- `savedPlacesHome`: `Home` / `Zuhause`
- `savedPlacesWork`: `Work` / `Arbeit`
- `savedPlacesArchived`: `Previous places` / `Frühere Orte`

Add placeholder metadata for:

- `achievementsSummaryBackfillBody`
- `achievementsOverflowUnlocked`

## Expanded Ladder Key Inventory

The following keys must exist in both ARB files with the literal values from [strings.md](./strings.md).

### Total Drinks

- `achievementFamilyTotalDrinksTitle`
- `achievementFamilyTotalDrinksLevel1Title`
- `achievementFamilyTotalDrinksLevel1Description`
- `achievementFamilyTotalDrinksLevel10Title`
- `achievementFamilyTotalDrinksLevel10Description`
- `achievementFamilyTotalDrinksLevel25Title`
- `achievementFamilyTotalDrinksLevel25Description`
- `achievementFamilyTotalDrinksLevel50Title`
- `achievementFamilyTotalDrinksLevel50Description`
- `achievementFamilyTotalDrinksLevel100Title`
- `achievementFamilyTotalDrinksLevel100Description`
- `achievementFamilyTotalDrinksLevel200Title`
- `achievementFamilyTotalDrinksLevel200Description`
- `achievementFamilyTotalDrinksLevel300Title`
- `achievementFamilyTotalDrinksLevel300Description`
- `achievementFamilyTotalDrinksLevel400Title`
- `achievementFamilyTotalDrinksLevel400Description`
- `achievementFamilyTotalDrinksLevel500Title`
- `achievementFamilyTotalDrinksLevel500Description`
- `achievementFamilyTotalDrinksLevel1000Title`
- `achievementFamilyTotalDrinksLevel1000Description`

### Streaks

- `achievementFamilyStreaksTitle`
- `achievementFamilyStreaksLevel3Title`
- `achievementFamilyStreaksLevel3Description`
- `achievementFamilyStreaksLevel7Title`
- `achievementFamilyStreaksLevel7Description`
- `achievementFamilyStreaksLevel14Title`
- `achievementFamilyStreaksLevel14Description`
- `achievementFamilyStreaksLevel30Title`
- `achievementFamilyStreaksLevel30Description`
- `achievementFamilyStreaksLevel60Title`
- `achievementFamilyStreaksLevel60Description`
- `achievementFamilyStreaksLevel90Title`
- `achievementFamilyStreaksLevel90Description`
- `achievementFamilyStreaksLevel180Title`
- `achievementFamilyStreaksLevel180Description`
- `achievementFamilyStreaksLevel365Title`
- `achievementFamilyStreaksLevel365Description`

### Beer

- `achievementFamilyBeerTitle`
- `achievementFamilyBeerLevel10Title`
- `achievementFamilyBeerLevel10Description`
- `achievementFamilyBeerLevel25Title`
- `achievementFamilyBeerLevel25Description`
- `achievementFamilyBeerLevel50Title`
- `achievementFamilyBeerLevel50Description`
- `achievementFamilyBeerLevel100Title`
- `achievementFamilyBeerLevel100Description`
- `achievementFamilyBeerLevel200Title`
- `achievementFamilyBeerLevel200Description`
- `achievementFamilyBeerLevel300Title`
- `achievementFamilyBeerLevel300Description`
- `achievementFamilyBeerLevel400Title`
- `achievementFamilyBeerLevel400Description`
- `achievementFamilyBeerLevel500Title`
- `achievementFamilyBeerLevel500Description`
- `achievementFamilyBeerLevel1000Title`
- `achievementFamilyBeerLevel1000Description`

### Wine

- `achievementFamilyWineTitle`
- `achievementFamilyWineLevel10Title`
- `achievementFamilyWineLevel10Description`
- `achievementFamilyWineLevel25Title`
- `achievementFamilyWineLevel25Description`
- `achievementFamilyWineLevel50Title`
- `achievementFamilyWineLevel50Description`
- `achievementFamilyWineLevel100Title`
- `achievementFamilyWineLevel100Description`
- `achievementFamilyWineLevel200Title`
- `achievementFamilyWineLevel200Description`
- `achievementFamilyWineLevel300Title`
- `achievementFamilyWineLevel300Description`
- `achievementFamilyWineLevel400Title`
- `achievementFamilyWineLevel400Description`
- `achievementFamilyWineLevel500Title`
- `achievementFamilyWineLevel500Description`
- `achievementFamilyWineLevel1000Title`
- `achievementFamilyWineLevel1000Description`

### Sparkling Wines

- `achievementFamilySparklingWinesTitle`
- `achievementFamilySparklingWinesLevel10Title`
- `achievementFamilySparklingWinesLevel10Description`
- `achievementFamilySparklingWinesLevel25Title`
- `achievementFamilySparklingWinesLevel25Description`
- `achievementFamilySparklingWinesLevel50Title`
- `achievementFamilySparklingWinesLevel50Description`
- `achievementFamilySparklingWinesLevel100Title`
- `achievementFamilySparklingWinesLevel100Description`
- `achievementFamilySparklingWinesLevel200Title`
- `achievementFamilySparklingWinesLevel200Description`
- `achievementFamilySparklingWinesLevel300Title`
- `achievementFamilySparklingWinesLevel300Description`
- `achievementFamilySparklingWinesLevel400Title`
- `achievementFamilySparklingWinesLevel400Description`
- `achievementFamilySparklingWinesLevel500Title`
- `achievementFamilySparklingWinesLevel500Description`
- `achievementFamilySparklingWinesLevel1000Title`
- `achievementFamilySparklingWinesLevel1000Description`

### Longdrinks

- `achievementFamilyLongdrinksTitle`
- `achievementFamilyLongdrinksLevel10Title`
- `achievementFamilyLongdrinksLevel10Description`
- `achievementFamilyLongdrinksLevel25Title`
- `achievementFamilyLongdrinksLevel25Description`
- `achievementFamilyLongdrinksLevel50Title`
- `achievementFamilyLongdrinksLevel50Description`
- `achievementFamilyLongdrinksLevel100Title`
- `achievementFamilyLongdrinksLevel100Description`
- `achievementFamilyLongdrinksLevel200Title`
- `achievementFamilyLongdrinksLevel200Description`
- `achievementFamilyLongdrinksLevel300Title`
- `achievementFamilyLongdrinksLevel300Description`
- `achievementFamilyLongdrinksLevel400Title`
- `achievementFamilyLongdrinksLevel400Description`
- `achievementFamilyLongdrinksLevel500Title`
- `achievementFamilyLongdrinksLevel500Description`
- `achievementFamilyLongdrinksLevel1000Title`
- `achievementFamilyLongdrinksLevel1000Description`

### Spirits

- `achievementFamilySpiritsTitle`
- `achievementFamilySpiritsLevel10Title`
- `achievementFamilySpiritsLevel10Description`
- `achievementFamilySpiritsLevel25Title`
- `achievementFamilySpiritsLevel25Description`
- `achievementFamilySpiritsLevel50Title`
- `achievementFamilySpiritsLevel50Description`
- `achievementFamilySpiritsLevel100Title`
- `achievementFamilySpiritsLevel100Description`
- `achievementFamilySpiritsLevel200Title`
- `achievementFamilySpiritsLevel200Description`
- `achievementFamilySpiritsLevel300Title`
- `achievementFamilySpiritsLevel300Description`
- `achievementFamilySpiritsLevel400Title`
- `achievementFamilySpiritsLevel400Description`
- `achievementFamilySpiritsLevel500Title`
- `achievementFamilySpiritsLevel500Description`
- `achievementFamilySpiritsLevel1000Title`
- `achievementFamilySpiritsLevel1000Description`

### Shots

- `achievementFamilyShotsTitle`
- `achievementFamilyShotsLevel10Title`
- `achievementFamilyShotsLevel10Description`
- `achievementFamilyShotsLevel25Title`
- `achievementFamilyShotsLevel25Description`
- `achievementFamilyShotsLevel50Title`
- `achievementFamilyShotsLevel50Description`
- `achievementFamilyShotsLevel100Title`
- `achievementFamilyShotsLevel100Description`
- `achievementFamilyShotsLevel200Title`
- `achievementFamilyShotsLevel200Description`
- `achievementFamilyShotsLevel300Title`
- `achievementFamilyShotsLevel300Description`
- `achievementFamilyShotsLevel400Title`
- `achievementFamilyShotsLevel400Description`
- `achievementFamilyShotsLevel500Title`
- `achievementFamilyShotsLevel500Description`
- `achievementFamilyShotsLevel1000Title`
- `achievementFamilyShotsLevel1000Description`

### Cocktails

- `achievementFamilyCocktailsTitle`
- `achievementFamilyCocktailsLevel10Title`
- `achievementFamilyCocktailsLevel10Description`
- `achievementFamilyCocktailsLevel25Title`
- `achievementFamilyCocktailsLevel25Description`
- `achievementFamilyCocktailsLevel50Title`
- `achievementFamilyCocktailsLevel50Description`
- `achievementFamilyCocktailsLevel100Title`
- `achievementFamilyCocktailsLevel100Description`
- `achievementFamilyCocktailsLevel200Title`
- `achievementFamilyCocktailsLevel200Description`
- `achievementFamilyCocktailsLevel300Title`
- `achievementFamilyCocktailsLevel300Description`
- `achievementFamilyCocktailsLevel400Title`
- `achievementFamilyCocktailsLevel400Description`
- `achievementFamilyCocktailsLevel500Title`
- `achievementFamilyCocktailsLevel500Description`
- `achievementFamilyCocktailsLevel1000Title`
- `achievementFamilyCocktailsLevel1000Description`

### Apple Wines

- `achievementFamilyAppleWinesTitle`
- `achievementFamilyAppleWinesLevel10Title`
- `achievementFamilyAppleWinesLevel10Description`
- `achievementFamilyAppleWinesLevel25Title`
- `achievementFamilyAppleWinesLevel25Description`
- `achievementFamilyAppleWinesLevel50Title`
- `achievementFamilyAppleWinesLevel50Description`
- `achievementFamilyAppleWinesLevel100Title`
- `achievementFamilyAppleWinesLevel100Description`
- `achievementFamilyAppleWinesLevel200Title`
- `achievementFamilyAppleWinesLevel200Description`
- `achievementFamilyAppleWinesLevel300Title`
- `achievementFamilyAppleWinesLevel300Description`
- `achievementFamilyAppleWinesLevel400Title`
- `achievementFamilyAppleWinesLevel400Description`
- `achievementFamilyAppleWinesLevel500Title`
- `achievementFamilyAppleWinesLevel500Description`
- `achievementFamilyAppleWinesLevel1000Title`
- `achievementFamilyAppleWinesLevel1000Description`

### Non-Alcoholic

- `achievementFamilyNonAlcoholicTitle`
- `achievementFamilyNonAlcoholicLevel10Title`
- `achievementFamilyNonAlcoholicLevel10Description`
- `achievementFamilyNonAlcoholicLevel25Title`
- `achievementFamilyNonAlcoholicLevel25Description`
- `achievementFamilyNonAlcoholicLevel50Title`
- `achievementFamilyNonAlcoholicLevel50Description`
- `achievementFamilyNonAlcoholicLevel100Title`
- `achievementFamilyNonAlcoholicLevel100Description`
- `achievementFamilyNonAlcoholicLevel200Title`
- `achievementFamilyNonAlcoholicLevel200Description`
- `achievementFamilyNonAlcoholicLevel300Title`
- `achievementFamilyNonAlcoholicLevel300Description`
- `achievementFamilyNonAlcoholicLevel400Title`
- `achievementFamilyNonAlcoholicLevel400Description`
- `achievementFamilyNonAlcoholicLevel500Title`
- `achievementFamilyNonAlcoholicLevel500Description`
- `achievementFamilyNonAlcoholicLevel1000Title`
- `achievementFamilyNonAlcoholicLevel1000Description`

### Home

- `achievementFamilyHomeTitle`
- `achievementFamilyHomeLevel1Title`
- `achievementFamilyHomeLevel1Description`
- `achievementFamilyHomeLevel10Title`
- `achievementFamilyHomeLevel10Description`
- `achievementFamilyHomeLevel25Title`
- `achievementFamilyHomeLevel25Description`
- `achievementFamilyHomeLevel50Title`
- `achievementFamilyHomeLevel50Description`
- `achievementFamilyHomeLevel100Title`
- `achievementFamilyHomeLevel100Description`

### Work

- `achievementFamilyWorkTitle`
- `achievementFamilyWorkLevel1Title`
- `achievementFamilyWorkLevel1Description`
- `achievementFamilyWorkLevel10Title`
- `achievementFamilyWorkLevel10Description`
- `achievementFamilyWorkLevel25Title`
- `achievementFamilyWorkLevel25Description`
- `achievementFamilyWorkLevel50Title`
- `achievementFamilyWorkLevel50Description`
- `achievementFamilyWorkLevel100Title`
- `achievementFamilyWorkLevel100Description`

### Travel Countries

- `achievementFamilyTravelCountriesTitle`
- `achievementFamilyTravelCountriesLevel3Title`
- `achievementFamilyTravelCountriesLevel3Description`
- `achievementFamilyTravelCountriesLevel5Title`
- `achievementFamilyTravelCountriesLevel5Description`
- `achievementFamilyTravelCountriesLevel10Title`
- `achievementFamilyTravelCountriesLevel10Description`
- `achievementFamilyTravelCountriesLevel15Title`
- `achievementFamilyTravelCountriesLevel15Description`
- `achievementFamilyTravelCountriesLevel20Title`
- `achievementFamilyTravelCountriesLevel20Description`
- `achievementFamilyTravelCountriesLevel30Title`
- `achievementFamilyTravelCountriesLevel30Description`
- `achievementFamilyTravelCountriesLevel50Title`
- `achievementFamilyTravelCountriesLevel50Description`

## Expanded One-Off Key Inventory

### Occasions

- `achievementOccasionBirthdayTitle`
- `achievementOccasionBirthdayDescription`
- `achievementOccasionFirstSipAnniversaryTitle`
- `achievementOccasionFirstSipAnniversaryDescription`
- `achievementOccasionNewYearTitle`
- `achievementOccasionNewYearDescription`
- `achievementOccasionChristmasTitle`
- `achievementOccasionChristmasDescription`
- `achievementOccasionEasterTitle`
- `achievementOccasionEasterDescription`
- `achievementOccasionHalloweenTitle`
- `achievementOccasionHalloweenDescription`
- `achievementOccasionStPatricksDayTitle`
- `achievementOccasionStPatricksDayDescription`
- `achievementOccasionOktoberfestTitle`
- `achievementOccasionOktoberfestDescription`
- `achievementOccasionCarnivalTitle`
- `achievementOccasionCarnivalDescription`

### Countries

- `achievementCountryDeTitle`
- `achievementCountryDeLabel`
- `achievementCountryDeDescription`
- `achievementCountryNlTitle`
- `achievementCountryNlLabel`
- `achievementCountryNlDescription`
- `achievementCountryBeTitle`
- `achievementCountryBeLabel`
- `achievementCountryBeDescription`
- `achievementCountryLuTitle`
- `achievementCountryLuLabel`
- `achievementCountryLuDescription`
- `achievementCountryFrTitle`
- `achievementCountryFrLabel`
- `achievementCountryFrDescription`
- `achievementCountryEsTitle`
- `achievementCountryEsLabel`
- `achievementCountryEsDescription`
- `achievementCountryPtTitle`
- `achievementCountryPtLabel`
- `achievementCountryPtDescription`
- `achievementCountryItTitle`
- `achievementCountryItLabel`
- `achievementCountryItDescription`
- `achievementCountryAtTitle`
- `achievementCountryAtLabel`
- `achievementCountryAtDescription`
- `achievementCountryChTitle`
- `achievementCountryChLabel`
- `achievementCountryChDescription`
- `achievementCountryPlTitle`
- `achievementCountryPlLabel`
- `achievementCountryPlDescription`
- `achievementCountryCzTitle`
- `achievementCountryCzLabel`
- `achievementCountryCzDescription`
- `achievementCountryIeTitle`
- `achievementCountryIeLabel`
- `achievementCountryIeDescription`
- `achievementCountryGbTitle`
- `achievementCountryGbLabel`
- `achievementCountryGbDescription`
- `achievementCountryDkTitle`
- `achievementCountryDkLabel`
- `achievementCountryDkDescription`
- `achievementCountrySeTitle`
- `achievementCountrySeLabel`
- `achievementCountrySeDescription`
- `achievementCountryNoTitle`
- `achievementCountryNoLabel`
- `achievementCountryNoDescription`
- `achievementCountryFiTitle`
- `achievementCountryFiLabel`
- `achievementCountryFiDescription`
- `achievementCountryGrTitle`
- `achievementCountryGrLabel`
- `achievementCountryGrDescription`
- `achievementCountryHrTitle`
- `achievementCountryHrLabel`
- `achievementCountryHrDescription`
- `achievementCountryHuTitle`
- `achievementCountryHuLabel`
- `achievementCountryHuDescription`
- `achievementCountryRoTitle`
- `achievementCountryRoLabel`
- `achievementCountryRoDescription`
- `achievementCountryTrTitle`
- `achievementCountryTrLabel`
- `achievementCountryTrDescription`
- `achievementCountryUsTitle`
- `achievementCountryUsLabel`
- `achievementCountryUsDescription`
- `achievementCountryJpTitle`
- `achievementCountryJpLabel`
- `achievementCountryJpDescription`
- `achievementCountrySiTitle`
- `achievementCountrySiLabel`
- `achievementCountrySiDescription`
- `achievementCountryMcTitle`
- `achievementCountryMcLabel`
- `achievementCountryMcDescription`

## Implementation Rule

- Copy all literal achievement names and descriptions from [strings.md](./strings.md).
- Do not rename stems once implementation starts.
- Do not introduce generic tier labels like `Bronze`, `Silver`, or `Gold`.
