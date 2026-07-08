/// Adapts the full `DrinkEntry` model into the evaluator's decoupled
/// `AchievementEntry` shape, applying the locked legacy-evaluation
/// fallback for entries persisted before achievement metadata existed.
///
/// See `spec.md` "Legacy Evaluation Fallback".
library;

import '../models.dart';
import 'evaluator.dart';

AchievementEntry toAchievementEntry(DrinkEntry entry) {
  final DateTime localDate = entry.achievementLocalDate ??
      DateTime(entry.consumedAt.year, entry.consumedAt.month, entry.consumedAt.day);

  return AchievementEntry(
    category: entry.category,
    isAlcoholFree: entry.isAlcoholFree,
    achievementLocalDate: localDate,
    // A missing countryCode means the entry does not count for country
    // badges or travel counting -- passing it through unchanged already
    // achieves that, since the evaluator only counts non-null codes.
    countryCode: entry.countryCode,
    // Missing precise-location metadata means the entry does not count
    // for home/work families; LocationPrecision.none (the model default
    // for legacy rows) already excludes it in evaluateFamily.
    locationPrecision: entry.locationPrecision,
    latitude: entry.locationLatitude,
    longitude: entry.locationLongitude,
  );
}

List<AchievementEntry> toAchievementEntries(Iterable<DrinkEntry> entries) =>
    entries.map(toAchievementEntry).toList(growable: false);
