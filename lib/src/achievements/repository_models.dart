/// Repository-facing model types for the achievements feature.
///
/// See `docs/achievements/repository-and-deeplink-contract.md`.
library;

import 'catalog_models.dart';

/// What the grant flow asks a repository to persist for a newly-qualifying
/// level. The repository stamps `grantedAt` itself (when it durably
/// persists the row); callers only know when the data first qualified.
class AchievementUnlockGrant {
  const AchievementUnlockGrant({
    required this.familyId,
    required this.level,
    required this.qualifiedAt,
    required this.source,
  });

  final String familyId;
  final int level;
  final DateTime qualifiedAt;
  final AchievementUnlockSource source;
}

/// A single earned level shared by a friend. Internal shaping detail used
/// while building [FriendSharedAchievementFamily] results; never exposed
/// directly to the friend-facing UI (which must never show timestamps).
class FriendSharedAchievement {
  const FriendSharedAchievement({
    required this.familyId,
    required this.level,
    required this.grantedAt,
  });

  final String familyId;
  final int level;
  final DateTime grantedAt;
}

/// Earned levels for one family on a friend's shared achievements list.
/// Carries no timestamps and no locked/progress state, per the friend-view
/// privacy rules in `spec.md`.
class FriendSharedAchievementFamily {
  const FriendSharedAchievementFamily({
    required this.familyId,
    required this.earnedLevels,
  });

  final String familyId;
  final List<int> earnedLevels;
}
