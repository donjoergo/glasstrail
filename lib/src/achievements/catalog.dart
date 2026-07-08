/// The built-in achievement catalog.
///
/// Locked contract: see `docs/achievements/spec.md`,
/// `docs/achievements/art-key-convention.md`, and
/// `docs/achievements/arb-key-plan.md`. Existing shipped family IDs,
/// thresholds, and unlock rules are immutable; the catalog is append-only
/// after release.
library;

import 'catalog_models.dart';

export 'catalog_models.dart';

/// Monotonic catalog version. Bump when new families/levels are appended.
const int achievementCatalogVersion = 1;

/// Fixed, locked family IDs. Do not rename or remove once shipped.
class AchievementFamilyIds {
  AchievementFamilyIds._();

  static const String totalDrinks = 'total_drinks';
  static const String streaks = 'streaks';
  static const String typeBeer = 'type_beer';
  static const String typeWine = 'type_wine';
  static const String typeSparklingWines = 'type_sparkling_wines';
  static const String typeLongdrinks = 'type_longdrinks';
  static const String typeSpirits = 'type_spirits';
  static const String typeShots = 'type_shots';
  static const String typeCocktails = 'type_cocktails';
  static const String typeAppleWines = 'type_apple_wines';
  static const String typeNonAlcoholic = 'type_non_alcoholic';
  static const String placeHome = 'place_home';
  static const String placeWork = 'place_work';
  static const String travelCountries = 'travel_countries';

  static const String occasionBirthday = 'occasion_birthday';
  static const String occasionFirstSipAnniversary = 'occasion_first_sip_anniversary';
  static const String occasionNewYear = 'occasion_new_year';
  static const String occasionChristmas = 'occasion_christmas';
  static const String occasionEaster = 'occasion_easter';
  static const String occasionHalloween = 'occasion_halloween';
  static const String occasionStPatricksDay = 'occasion_st_patricks_day';
  static const String occasionOktoberfest = 'occasion_oktoberfest';
  static const String occasionCarnival = 'occasion_carnival';
}

class _LadderSpec {
  const _LadderSpec(this.familyId, this.category, this.stem, this.thresholds);

  final String familyId;
  final AchievementCategory category;
  final String stem;
  final List<int> thresholds;
}

class _OccasionSpec {
  const _OccasionSpec(this.familyId, this.stem, this.artStem);

  final String familyId;
  final String stem;
  final String artStem;
}

class _CountrySpec {
  const _CountrySpec(this.isoCode, this.stem);

  final String isoCode;
  final String stem;
}

const List<int> _drinkTypeThresholds = <int>[10, 25, 50, 100, 200, 300, 400, 500, 1000];

const List<_LadderSpec> _ladderSpecs = <_LadderSpec>[
  _LadderSpec(
    AchievementFamilyIds.totalDrinks,
    AchievementCategory.totals,
    'TotalDrinks',
    <int>[1, 10, 25, 50, 100, 200, 300, 400, 500, 1000],
  ),
  _LadderSpec(
    AchievementFamilyIds.streaks,
    AchievementCategory.streaks,
    'Streaks',
    <int>[3, 7, 14, 30, 60, 90, 180, 365],
  ),
  _LadderSpec(AchievementFamilyIds.typeBeer, AchievementCategory.drinkTypes, 'Beer', _drinkTypeThresholds),
  _LadderSpec(AchievementFamilyIds.typeWine, AchievementCategory.drinkTypes, 'Wine', _drinkTypeThresholds),
  _LadderSpec(
    AchievementFamilyIds.typeSparklingWines,
    AchievementCategory.drinkTypes,
    'SparklingWines',
    _drinkTypeThresholds,
  ),
  _LadderSpec(
    AchievementFamilyIds.typeLongdrinks,
    AchievementCategory.drinkTypes,
    'Longdrinks',
    _drinkTypeThresholds,
  ),
  _LadderSpec(AchievementFamilyIds.typeSpirits, AchievementCategory.drinkTypes, 'Spirits', _drinkTypeThresholds),
  _LadderSpec(AchievementFamilyIds.typeShots, AchievementCategory.drinkTypes, 'Shots', _drinkTypeThresholds),
  _LadderSpec(
    AchievementFamilyIds.typeCocktails,
    AchievementCategory.drinkTypes,
    'Cocktails',
    _drinkTypeThresholds,
  ),
  _LadderSpec(
    AchievementFamilyIds.typeAppleWines,
    AchievementCategory.drinkTypes,
    'AppleWines',
    _drinkTypeThresholds,
  ),
  _LadderSpec(
    AchievementFamilyIds.typeNonAlcoholic,
    AchievementCategory.drinkTypes,
    'NonAlcoholic',
    _drinkTypeThresholds,
  ),
  _LadderSpec(
    AchievementFamilyIds.placeHome,
    AchievementCategory.places,
    'Home',
    <int>[1, 10, 25, 50, 100],
  ),
  _LadderSpec(
    AchievementFamilyIds.placeWork,
    AchievementCategory.places,
    'Work',
    <int>[1, 10, 25, 50, 100],
  ),
  _LadderSpec(
    AchievementFamilyIds.travelCountries,
    AchievementCategory.travel,
    'TravelCountries',
    <int>[3, 5, 10, 15, 20, 30, 50],
  ),
];

const List<_OccasionSpec> _occasionSpecs = <_OccasionSpec>[
  _OccasionSpec(AchievementFamilyIds.occasionBirthday, 'Birthday', 'birthday'),
  _OccasionSpec(
    AchievementFamilyIds.occasionFirstSipAnniversary,
    'FirstSipAnniversary',
    'first_sip_anniversary',
  ),
  _OccasionSpec(AchievementFamilyIds.occasionNewYear, 'NewYear', 'new_year'),
  _OccasionSpec(AchievementFamilyIds.occasionChristmas, 'Christmas', 'christmas'),
  _OccasionSpec(AchievementFamilyIds.occasionEaster, 'Easter', 'easter'),
  _OccasionSpec(AchievementFamilyIds.occasionHalloween, 'Halloween', 'halloween'),
  _OccasionSpec(AchievementFamilyIds.occasionStPatricksDay, 'StPatricksDay', 'st_patricks_day'),
  _OccasionSpec(AchievementFamilyIds.occasionOktoberfest, 'Oktoberfest', 'oktoberfest'),
  _OccasionSpec(AchievementFamilyIds.occasionCarnival, 'Carnival', 'carnival'),
];

/// The curated 27-country catalog, in `strings.md` order.
const List<_CountrySpec> _countrySpecs = <_CountrySpec>[
  _CountrySpec('de', 'De'),
  _CountrySpec('nl', 'Nl'),
  _CountrySpec('be', 'Be'),
  _CountrySpec('lu', 'Lu'),
  _CountrySpec('fr', 'Fr'),
  _CountrySpec('es', 'Es'),
  _CountrySpec('pt', 'Pt'),
  _CountrySpec('it', 'It'),
  _CountrySpec('at', 'At'),
  _CountrySpec('ch', 'Ch'),
  _CountrySpec('pl', 'Pl'),
  _CountrySpec('cz', 'Cz'),
  _CountrySpec('ie', 'Ie'),
  _CountrySpec('gb', 'Gb'),
  _CountrySpec('dk', 'Dk'),
  _CountrySpec('se', 'Se'),
  _CountrySpec('no', 'No'),
  _CountrySpec('fi', 'Fi'),
  _CountrySpec('gr', 'Gr'),
  _CountrySpec('hr', 'Hr'),
  _CountrySpec('hu', 'Hu'),
  _CountrySpec('ro', 'Ro'),
  _CountrySpec('tr', 'Tr'),
  _CountrySpec('us', 'Us'),
  _CountrySpec('jp', 'Jp'),
  _CountrySpec('si', 'Si'),
  _CountrySpec('mc', 'Mc'),
];

/// ISO codes for the curated country catalog, for quick membership checks.
final Set<String> curatedCountryCodes = _countrySpecs.map((_CountrySpec s) => s.isoCode).toSet();

AchievementFamily _buildLadderFamily(_LadderSpec spec) {
  return AchievementFamily(
    familyId: spec.familyId,
    category: spec.category,
    kind: AchievementKind.ladder,
    familyTitleKey: 'achievementFamily${spec.stem}Title',
    coverArtKey: 'achievements/ladder/${spec.familyId}/cover',
    levels: spec.thresholds
        .map(
          (int threshold) => AchievementLevelDef(
            level: threshold,
            threshold: threshold,
            titleKey: 'achievementFamily${spec.stem}Level${threshold}Title',
            descriptionKey: 'achievementFamily${spec.stem}Level${threshold}Description',
            artKey: 'achievements/ladder/${spec.familyId}/level_$threshold',
          ),
        )
        .toList(growable: false),
  );
}

AchievementFamily _buildOccasionFamily(_OccasionSpec spec) {
  final String titleKey = 'achievementOccasion${spec.stem}Title';
  final String descriptionKey = 'achievementOccasion${spec.stem}Description';
  final String artKey = 'achievements/occasion/${spec.artStem}/badge';
  return AchievementFamily(
    familyId: spec.familyId,
    category: AchievementCategory.occasions,
    kind: AchievementKind.oneOffOccasion,
    familyTitleKey: titleKey,
    coverArtKey: artKey,
    levels: <AchievementLevelDef>[
      AchievementLevelDef(
        level: 1,
        threshold: null,
        titleKey: titleKey,
        descriptionKey: descriptionKey,
        artKey: artKey,
      ),
    ],
  );
}

AchievementFamily _buildCountryFamily(_CountrySpec spec) {
  final String familyId = 'country_${spec.isoCode}';
  final String titleKey = 'achievementCountry${spec.stem}Title';
  final String descriptionKey = 'achievementCountry${spec.stem}Description';
  final String labelKey = 'achievementCountry${spec.stem}Label';
  final String artKey = 'achievements/country/${spec.isoCode}/badge';
  return AchievementFamily(
    familyId: familyId,
    category: AchievementCategory.countries,
    kind: AchievementKind.oneOffCountry,
    familyTitleKey: titleKey,
    coverArtKey: artKey,
    countryCode: spec.isoCode,
    countryLabelKey: labelKey,
    levels: <AchievementLevelDef>[
      AchievementLevelDef(
        level: 1,
        threshold: null,
        titleKey: titleKey,
        descriptionKey: descriptionKey,
        artKey: artKey,
      ),
    ],
  );
}

/// The full, ordered achievement catalog.
///
/// Order follows the fixed category order from `spec.md`; within a category,
/// declaration order above is preserved.
final List<AchievementFamily> achievementCatalog = <AchievementFamily>[
  ..._ladderSpecs.where((_LadderSpec s) => s.category == AchievementCategory.totals).map(_buildLadderFamily),
  ..._ladderSpecs.where((_LadderSpec s) => s.category == AchievementCategory.streaks).map(_buildLadderFamily),
  ..._ladderSpecs.where((_LadderSpec s) => s.category == AchievementCategory.drinkTypes).map(_buildLadderFamily),
  ..._occasionSpecs.map(_buildOccasionFamily),
  ..._ladderSpecs.where((_LadderSpec s) => s.category == AchievementCategory.places).map(_buildLadderFamily),
  ..._ladderSpecs.where((_LadderSpec s) => s.category == AchievementCategory.travel).map(_buildLadderFamily),
  ..._countrySpecs.map(_buildCountryFamily),
];

final Map<String, AchievementFamily> achievementCatalogById = <String, AchievementFamily>{
  for (final AchievementFamily family in achievementCatalog) family.familyId: family,
};

AchievementFamily? achievementFamilyById(String familyId) => achievementCatalogById[familyId];

/// Official Oktoberfest date ranges, shared by app catalog and reminder
/// backend. Each entry is `(startMonth, startDay, endMonth, endDay)` in a
/// given year. Locked in `spec.md`.
const Map<int, (int, int, int, int)> oktoberfestDateRanges = <int, (int, int, int, int)>{
  2026: (9, 19, 10, 4),
  2027: (9, 18, 10, 3),
  2028: (9, 16, 10, 3),
  2029: (9, 22, 10, 7),
  2030: (9, 21, 10, 6),
};
