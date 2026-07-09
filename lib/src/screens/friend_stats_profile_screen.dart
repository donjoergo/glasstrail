import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../achievements/achievement_localizations.dart';
import '../achievements/catalog.dart';
import '../achievements/repository_models.dart';
import '../app_scope.dart';
import '../friend_stats_profile.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_media.dart';
import '../widgets/statistics_overview_content.dart';

const double _friendStatsProfileAvatarRadius = 54;

class FriendStatsProfileScreen extends StatefulWidget {
  const FriendStatsProfileScreen({super.key, required this.friendUserId});

  final String friendUserId;

  @override
  State<FriendStatsProfileScreen> createState() =>
      _FriendStatsProfileScreenState();
}

class _FriendStatsProfileScreenState extends State<FriendStatsProfileScreen> {
  Future<FriendStatsProfile?>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileFuture ??= Future<FriendStatsProfile?>.delayed(
      Duration.zero,
      _loadProfile,
    );
  }

  Future<FriendStatsProfile?> _loadProfile() {
    return AppScope.controllerOf(
      context,
    ).loadFriendStatsProfile(widget.friendUserId);
  }

  Future<void> _refreshProfile() async {
    final future = _loadProfile();
    setState(() {
      _profileFuture = future;
    });
    await future;
  }

  void _showControllerMessage() {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final message = controller.takeFlashMessage(l10n);
    if (message == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = AppScope.controllerOf(context);

    return Scaffold(
      key: const Key('friend-stats-profile-screen'),
      appBar: AppBar(title: Text(l10n.friendProfile)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.primary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<FriendStatsProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  key: Key('friend-stats-profile-loading'),
                ),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showControllerMessage();
              });
              return ListView(
                key: const Key('friend-stats-profile-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: <Widget>[
                  AppEmptyStateCard(
                    key: const Key('friend-stats-profile-unavailable'),
                    icon: Icons.person_off_rounded,
                    title: l10n.friendStatsUnavailableTitle,
                    body: l10n.friendStatsUnavailableBody,
                  ),
                ],
              );
            }

            return RefreshIndicator(
              key: const Key('friend-stats-profile-refresh-indicator'),
              onRefresh: _refreshProfile,
              child: ListView(
                key: const Key('friend-stats-profile-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: <Widget>[
                  _FriendStatsProfileHeader(profile: profile),
                  const SizedBox(height: 20),
                  if (!profile.shareStatsWithFriends ||
                      profile.statistics == null)
                    AppEmptyStateCard(
                      key: const Key('friend-stats-profile-not-shared'),
                      icon: Icons.visibility_off_rounded,
                      title: l10n.friendStatsNotSharedTitle,
                      body: l10n.friendStatsNotSharedBody(profile.displayName),
                    )
                  else
                    StatisticsOverviewContent(
                      stats: profile.statistics!,
                      localeCode: controller.settings.localeCode,
                    ),
                  const SizedBox(height: 20),
                  _FriendSharedAchievementsSection(friendUserId: widget.friendUserId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FriendStatsProfileHeader extends StatelessWidget {
  const _FriendStatsProfileHeader({required this.profile});

  final FriendStatsProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('friend-stats-profile-header'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          AppAvatar(
            key: const Key('friend-stats-profile-avatar'),
            imagePath: profile.profileImagePath,
            radius: _friendStatsProfileAvatarRadius,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            fallback: Text(
              profile.initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.displayName,
                  key: const Key('friend-stats-profile-display-name'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.statistics,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Friend-shared achievements, lazy-loaded only once this section is
/// opened. `loadFriendSharedAchievements` already gates on the target's
/// `shareAchievements` flag server-side, so an empty/null result (not
/// shared, or shared with nothing earned yet) simply renders nothing.
class _FriendSharedAchievementsSection extends StatefulWidget {
  const _FriendSharedAchievementsSection({required this.friendUserId});

  final String friendUserId;

  @override
  State<_FriendSharedAchievementsSection> createState() =>
      _FriendSharedAchievementsSectionState();
}

class _FriendSharedAchievementsSectionState
    extends State<_FriendSharedAchievementsSection> {
  Future<List<FriendSharedAchievementFamily>>? _future;

  void _open() {
    setState(() {
      _future ??= AppScope.controllerOf(
        context,
      ).loadFriendSharedAchievements(widget.friendUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_future == null) {
      return Material(
        key: const Key('friend-achievements-open-button'),
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: _open,
          leading: const Icon(Icons.emoji_events_outlined),
          title: Text(l10n.achievementsTab),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
    }

    return FutureBuilder<List<FriendSharedAchievementFamily>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('friend-achievements-loading'),
              ),
            ),
          );
        }

        final families = snapshot.data ?? const <FriendSharedAchievementFamily>[];
        if (families.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          key: const Key('friend-achievements-section'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.achievementsTab,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final family in families) _FriendAchievementFamilyRow(family: family),
            ],
          ),
        );
      },
    );
  }
}

class _FriendAchievementFamilyRow extends StatelessWidget {
  const _FriendAchievementFamilyRow({required this.family});

  final FriendSharedAchievementFamily family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalogFamily = achievementFamilyById(family.familyId);
    if (catalogFamily == null) {
      return const SizedBox.shrink();
    }

    final earnedTitles = family.earnedLevels
        .map((level) {
          final def = catalogFamily.levels.where((l) => l.level == level).cast<AchievementLevelDef?>().firstWhere(
                (_) => true,
                orElse: () => null,
              );
          return def == null ? null : resolveAchievementString(l10n, def.titleKey);
        })
        .whereType<String>()
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  resolveAchievementString(l10n, catalogFamily.familyTitleKey),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  earnedTitles.join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
