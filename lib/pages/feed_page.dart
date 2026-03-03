import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/models/app_models.dart';
import 'package:glasstrail/state/app_controller.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({required this.controller, super.key});

  final AppController controller;

  Future<void> _openCommentDialog(BuildContext context, DrinkLog log) async {
    final textController = TextEditingController();
    final l10n = context.l10n;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.comment),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: l10n.addCommentHint),
            maxLines: 3,
            minLines: 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.postComment),
            ),
          ],
        );
      },
    );

    if (submitted == true && context.mounted) {
      controller.addComment(log.id, textController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.comment)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feedItems = controller.feed;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshFeed,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(l10n.feedTitle),
            ),
            if (feedItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.feedEmptyTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.feedEmptyBody,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => controller.refreshFeed(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                sliver: SliverList.builder(
                  itemCount: feedItems.length,
                  itemBuilder: (context, index) {
                    final item = feedItems[index];
                    if (item.type == FeedEventType.badgesUnlocked) {
                      return _BadgeFeedCard(item: item);
                    }
                    return _DrinkFeedCard(
                      item: item,
                      controller: controller,
                      onCommentTap: () =>
                          _openCommentDialog(context, item.log!),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrinkFeedCard extends StatelessWidget {
  const _DrinkFeedCard({
    required this.item,
    required this.controller,
    required this.onCommentTap,
  });

  final FeedItem item;
  final AppController controller;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final log = item.log!;
    final formatter = DateFormat.yMMMd(controller.locale.languageCode).add_Hm();
    final hasImage = log.imageUrl != null && log.imageUrl!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: _imageProvider(log.userAvatarUrl),
              ),
              title: Text(log.userName),
              subtitle: Text(formatter.format(log.loggedAt)),
              trailing: Text(
                log.drinkName,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(log.category.defaultLabel)),
                if (log.taggedFriends.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.groups, size: 18),
                    label: Text(l10n.withFriends),
                  ),
              ],
            ),
            if (log.comment != null) ...[
              const SizedBox(height: 8),
              Text(log.comment!),
            ],
            if (hasImage) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _FeedImage(image: log.imageUrl!),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => controller.toggleCheer(log.id),
                  icon: Icon(
                    controller.hasCheered(log.id)
                        ? Icons.celebration
                        : Icons.celebration_outlined,
                  ),
                  tooltip: l10n.cheer,
                ),
                Text('${log.cheersCount}'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onCommentTap,
                  icon: const Icon(Icons.mode_comment_outlined),
                  tooltip: l10n.comment,
                ),
                Text('${log.commentCount}'),
              ],
            ),
          ],
        ),
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

class _FeedImage extends StatelessWidget {
  const _FeedImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(image, fit: BoxFit.cover);
    }
    return Image.file(File(image), fit: BoxFit.cover);
  }
}

class _BadgeFeedCard extends StatelessWidget {
  const _BadgeFeedCard({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.workspace_premium)),
              title: Text(l10n.badgeUnlocked),
              subtitle: Text(
                DateFormat.yMMMd().add_Hm().format(item.createdAt),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.badges
                  .map(
                    (badge) => Chip(
                      avatar: const Icon(Icons.emoji_events, size: 16),
                      label: Text(badge.name),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
