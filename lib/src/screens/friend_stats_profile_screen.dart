import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

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
