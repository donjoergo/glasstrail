/// Pure achievement evaluation.
///
/// Everything here is a function of `AchievementEvaluationContext` (in
/// memory, no repository/UI dependencies). It computes live progress and
/// merges it with previously persisted earned levels via `progress.dart`.
/// See `docs/achievements/spec.md` and `checklist-evaluator-engine.md`.
library;

import '../models.dart' show DrinkCategory;
import 'catalog.dart';
import 'occasion_rules.dart';
import 'place_matching.dart';
import 'progress.dart';
import 'streaks.dart';

export 'catalog.dart';
export 'progress.dart';

/// Evaluator-facing, decoupled shape of a logged drink. Chunk 6 wires the
/// real `DrinkEntry` model into this (with legacy fallback for entries
/// predating achievement metadata); the evaluator itself never depends on
/// the full entry model or persistence.
class AchievementEntry {
  const AchievementEntry({
    required this.category,
    required this.isAlcoholFree,
    required this.achievementLocalDate,
    this.countryCode,
    this.locationPrecision = LocationPrecision.none,
    this.latitude,
    this.longitude,
  });

  final DrinkCategory category;
  final bool isAlcoholFree;

  /// Date-only local calendar date this drink counts toward.
  final DateTime achievementLocalDate;

  /// Lowercase ISO-3166-1 alpha-2, or `null` if not derivable.
  final String? countryCode;
  final LocationPrecision locationPrecision;
  final double? latitude;
  final double? longitude;
}

/// Everything the evaluator needs to compute live progress for the whole
/// catalog. Recomputed fresh from current data on every evaluation run.
class AchievementEvaluationContext {
  const AchievementEvaluationContext({
    required this.entries,
    required this.now,
    this.birthdayMonthDay,
    this.savedPlaces = const <SavedPlace>[],
  });

  final List<AchievementEntry> entries;

  /// Evaluation "now", used for current-streak and occasion window checks.
  final DateTime now;

  /// User's birthday, month/day only (any reference year). `null` means
  /// unset -> `occasion_birthday` is setup-required.
  final DateTime? birthdayMonthDay;

  /// Every currently saved place (active and archived). Deleted places are
  /// simply absent, so they naturally stop contributing to future progress.
  final List<SavedPlace> savedPlaces;
}

const Map<String, DrinkCategory> _drinkTypeFamilyCategories = <String, DrinkCategory>{
  AchievementFamilyIds.typeBeer: DrinkCategory.beer,
  AchievementFamilyIds.typeWine: DrinkCategory.wine,
  AchievementFamilyIds.typeSparklingWines: DrinkCategory.sparklingWines,
  AchievementFamilyIds.typeLongdrinks: DrinkCategory.longdrinks,
  AchievementFamilyIds.typeSpirits: DrinkCategory.spirits,
  AchievementFamilyIds.typeShots: DrinkCategory.shots,
  AchievementFamilyIds.typeCocktails: DrinkCategory.cocktails,
  AchievementFamilyIds.typeAppleWines: DrinkCategory.appleWines,
  AchievementFamilyIds.typeNonAlcoholic: DrinkCategory.nonAlcoholic,
};

/// The earliest known `achievementLocalDate` across all entries, as a
/// month/day anniversary anchor (any reference year), or `null` if there is
/// no entry history yet.
DateTime? firstSipAnniversaryAnchor(List<AchievementEntry> entries) {
  if (entries.isEmpty) return null;
  DateTime earliest = entries.first.achievementLocalDate;
  for (final AchievementEntry entry in entries.skip(1)) {
    if (entry.achievementLocalDate.isBefore(earliest)) {
      earliest = entry.achievementLocalDate;
    }
  }
  return earliest;
}

LadderEvaluationResult _evaluateLadder(
  AchievementFamily family,
  AchievementEvaluationContext ctx,
) {
  switch (family.familyId) {
    case AchievementFamilyIds.totalDrinks:
      final int value = ctx.entries.length;
      return LadderEvaluationResult(familyId: family.familyId, liveValue: value, qualifyingValue: value);

    case AchievementFamilyIds.streaks:
      final StreakResult streaks = computeStreaks(
        ctx.entries.map((AchievementEntry e) => e.achievementLocalDate),
        today: ctx.now,
      );
      return LadderEvaluationResult(
        familyId: family.familyId,
        liveValue: streaks.current,
        qualifyingValue: streaks.best,
      );

    case AchievementFamilyIds.placeHome:
    case AchievementFamilyIds.placeWork:
      final SavedPlaceType placeType =
          family.familyId == AchievementFamilyIds.placeHome ? SavedPlaceType.home : SavedPlaceType.work;
      final List<(double, double)> coordinates = <(double, double)>[
        for (final AchievementEntry e in ctx.entries)
          if (e.locationPrecision == LocationPrecision.precise && e.latitude != null && e.longitude != null)
            (e.latitude!, e.longitude!),
      ];
      final int value = countEntriesMatchingPlaceType(
        preciseEntryCoordinates: coordinates,
        placeType: placeType,
        places: ctx.savedPlaces,
      );
      return LadderEvaluationResult(familyId: family.familyId, liveValue: value, qualifyingValue: value);

    case AchievementFamilyIds.travelCountries:
      final int value =
          ctx.entries.map((AchievementEntry e) => e.countryCode).whereType<String>().toSet().length;
      return LadderEvaluationResult(familyId: family.familyId, liveValue: value, qualifyingValue: value);

    default:
      final DrinkCategory? category = _drinkTypeFamilyCategories[family.familyId];
      final int value =
          category == null ? 0 : ctx.entries.where((AchievementEntry e) => e.category == category).length;
      return LadderEvaluationResult(familyId: family.familyId, liveValue: value, qualifyingValue: value);
  }
}

LadderEvaluationResult _evaluateOccasion(
  AchievementFamily family,
  AchievementEvaluationContext ctx,
  DateTime? anniversaryAnchor,
) {
  final bool qualifies = ctx.entries.any(
    (AchievementEntry e) => occasionMatches(
      familyId: family.familyId,
      localDate: e.achievementLocalDate,
      isBeer: e.category == DrinkCategory.beer,
      birthdayMonthDay: ctx.birthdayMonthDay,
      firstSipAnniversaryMonthDay: anniversaryAnchor,
    ),
  );
  final int value = qualifies ? 1 : 0;
  return LadderEvaluationResult(familyId: family.familyId, liveValue: value, qualifyingValue: value);
}

LadderEvaluationResult _evaluateCountry(AchievementFamily family, AchievementEvaluationContext ctx) {
  final bool qualifies = ctx.entries.any((AchievementEntry e) => e.countryCode == family.countryCode);
  final int value = qualifies ? 1 : 0;
  return LadderEvaluationResult(familyId: family.familyId, liveValue: value, qualifyingValue: value);
}

LadderEvaluationResult evaluateFamily(
  AchievementFamily family,
  AchievementEvaluationContext ctx, {
  DateTime? anniversaryAnchor,
}) {
  switch (family.kind) {
    case AchievementKind.ladder:
      return _evaluateLadder(family, ctx);
    case AchievementKind.oneOffOccasion:
      return _evaluateOccasion(family, ctx, anniversaryAnchor ?? firstSipAnniversaryAnchor(ctx.entries));
    case AchievementKind.oneOffCountry:
      return _evaluateCountry(family, ctx);
  }
}

bool _isSetupRequired(AchievementFamily family, AchievementEvaluationContext ctx) {
  switch (family.familyId) {
    case AchievementFamilyIds.occasionBirthday:
      return ctx.birthdayMonthDay == null;
    case AchievementFamilyIds.occasionFirstSipAnniversary:
      return ctx.entries.isEmpty;
    case AchievementFamilyIds.placeHome:
      return !ctx.savedPlaces.any((SavedPlace p) => p.placeType == SavedPlaceType.home);
    case AchievementFamilyIds.placeWork:
      return !ctx.savedPlaces.any((SavedPlace p) => p.placeType == SavedPlaceType.work);
    default:
      return false;
  }
}

/// Live-evaluates the entire catalog and merges it with [persistedEarnedLevels]
/// (keyed by `familyId`) into the UI-facing progress list, in catalog order.
List<AchievementFamilyProgress> evaluateCatalog({
  required AchievementEvaluationContext ctx,
  required Map<String, Set<int>> persistedEarnedLevels,
}) {
  final DateTime? anchor = firstSipAnniversaryAnchor(ctx.entries);
  return <AchievementFamilyProgress>[
    for (final AchievementFamily family in achievementCatalog)
      mergeFamilyProgress(
        family: family,
        result: evaluateFamily(family, ctx, anniversaryAnchor: anchor),
        persistedEarnedLevels: persistedEarnedLevels[family.familyId] ?? const <int>{},
        setupRequired: _isSetupRequired(family, ctx),
      ),
  ];
}

/// Every level newly qualified by current data that is not already in
/// [persistedEarnedLevels], across the whole catalog. This is what the
/// grant flow (Chunk 5) persists as fresh unlocks.
Map<String, Set<int>> evaluateNewlyQualifyingLevels({
  required AchievementEvaluationContext ctx,
  required Map<String, Set<int>> persistedEarnedLevels,
}) {
  final DateTime? anchor = firstSipAnniversaryAnchor(ctx.entries);
  final Map<String, Set<int>> result = <String, Set<int>>{};
  for (final AchievementFamily family in achievementCatalog) {
    final Set<int> newly = newlyQualifyingLevels(
      family: family,
      result: evaluateFamily(family, ctx, anniversaryAnchor: anchor),
      persistedEarnedLevels: persistedEarnedLevels[family.familyId] ?? const <int>{},
    );
    if (newly.isNotEmpty) {
      result[family.familyId] = newly;
    }
  }
  return result;
}

/// True when [family] (an occasion family) is qualifiable today and not
/// already earned — drives the "Earnable today" pill.
bool isEarnableToday({
  required AchievementFamily family,
  required AchievementEvaluationContext ctx,
  required bool alreadyEarned,
}) {
  if (alreadyEarned || family.kind != AchievementKind.oneOffOccasion) return false;
  final DateTime? anchor = firstSipAnniversaryAnchor(ctx.entries);
  return occasionMatches(
    familyId: family.familyId,
    localDate: ctx.now,
    isBeer: true,
    birthdayMonthDay: ctx.birthdayMonthDay,
    firstSipAnniversaryMonthDay: anchor,
  );
}
