import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../app_routes.dart';
import '../app_scope.dart';
import '../models.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_media.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _openNotification(AppNotification notification) async {
    final controller = AppScope.controllerOf(context);
    if (notification.isUnread) {
      await controller.markNotificationsRead(<String>[notification.id]);
    }
    await controller.refreshData();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
  }

  Future<void> _markAllAsRead() async {
    final controller = AppScope.controllerOf(context);
    await controller.markAllNotificationsRead();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final notifications = controller.notifications;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasUnread = notifications.any((n) => n.isUnread);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: l10n.notificationsMarkAllRead,
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AppEmptyStateCard(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.notificationsEmptyTitle,
                      body: l10n.notificationsEmptyBody,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                key: const Key('notifications-list'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    key: Key('notification-${notification.id}'),
                    notification: notification,
                    dateLabel: DateFormat.yMMMd(
                      l10n.localeName,
                    ).add_Hm().format(notification.createdAt),
                    onTap: () => _openNotification(notification),
                  );
                },
              ),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.dateLabel,
    required this.onTap,
  });

  final AppNotification notification;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unread = notification.isUnread;

    return Material(
      color: unread
          ? colorScheme.primaryContainer.withValues(alpha: 0.36)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppAvatar(
                imagePath: notification.actorProfileImagePath,
                radius: 22,
                fallback: Text(
                  notification.actorInitials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _title(l10n),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _body(l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  key: Key('notification-unread-${notification.id}'),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    final name = notification.actorDisplayName;
    return switch (notification.type) {
      AppNotificationType.friendRequestSent =>
        l10n.notificationFriendRequestSentTitle(name),
      AppNotificationType.friendRequestAccepted =>
        l10n.notificationFriendRequestAcceptedTitle(name),
      AppNotificationType.friendRequestRejected =>
        l10n.notificationFriendRequestRejectedTitle(name),
      AppNotificationType.friendRemoved => l10n.notificationFriendRemovedTitle(
        name,
      ),
    };
  }

  String _body(AppLocalizations l10n) {
    return switch (notification.type) {
      AppNotificationType.friendRequestSent =>
        l10n.notificationFriendRequestSentBody,
      AppNotificationType.friendRequestAccepted =>
        l10n.notificationFriendRequestAcceptedBody,
      AppNotificationType.friendRequestRejected =>
        l10n.notificationFriendRequestRejectedBody,
      AppNotificationType.friendRemoved => l10n.notificationFriendRemovedBody,
    };
  }
}
