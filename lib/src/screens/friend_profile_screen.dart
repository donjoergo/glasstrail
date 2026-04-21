import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_controller.dart';
import '../app_routes.dart';
import '../app_scope.dart';
import '../models.dart';
import '../widgets/app_media.dart';

const double _friendProfileAvatarRadius = 72;

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  Future<_VisibleFriendProfile?>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.controllerOf(context);
    _profileFuture ??= Future<_VisibleFriendProfile?>.delayed(
      Duration.zero,
      () async {
        if (controller.isAuthenticated) {
          final profile = await controller.resolveFriendProfileLink(
            widget.shareCode,
          );
          return profile == null
              ? null
              : _VisibleFriendProfile.fromFriendProfile(profile);
        }
        final profile = await controller.resolvePublicFriendProfileLink(
          widget.shareCode,
        );
        return profile == null
            ? null
            : _VisibleFriendProfile.fromPublicFriendProfile(profile);
      },
    );
  }

  Future<void> _sendFriendRequest(_VisibleFriendProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await controller.sendFriendRequestToProfile(
      profile.profileShareCode ?? widget.shareCode,
    );
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (success) {
      setState(() {});
    }
  }

  Future<void> _cancelFriendRequest(FriendConnection connection) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await controller.cancelFriendRequest(connection);
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (success) {
      setState(() {});
    }
  }

  void _signIn() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.auth,
      arguments: AppRoutes.friendProfileRoute(widget.shareCode),
    );
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
    final isAuthenticated = controller.isAuthenticated;

    return Scaffold(
      key: const Key('friend-profile-link-screen'),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FutureBuilder<_VisibleFriendProfile?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          key: Key('friend-profile-loading'),
                        ),
                      );
                    }

                    final profile = snapshot.data;
                    if (profile == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showControllerMessage();
                      });
                      return _FriendProfileMessageCard(
                        icon: Icons.link_off_rounded,
                        title: l10n.friendProfileLinkInvalidTitle,
                        body: l10n.friendProfileLinkInvalidBody,
                        actionLabel: isAuthenticated
                            ? l10n.profile
                            : l10n.signIn,
                        onAction: isAuthenticated
                            ? () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.profile);
                              }
                            : _signIn,
                      );
                    }

                    return _FriendProfileCard(
                      profile: profile,
                      isAuthenticated: isAuthenticated,
                      onAddFriend: () => _sendFriendRequest(profile),
                      onCancelFriendRequest: _cancelFriendRequest,
                      onSignIn: _signIn,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibleFriendProfile {
  const _VisibleFriendProfile({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.isPublic,
    this.profileImagePath,
    this.profileShareCode,
  });

  factory _VisibleFriendProfile.fromFriendProfile(FriendProfile profile) {
    return _VisibleFriendProfile(
      id: profile.id,
      displayName: profile.displayName,
      initials: profile.initials,
      profileImagePath: profile.profileImagePath,
      profileShareCode: profile.profileShareCode,
      isPublic: false,
    );
  }

  factory _VisibleFriendProfile.fromPublicFriendProfile(
    PublicFriendProfile profile,
  ) {
    return _VisibleFriendProfile(
      id: profile.id,
      displayName: profile.displayName,
      initials: profile.initials,
      profileImagePath: profile.profileImagePath,
      profileShareCode: profile.profileShareCode,
      isPublic: true,
    );
  }

  final String id;
  final String displayName;
  final String initials;
  final String? profileImagePath;
  final String? profileShareCode;
  final bool isPublic;
}

class _FriendProfileCard extends StatelessWidget {
  const _FriendProfileCard({
    required this.profile,
    required this.isAuthenticated,
    required this.onAddFriend,
    required this.onCancelFriendRequest,
    required this.onSignIn,
  });

  final _VisibleFriendProfile profile;
  final bool isAuthenticated;
  final VoidCallback onAddFriend;
  final ValueChanged<FriendConnection> onCancelFriendRequest;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final currentUser = controller.currentUser;
    final connection = isAuthenticated
        ? controller.friendConnections.where(
            (candidate) => candidate.profile.id == profile.id,
          )
        : const Iterable<FriendConnection>.empty();
    final existingConnection = connection.isEmpty ? null : connection.single;
    final isSelf = isAuthenticated && currentUser?.id == profile.id;
    final isBusy = controller.isBusy;
    final status = _statusLabel(
      l10n: l10n,
      isAuthenticated: isAuthenticated,
      isSelf: isSelf,
      connection: existingConnection,
    );
    final canAdd = isAuthenticated && !isSelf && existingConnection == null;
    final canCancel =
        isAuthenticated &&
        existingConnection?.isPending == true &&
        existingConnection?.isOutgoing == true;

    return Container(
      key: const Key('friend-profile-card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppAvatar(
            key: const Key('friend-profile-avatar'),
            imagePath: profile.profileImagePath,
            radius: _friendProfileAvatarRadius,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            fallback: Text(
              profile.initials,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            key: const Key('friend-profile-display-name'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            key: const Key('friend-profile-status'),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (isAuthenticated && canCancel && existingConnection != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('friend-profile-cancel-button'),
                onPressed: isBusy
                    ? null
                    : () => onCancelFriendRequest(existingConnection),
                icon:
                    isBusy &&
                        controller.isBusyFor(AppBusyAction.cancelFriendRequest)
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.undo_rounded),
                label: Text(l10n.withdrawFriendRequest),
              ),
            )
          else if (isAuthenticated)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('friend-profile-add-button'),
                onPressed: canAdd && !isBusy ? onAddFriend : null,
                icon:
                    isBusy &&
                        controller.isBusyFor(AppBusyAction.sendFriendRequest)
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(l10n.addAsFriend),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('friend-profile-sign-in-button'),
                onPressed: onSignIn,
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n.signIn),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel({
    required AppLocalizations l10n,
    required bool isAuthenticated,
    required bool isSelf,
    required FriendConnection? connection,
  }) {
    if (!isAuthenticated) {
      return l10n.friendProfilePublicPrompt(profile.displayName);
    }
    if (isSelf) {
      return l10n.friendProfileSelf;
    }
    if (connection == null) {
      return l10n.friendProfileRequestPrompt(profile.displayName);
    }
    if (connection.isAccepted) {
      return l10n.friendAlreadyFriends;
    }
    if (connection.isIncoming) {
      return l10n.friendIncomingRequestFromProfile;
    }
    return l10n.friendRequestPending;
  }
}

class _FriendProfileMessageCard extends StatelessWidget {
  const _FriendProfileMessageCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('friend-profile-message-card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary, size: 38),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
