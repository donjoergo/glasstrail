import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../achievements/achievement_localizations.dart';
import '../achievements/catalog.dart';
import '../achievements/occasion_rules.dart';
import '../app_routes.dart';
import '../app_scope.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, this.initialDeepLink});

  /// Set by the deep-link service / post-auth redirect to open a specific
  /// detail sheet as soon as the tab mounts. Normal restoration never
  /// passes this -- only push and explicit post-auth redirect do.
  final AchievementDeepLinkTarget? initialDeepLink;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementDeepLinkTarget? _openDetail;

  @override
  void initState() {
    super.initState();
    _openDetail = widget.initialDeepLink;
  }

  @override
  void didUpdateWidget(covariant AchievementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDeepLink != null &&
        widget.initialDeepLink != oldWidget.initialDeepLink) {
      setState(() => _openDetail = widget.initialDeepLink);
    }
  }

  void _openFamily(String familyId) {
    setState(() => _openDetail = AchievementDeepLinkTarget(familyId: familyId));
  }

  void _closeDetail() {
    setState(() => _openDetail = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final progress = controller.achievementProgress;
    final filter = controller.achievementsFilter;

    final filtered = progress.where((p) {
      return switch (filter) {
        AchievementsFilter.all => true,
        AchievementsFilter.unlocked => p.earnedLevels.isNotEmpty,
        AchievementsFilter.locked => p.earnedLevels.isEmpty,
      };
    }).toList(growable: false);

    final sections = <AchievementCategory, List<_FamilyCardData>>{};
    for (final p in filtered) {
      final family = achievementFamilyById(p.familyId);
      if (family == null) continue;
      (sections[family.category] ??= <_FamilyCardData>[])
          .add(_FamilyCardData(family: family, progress: p));
    }

    final totalEarnedLevels = progress.fold<int>(
      0,
      (sum, p) => sum + p.earnedLevels.length,
    );
    final recentlyUnlocked = controller.achievementUnlocks.take(5).toList(growable: false);

    return Stack(
      children: <Widget>[
        CustomScrollView(
          key: const PageStorageKey<String>('achievements-scroll'),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$totalEarnedLevels',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(l10n.achievementsBadgesEarned),
                    const SizedBox(height: 12),
                    _FilterChips(
                      filter: filter,
                      onChanged: controller.setAchievementsFilter,
                    ),
                  ],
                ),
              ),
            ),
            if (recentlyUnlocked.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecentlyUnlockedSection(
                  unlocks: recentlyUnlocked,
                  onTap: _openFamily,
                ),
              ),
            for (final entry in sections.entries) ...<Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    _categoryLabel(l10n, entry.key),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _FamilyCard(
                      data: entry.value[index],
                      onTap: () => _openFamily(entry.value[index].family.familyId),
                    ),
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
        if (_openDetail != null)
          _AchievementDetailOverlay(
            target: _openDetail!,
            onClose: _closeDetail,
          ),
      ],
    );
  }

  String _categoryLabel(AppLocalizations l10n, AchievementCategory category) {
    // Category section headers reuse the first family's title key group
    // conceptually, but v1 keeps this simple with a fixed English/German
    // label per category since spec.md doesn't define separate section
    // header copy.
    return switch (category) {
      AchievementCategory.totals => l10n.achievementsCategoryTotals,
      AchievementCategory.streaks => l10n.achievementsCategoryStreaks,
      AchievementCategory.drinkTypes => l10n.achievementsCategoryDrinkTypes,
      AchievementCategory.occasions => l10n.achievementsCategoryOccasions,
      AchievementCategory.places => l10n.achievementsCategoryPlaces,
      AchievementCategory.travel => l10n.achievementsCategoryTravel,
      AchievementCategory.countries => l10n.achievementsCategoryCountries,
    };
  }
}

class _FamilyCardData {
  const _FamilyCardData({required this.family, required this.progress});

  final AchievementFamily family;
  final AchievementFamilyProgress progress;
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final AchievementsFilter filter;
  final ValueChanged<AchievementsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: <Widget>[
        ChoiceChip(
          label: Text(l10n.achievementsFilterAll),
          selected: filter == AchievementsFilter.all,
          onSelected: (_) => onChanged(AchievementsFilter.all),
        ),
        ChoiceChip(
          label: Text(l10n.achievementsFilterUnlocked),
          selected: filter == AchievementsFilter.unlocked,
          onSelected: (_) => onChanged(AchievementsFilter.unlocked),
        ),
        ChoiceChip(
          label: Text(l10n.achievementsFilterLocked),
          selected: filter == AchievementsFilter.locked,
          onSelected: (_) => onChanged(AchievementsFilter.locked),
        ),
      ],
    );
  }
}

class _RecentlyUnlockedSection extends StatelessWidget {
  const _RecentlyUnlockedSection({required this.unlocks, required this.onTap});

  final List<AchievementUnlock> unlocks;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.achievementsRecentlyUnlocked,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: unlocks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final unlock = unlocks[index];
              final family = achievementFamilyById(unlock.familyId);
              final level = family?.levels.firstWhere(
                (l) => l.level == unlock.level,
                orElse: () => family.levels.first,
              );
              return _RecentBadge(
                family: family,
                level: level,
                onTap: () => onTap(unlock.familyId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentBadge extends StatelessWidget {
  const _RecentBadge({required this.family, required this.level, required this.onTap});

  final AchievementFamily? family;
  final AchievementLevelDef? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              family == null ? Icons.emoji_events_rounded : _categoryIcon(family!.category),
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 4),
            Text(
              level == null ? '' : resolveAchievementString(l10n, level!.titleKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(AchievementCategory category) {
  return switch (category) {
    AchievementCategory.totals => Icons.local_bar_rounded,
    AchievementCategory.streaks => Icons.local_fire_department_rounded,
    AchievementCategory.drinkTypes => Icons.sports_bar_rounded,
    AchievementCategory.occasions => Icons.celebration_rounded,
    AchievementCategory.places => Icons.home_rounded,
    AchievementCategory.travel => Icons.flight_takeoff_rounded,
    AchievementCategory.countries => Icons.public_rounded,
  };
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.data, required this.onTap});

  final _FamilyCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final family = data.family;
    final progress = data.progress;
    final isLocked = progress.earnedLevels.isEmpty;

    final String statusText;
    if (progress.setupRequired) {
      statusText = l10n.achievementsSetupRequired;
    } else if (family.kind == AchievementKind.ladder) {
      statusText = progress.isCompleted
          ? l10n.achievementsCompleted
          : '${progress.earnedLevels.length}/${family.levels.length}';
    } else {
      statusText = progress.earnedLevels.isNotEmpty
          ? l10n.achievementsUnlocked
          : l10n.achievementsLocked;
    }

    return Card(
      elevation: 0,
      color: isLocked
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                _categoryIcon(family.category),
                size: 32,
                color: isLocked
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : theme.colorScheme.onPrimaryContainer,
              ),
              const Spacer(),
              Text(
                resolveAchievementString(l10n, family.familyTitleKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              if (family.kind == AchievementKind.ladder && !progress.setupRequired)
                LinearProgressIndicator(
                  value: family.levels.isEmpty
                      ? 0
                      : progress.earnedLevels.length / family.levels.length,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
              const SizedBox(height: 4),
              Text(statusText, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementDetailOverlay extends StatelessWidget {
  const _AchievementDetailOverlay({required this.target, required this.onClose});

  final AchievementDeepLinkTarget target;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final family = achievementFamilyById(target.familyId);
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);

    if (family == null) {
      return const SizedBox.shrink();
    }

    final progress = controller.achievementProgress.firstWhere(
      (p) => p.familyId == family.familyId,
      orElse: () => AchievementFamilyProgress(
        familyId: family.familyId,
        currentValue: 0,
        earnedLevels: const <int>{},
      ),
    );
    final earnedUnlocks = <int, AchievementUnlock>{
      for (final u in controller.achievementUnlocks)
        if (u.familyId == family.familyId) u.level: u,
    };

    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.82,
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              resolveAchievementString(l10n, family.familyTitleKey),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (controller.isAchievementFamilyEarnableToday(family))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(l10n.achievementsEarnableToday),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: theme.colorScheme.tertiaryContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: <Widget>[
                          if (progress.setupRequired)
                            _SetupRequiredCard(family: family, onClose: onClose),
                          for (final level in family.levels)
                            _DetailLevelTile(
                              family: family,
                              level: level,
                              earned: earnedUnlocks[level.level],
                              isNextTarget: progress.nextLevel == level.level,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupRequiredCard extends StatelessWidget {
  const _SetupRequiredCard({required this.family, required this.onClose});

  final AchievementFamily family;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline_rounded),
        title: Text(l10n.achievementsSetupRequired),
        trailing: FilledButton(
          onPressed: () {
            onClose();
            final route = family.familyId == AchievementFamilyIds.occasionBirthday
                ? AppRoutes.editProfile
                : AppRoutes.places;
            Navigator.of(context).pushNamed(route);
          },
          child: Text(l10n.achievementsSetUpNow),
        ),
      ),
    );
  }
}

class _DetailLevelTile extends StatelessWidget {
  const _DetailLevelTile({
    required this.family,
    required this.level,
    required this.earned,
    required this.isNextTarget,
  });

  final AchievementFamily family;
  final AchievementLevelDef level;
  final AchievementUnlock? earned;
  final bool isNextTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEarned = earned != null;

    String? trailingText;
    if (isEarned) {
      trailingText = DateFormat.yMMMd(l10n.localeName).format(earned!.grantedAt);
    } else if (family.kind != AchievementKind.ladder) {
      final window = nextEligibleWindow(familyId: family.familyId, now: DateTime.now());
      if (window != null) {
        final formatter = DateFormat.MMMd(l10n.localeName);
        trailingText = window.$1 == window.$2
            ? formatter.format(window.$1)
            : '${formatter.format(window.$1)} - ${formatter.format(window.$2)}';
      }
    }

    return ListTile(
      leading: Icon(
        isEarned ? Icons.emoji_events_rounded : Icons.emoji_events_outlined,
        color: isEarned ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(
        resolveAchievementString(l10n, level.titleKey),
        style: TextStyle(fontWeight: isNextTarget ? FontWeight.w700 : FontWeight.w500),
      ),
      subtitle: Text(resolveAchievementString(l10n, level.descriptionKey)),
      trailing: trailingText == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (!isEarned)
                  Text(l10n.achievementsNextEligible, style: theme.textTheme.labelSmall),
                Text(trailingText, style: theme.textTheme.labelSmall),
              ],
            ),
    );
  }
}
