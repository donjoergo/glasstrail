/// Pure model types for the achievements feature.
///
/// These types describe the built-in catalog shape and the persisted /
/// evaluated state that is layered on top of it. Nothing in this file
/// touches persistence, evaluation, or UI.
library;

/// Fixed, ordered top-level grouping for achievement families.
///
/// Enum declaration order is the authoritative category order from
/// `docs/achievements/spec.md` and must not be reordered.
enum AchievementCategory {
  totals,
  streaks,
  drinkTypes,
  occasions,
  places,
  travel,
  countries,
}

extension AchievementCategoryX on AchievementCategory {
  String get storageValue {
    switch (this) {
      case AchievementCategory.totals:
        return 'totals';
      case AchievementCategory.streaks:
        return 'streaks';
      case AchievementCategory.drinkTypes:
        return 'drink_types';
      case AchievementCategory.occasions:
        return 'occasions';
      case AchievementCategory.places:
        return 'places';
      case AchievementCategory.travel:
        return 'travel';
      case AchievementCategory.countries:
        return 'countries';
    }
  }
}

/// Fixed evaluation shape for a family.
enum AchievementKind {
  ladder,
  oneOffOccasion,
  oneOffCountry,
}

extension AchievementKindX on AchievementKind {
  String get storageValue {
    switch (this) {
      case AchievementKind.ladder:
        return 'ladder';
      case AchievementKind.oneOffOccasion:
        return 'one_off_occasion';
      case AchievementKind.oneOffCountry:
        return 'one_off_country';
    }
  }
}

/// A single earnable level inside a family.
///
/// For `ladder` families, [level] equals [threshold]. For one-off families
/// there is exactly one level with `level == 1` and `threshold == null`.
class AchievementLevelDef {
  const AchievementLevelDef({
    required this.level,
    required this.threshold,
    required this.titleKey,
    required this.descriptionKey,
    required this.artKey,
  });

  final int level;
  final int? threshold;
  final String titleKey;
  final String descriptionKey;
  final String artKey;
}

/// A full achievement family: its identity, grouping, and every earnable
/// level inside it.
class AchievementFamily {
  const AchievementFamily({
    required this.familyId,
    required this.category,
    required this.kind,
    required this.familyTitleKey,
    required this.coverArtKey,
    required this.levels,
    this.countryCode,
    this.countryLabelKey,
  });

  /// Stable, immutable identifier from `docs/achievements/spec.md`.
  final String familyId;
  final AchievementCategory category;
  final AchievementKind kind;

  /// Localization key for the family/collection display name.
  final String familyTitleKey;

  /// Art key for family cards, profile preview, and setup-required state.
  final String coverArtKey;

  final List<AchievementLevelDef> levels;

  /// Lowercase ISO-3166-1 alpha-2 code. Only set for [AchievementKind.oneOffCountry].
  final String? countryCode;

  /// Localization key for the explicit country label. Only set for
  /// [AchievementKind.oneOffCountry].
  final String? countryLabelKey;
}

/// Lightweight identity for a specific earnable level, used for dedupe and
/// lookups without carrying the full catalog definition around.
class AchievementUnlockRef {
  const AchievementUnlockRef({required this.familyId, required this.level});

  final String familyId;
  final int level;

  @override
  bool operator ==(Object other) {
    return other is AchievementUnlockRef &&
        other.familyId == familyId &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(familyId, level);

  @override
  String toString() => 'AchievementUnlockRef($familyId, $level)';
}

/// How an unlock came to be granted. Controls unlock-presentation behavior.
enum AchievementUnlockSource {
  realtimeLog,
  import,
  backfill,
  historyEdit,
  settingsChange,
}

extension AchievementUnlockSourceX on AchievementUnlockSource {
  String get storageValue {
    switch (this) {
      case AchievementUnlockSource.realtimeLog:
        return 'realtime_log';
      case AchievementUnlockSource.import:
        return 'import';
      case AchievementUnlockSource.backfill:
        return 'backfill';
      case AchievementUnlockSource.historyEdit:
        return 'history_edit';
      case AchievementUnlockSource.settingsChange:
        return 'settings_change';
    }
  }

  static AchievementUnlockSource? maybeFromStorage(String? value) {
    for (final candidate in AchievementUnlockSource.values) {
      if (candidate.storageValue == value) {
        return candidate;
      }
    }
    return null;
  }
}

/// A persisted, permanent unlock record.
///
/// Deduplicated by `(user, familyId, level)`. Never revoked once granted.
class AchievementUnlock {
  const AchievementUnlock({
    required this.familyId,
    required this.level,
    required this.qualifiedAt,
    required this.grantedAt,
    required this.source,
    this.surfacedAt,
  });

  final String familyId;
  final int level;

  /// When the user's data first met the rule.
  final DateTime qualifiedAt;

  /// When the app/backend persisted the unlock row.
  final DateTime grantedAt;
  final AchievementUnlockSource source;

  /// Set once this unlock has been shown in an unlock summary. `null` means
  /// still pending presentation.
  final DateTime? surfacedAt;

  AchievementUnlockRef get ref => AchievementUnlockRef(familyId: familyId, level: level);

  AchievementUnlock copyWith({
    DateTime? qualifiedAt,
    DateTime? grantedAt,
    AchievementUnlockSource? source,
    DateTime? surfacedAt,
    bool clearSurfacedAt = false,
  }) {
    return AchievementUnlock(
      familyId: familyId,
      level: level,
      qualifiedAt: qualifiedAt ?? this.qualifiedAt,
      grantedAt: grantedAt ?? this.grantedAt,
      source: source ?? this.source,
      surfacedAt: clearSurfacedAt ? null : (surfacedAt ?? this.surfacedAt),
    );
  }
}

/// Exact-vs-approximate location confidence for a logged entry.
enum LocationPrecision {
  none,
  approximate,
  precise,
}

extension LocationPrecisionX on LocationPrecision {
  String get storageValue {
    switch (this) {
      case LocationPrecision.none:
        return 'none';
      case LocationPrecision.approximate:
        return 'approximate';
      case LocationPrecision.precise:
        return 'precise';
    }
  }

  static LocationPrecision maybeFromStorage(String? value) {
    for (final candidate in LocationPrecision.values) {
      if (candidate.storageValue == value) {
        return candidate;
      }
    }
    return LocationPrecision.none;
  }
}

/// Which saved-place slot a place occupies.
enum SavedPlaceType {
  home,
  work,
}

extension SavedPlaceTypeX on SavedPlaceType {
  String get storageValue {
    switch (this) {
      case SavedPlaceType.home:
        return 'home';
      case SavedPlaceType.work:
        return 'work';
    }
  }

  static SavedPlaceType? maybeFromStorage(String? value) {
    for (final candidate in SavedPlaceType.values) {
      if (candidate.storageValue == value) {
        return candidate;
      }
    }
    return null;
  }
}

/// A saved `Home` / `Work` location, active or archived.
///
/// Only one active place per [placeType] may exist at a time; replacing an
/// active place archives the previous one instead of deleting it.
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.placeType,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final SavedPlaceType placeType;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  /// Fixed match radius in meters for all home/work achievement matching.
  static const double matchRadiusMeters = 50;

  SavedPlace copyWith({
    bool? isActive,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return SavedPlace(
      id: id,
      placeType: placeType,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }
}

/// Live-computed progress for a single family, combined with its permanent
/// earned levels. Never persisted; recomputed from current data.
class AchievementFamilyProgress {
  const AchievementFamilyProgress({
    required this.familyId,
    required this.currentValue,
    required this.earnedLevels,
    this.nextLevel,
    this.nextThreshold,
    this.setupRequired = false,
  });

  final String familyId;

  /// Current live metric (e.g. total drinks logged, current streak days,
  /// distinct countries visited). Meaning is family-specific.
  final int currentValue;

  /// Every level number permanently earned for this family, regardless of
  /// current live value.
  final Set<int> earnedLevels;

  /// The next not-yet-earned level, if any levels remain.
  final int? nextLevel;

  /// The threshold for [nextLevel], for ladder families.
  final int? nextThreshold;

  /// True when a required prerequisite (birthday, saved home/work) is
  /// missing, independent of [currentValue].
  final bool setupRequired;

  bool get isCompleted => nextLevel == null;
}

/// Payload for opening a specific achievement detail sheet, used by both
/// route restoration and push deep links.
class AchievementDeepLink {
  const AchievementDeepLink({required this.familyId, required this.level});

  final String familyId;
  final int level;
}
