import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/models/app_models.dart';
import 'package:glasstrail/state/app_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 16, bottom: 16),
              title: Text(controller.currentUser.displayName),
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 90, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          _imageProvider(controller.currentUser.avatarUrl),
                    ),
                    const SizedBox(height: 10),
                    Text('@${controller.currentUser.nickname}'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {},
                      child: Text(l10n.editProfile),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.badges,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: controller.badges
                                .map(
                                  (badge) => Chip(
                                    avatar: const Icon(
                                      Icons.workspace_premium,
                                      size: 16,
                                    ),
                                    label: Text(badge.name),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.friendsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            itemCount: controller.friends.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final friend = controller.friends[index];
                              return _FriendTile(
                                friend: friend,
                                controller: controller,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(l10n.friendDrinkNotifications),
                          value: controller.friendDrinkNotifications,
                          onChanged: controller.setFriendDrinkNotifications,
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: Text(l10n.settings),
                          onTap: () => context.push('/settings'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: Text(l10n.logout),
                          onTap: () {
                            controller.logOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.controller});

  final Friend friend;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl)),
      title: Text(friend.name),
      subtitle: friend.status == FriendshipStatus.accepted
          ? null
          : Text(l10n.pendingRequest),
      trailing: switch (friend.status) {
        FriendshipStatus.accepted => IconButton(
            onPressed: () => controller.removeFriend(friend.id),
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: l10n.remove,
          ),
        FriendshipStatus.incomingRequest => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => controller.acceptFriendRequest(friend.id),
                icon: const Icon(Icons.check),
                tooltip: l10n.accept,
              ),
              IconButton(
                onPressed: () => controller.rejectFriendRequest(friend.id),
                icon: const Icon(Icons.close),
                tooltip: l10n.reject,
              ),
            ],
          ),
        FriendshipStatus.outgoingRequest => TextButton(
            onPressed: () => controller.rejectFriendRequest(friend.id),
            child: Text(l10n.cancel),
          ),
      },
    );
  }
}
