/// Merges live-computed evaluation results with permanently persisted
/// unlock state into the [AchievementFamilyProgress] shape the UI reads.
///
/// Nothing here touches persistence directly: callers pass in the set of
/// already-earned levels for a family and get back the combined progress.
library;

import 'catalog_models.dart';

/// Result of live-evaluating a ladder family (or a one-off family modeled
/// as a single-level ladder) against current data.
///
/// [liveValue] drives the progress bar / "current progress" display.
/// [qualifyingValue] drives which levels current data would newly earn.
/// These differ only for streak families (best historical vs current
/// active streak); for every other family they are equal.
class LadderEvaluationResult {
  const LadderEvaluationResult({
    required this.familyId,
    required this.liveValue,
    required this.qualifyingValue,
  });

  final String familyId;
  final int liveValue;
  final int qualifyingValue;

  /// Every level whose threshold is met by [qualifyingValue]. For one-off
  /// families (threshold == null, single level) this is `{1}` when
  /// [qualifyingValue] > 0.
  Set<int> qualifyingLevels(List<AchievementLevelDef> levels) {
    final Set<int> result = <int>{};
    for (final AchievementLevelDef level in levels) {
      if (level.threshold == null) {
        if (qualifyingValue > 0) {
          result.add(level.level);
        }
      } else if (qualifyingValue >= level.threshold!) {
        result.add(level.level);
      }
    }
    return result;
  }
}

/// Combines a live [LadderEvaluationResult] with previously persisted
/// earned levels into the permanent-plus-live progress shape.
///
/// Earned levels are the union of what was already persisted and what
/// current data newly qualifies for; they never shrink. The next target
/// is always the lowest not-yet-earned level, so a card keeps showing
/// progress toward the next tier even if [LadderEvaluationResult.liveValue]
/// is below an already-earned threshold (e.g. a broken streak).
AchievementFamilyProgress mergeFamilyProgress({
  required AchievementFamily family,
  required LadderEvaluationResult result,
  required Set<int> persistedEarnedLevels,
  bool setupRequired = false,
}) {
  final Set<int> earnedLevels = <int>{
    ...persistedEarnedLevels,
    ...result.qualifyingLevels(family.levels),
  };

  AchievementLevelDef? next;
  for (final AchievementLevelDef level in family.levels) {
    if (!earnedLevels.contains(level.level)) {
      next = level;
      break;
    }
  }

  return AchievementFamilyProgress(
    familyId: family.familyId,
    currentValue: result.liveValue,
    earnedLevels: earnedLevels,
    nextLevel: next?.level,
    nextThreshold: next?.threshold,
    setupRequired: setupRequired,
  );
}

/// Newly-qualifying levels that are not yet in [persistedEarnedLevels].
/// This is what the grant flow (Chunk 5) persists as fresh unlocks.
Set<int> newlyQualifyingLevels({
  required AchievementFamily family,
  required LadderEvaluationResult result,
  required Set<int> persistedEarnedLevels,
}) {
  final Set<int> qualifying = result.qualifyingLevels(family.levels);
  return qualifying.difference(persistedEarnedLevels);
}
