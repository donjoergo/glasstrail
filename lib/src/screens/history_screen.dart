import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _refresh() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await controller.refreshData();
    if (!mounted || success) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final entries = controller.entries;
    final locale = controller.settings.localeCode;

    return RefreshIndicator(
      key: const Key('history-refresh-indicator'),
      onRefresh: _refresh,
      child: ListView(
        key: const Key('history-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: <Color>[
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  theme.colorScheme.tertiary.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.feedHeadline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.feedBody),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _MetricBadge(
                      label: l10n.totalDrinks,
                      value: '${entries.length}',
                      valueKey: const Key('history-total-drinks-value'),
                    ),
                    _MetricBadge(
                      label: l10n.currentStreak,
                      value:
                          '${controller.statistics.currentStreak} ${l10n.dayLabel(controller.statistics.currentStreak)}',
                      valueKey: const Key('history-current-streak-value'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 42,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noEntries,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.startLogging),
                ],
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DrinkEntryCard(
                  entry: entry,
                  drinkName: controller.localizedEntryDrinkName(entry),
                  locale: locale,
                  unit: controller.settings.unit,
                  categoryLabel: l10n.categoryLabel(entry.category),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value, this.valueKey});

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            key: valueKey,
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _DrinkEntryAction { edit, delete }

class _DrinkEntryCard extends StatelessWidget {
  const _DrinkEntryCard({
    required this.entry,
    required this.drinkName,
    required this.locale,
    required this.unit,
    required this.categoryLabel,
  });

  final DrinkEntry entry;
  final String drinkName;
  final String locale;
  final AppUnit unit;
  final String categoryLabel;

  Future<void> _handleAction(
    BuildContext context,
    _DrinkEntryAction action,
  ) async {
    if (action == _DrinkEntryAction.edit) {
      await _openEditDialog(context);
      return;
    }
    await _confirmDelete(context);
  }

  Future<void> _openEditDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditDrinkEntryDialog(
        entry: entry,
        drinkName: drinkName,
        categoryLabel: categoryLabel,
        locale: locale,
        unit: unit,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteEntryPrompt),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('delete-entry-confirm-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteEntry),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await controller.deleteDrinkEntry(entry);
    if (!context.mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (!success) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(entry.consumedAt);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                foregroundColor: theme.colorScheme.primary,
                child: Icon(entry.category.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      drinkName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$categoryLabel • $timeLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.volumeMl != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(unit.formatVolume(entry.volumeMl)),
                ),
              PopupMenuButton<_DrinkEntryAction>(
                key: Key('history-entry-actions-${entry.id}'),
                onSelected: (action) {
                  _handleAction(context, action);
                },
                itemBuilder: (context) => <PopupMenuEntry<_DrinkEntryAction>>[
                  PopupMenuItem<_DrinkEntryAction>(
                    key: Key('history-entry-edit-${entry.id}'),
                    value: _DrinkEntryAction.edit,
                    child: Text(AppLocalizations.of(context).editEntry),
                  ),
                  PopupMenuItem<_DrinkEntryAction>(
                    key: Key('history-entry-delete-${entry.id}'),
                    value: _DrinkEntryAction.delete,
                    child: Text(AppLocalizations.of(context).deleteEntry),
                  ),
                ],
              ),
            ],
          ),
          if (entry.comment != null && entry.comment!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(entry.comment!),
          ],
          if (entry.imagePath != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.image_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.imagePath!.split(RegExp(r'[\\/]')).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditDrinkEntryDialog extends StatefulWidget {
  const _EditDrinkEntryDialog({
    required this.entry,
    required this.drinkName,
    required this.categoryLabel,
    required this.locale,
    required this.unit,
  });

  final DrinkEntry entry;
  final String drinkName;
  final String categoryLabel;
  final String locale;
  final AppUnit unit;

  @override
  State<_EditDrinkEntryDialog> createState() => _EditDrinkEntryDialogState();
}

class _EditDrinkEntryDialogState extends State<_EditDrinkEntryDialog> {
  late final TextEditingController _commentController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.entry.comment ?? '',
    );
    _imagePath = widget.entry.imagePath;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await AppScope.photoServiceOf(context).pickImage();
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _imagePath = path;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await controller.updateDrinkEntry(
      entry: widget.entry,
      comment: _commentController.text,
      imagePath: _imagePath,
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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final timeLabel = DateFormat.yMMMd(
      widget.locale,
    ).add_Hm().format(widget.entry.consumedAt);

    return AlertDialog(
      title: Text(l10n.editEntry),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.drinkName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.categoryLabel} • $timeLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.entry.volumeMl != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.unit.formatVolume(widget.entry.volumeMl),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('edit-entry-comment-field'),
                controller: _commentController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '${l10n.comment} (${l10n.optional})',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  FilledButton.tonalIcon(
                    key: const Key('edit-entry-pick-photo-button'),
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _imagePath == null ? l10n.pickPhoto : l10n.changePhoto,
                    ),
                  ),
                  if (_imagePath != null) ...<Widget>[
                    const SizedBox(width: 12),
                    IconButton(
                      key: const Key('edit-entry-remove-photo-button'),
                      onPressed: () {
                        setState(() {
                          _imagePath = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.removePhoto,
                    ),
                  ],
                ],
              ),
              if (_imagePath != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _imagePath!.split(RegExp(r'[\\/]')).last,
                    key: const Key('edit-entry-image-name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('edit-entry-save-button'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
