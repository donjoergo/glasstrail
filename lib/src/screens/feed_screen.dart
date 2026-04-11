import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../models.dart';
import '../photo_pick_flow.dart';
import '../photo_service.dart';
import '../stats_calculator.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_media.dart';

@visibleForTesting
bool debugForceUpdateNotice = const bool.fromEnvironment(
  'FORCE_UPDATE_NOTICE',
  defaultValue: false,
);

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const _lastAcknowledgedReleaseKey =
      'glasstrail.last_acknowledged_release';
  static final Uri _changelogUri = Uri.parse(
    'https://github.com/donjoergo/glasstrail/blob/main/CHANGELOG.md',
  );

  _UpdateNoticeData? _updateNotice;
  bool _isHandlingUpdateNotice = false;

  LaunchMode get _changelogLaunchMode {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS => LaunchMode.inAppBrowserView,
      _ => LaunchMode.externalApplication,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadUpdateNotice();
  }

  Future<void> _loadUpdateNotice() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();
      if (version.isEmpty) {
        return;
      }

      final releaseId = buildNumber.isEmpty ? version : '$version+$buildNumber';
      final preferences = await SharedPreferences.getInstance();
      if (debugForceUpdateNotice) {
        if (!mounted) {
          return;
        }
        setState(() {
          _updateNotice = _UpdateNoticeData(
            releaseId: releaseId,
            version: version,
          );
        });
        return;
      }
      final lastAcknowledgedRelease = preferences.getString(
        _lastAcknowledgedReleaseKey,
      );
      if (lastAcknowledgedRelease == null) {
        await preferences.setString(_lastAcknowledgedReleaseKey, releaseId);
        return;
      }
      if (lastAcknowledgedRelease == releaseId || !mounted) {
        return;
      }

      setState(() {
        _updateNotice = _UpdateNoticeData(
          releaseId: releaseId,
          version: version,
        );
      });
    } catch (_) {}
  }

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

  Future<void> _acknowledgeUpdateNotice({required bool openChangelog}) async {
    final notice = _updateNotice;
    if (notice == null || _isHandlingUpdateNotice) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    var shouldDismiss = false;
    setState(() {
      _isHandlingUpdateNotice = true;
    });

    try {
      if (openChangelog) {
        final launched = await launchUrl(
          _changelogUri,
          mode: _changelogLaunchMode,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
        if (!launched) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
          }
          return;
        }
      }

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _lastAcknowledgedReleaseKey,
        notice.releaseId,
      );
      shouldDismiss = true;
    } catch (_) {
      if (openChangelog && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHandlingUpdateNotice = false;
          if (shouldDismiss) {
            _updateNotice = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final entries = controller.entries;
    final stats = controller.statistics;
    final locale = controller.settings.localeCode;

    return RefreshIndicator(
      key: const Key('feed-refresh-indicator'),
      onRefresh: _refresh,
      child: ListView(
        key: const Key('feed-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: <Widget>[
          if (_updateNotice case final notice?) ...<Widget>[
            _FeedUpdateCard(
              version: notice.version,
              isBusy: _isHandlingUpdateNotice,
              onClose: () => _acknowledgeUpdateNotice(openChangelog: false),
              onOpenChangelog: () =>
                  _acknowledgeUpdateNotice(openChangelog: true),
            ),
            const SizedBox(height: 24),
          ],
          _FeedStreakCard(stats: stats),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            AppEmptyStateCard(
              key: const Key('feed-empty-state'),
              icon: Icons.hourglass_empty_rounded,
              title: l10n.noEntries,
              body: l10n.startLogging,
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

class _UpdateNoticeData {
  const _UpdateNoticeData({required this.releaseId, required this.version});

  final String releaseId;
  final String version;
}

class _FeedUpdateCard extends StatelessWidget {
  const _FeedUpdateCard({
    required this.version,
    required this.isBusy,
    required this.onClose,
    required this.onOpenChangelog,
  });

  final String version;
  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback onOpenChangelog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('feed-update-card'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.appUpdatedTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.appUpdatedBody(l10n.appTitle, version),
            key: const Key('feed-update-card-body'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 12,
            overflowSpacing: 12,
            children: <Widget>[
              TextButton(
                key: const Key('feed-update-card-close-button'),
                onPressed: isBusy ? null : onClose,
                child: Text(l10n.close),
              ),
              FilledButton(
                key: const Key('feed-update-card-whats-new-button'),
                onPressed: isBusy ? null : onOpenChangelog,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(l10n.whatsNew),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedStreakCard extends StatelessWidget {
  const _FeedStreakCard({required this.stats});

  final AppStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final streakValue =
        '${stats.currentStreak} ${l10n.dayLabel(stats.currentStreak)}';
    final accentColors = _accentColors(theme);

    return Container(
      key: const Key('feed-streak-card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColors.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: accentColors.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.currentStreak,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                key: const Key('feed-streak-current-value'),
                streakValue,
                textAlign: TextAlign.right,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.thisWeek,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: stats.weekProgress
                .map((day) => Expanded(child: _WeekProgressIndicator(day: day)))
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text(
            key: const Key('feed-streak-message'),
            _streakMessage(l10n, stats),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: accentColors.messageColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StreakAccentColors _accentColors(ThemeData theme) {
    final scheme = theme.colorScheme;
    final warningForeground = theme.brightness == Brightness.dark
        ? scheme.tertiary
        : const Color(0xFF8A5A00);
    final startedForeground = theme.brightness == Brightness.dark
        ? scheme.secondary
        : const Color(0xFF2F6F6D);
    return switch (stats.streakMessageState) {
      StreakMessageState.start => _StreakAccentColors(
        iconColor: scheme.onSurfaceVariant,
        iconBackgroundColor: scheme.surfaceContainerHighest,
        messageColor: scheme.onSurfaceVariant,
      ),
      StreakMessageState.keepAlive => _StreakAccentColors(
        iconColor: warningForeground,
        iconBackgroundColor: scheme.tertiary.withValues(alpha: 0.18),
        messageColor: warningForeground,
      ),
      StreakMessageState.startedToday => _StreakAccentColors(
        iconColor: startedForeground,
        iconBackgroundColor: scheme.secondary.withValues(alpha: 0.16),
        messageColor: startedForeground,
      ),
      StreakMessageState.continuedToday => _StreakAccentColors(
        iconColor: scheme.primary,
        iconBackgroundColor: scheme.primary.withValues(alpha: 0.16),
        messageColor: scheme.primary,
      ),
    };
  }

  String _streakMessage(AppLocalizations l10n, AppStatistics stats) {
    return switch (stats.streakMessageState) {
      StreakMessageState.start => l10n.streakPromptStart,
      StreakMessageState.keepAlive => l10n.streakPromptKeepAlive,
      StreakMessageState.startedToday => l10n.streakPromptStartedToday,
      StreakMessageState.continuedToday => l10n.streakPromptContinuedToday,
    };
  }
}

class _StreakAccentColors {
  const _StreakAccentColors({
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.messageColor,
  });

  final Color iconColor;
  final Color iconBackgroundColor;
  final Color messageColor;
}

class _WeekProgressIndicator extends StatelessWidget {
  const _WeekProgressIndicator({required this.day});

  final WeekProgressDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasEntry = day.hasEntry;
    final circleColor = hasEntry
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final iconColor = hasEntry
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final labelColor = hasEntry
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      key: Key('feed-streak-day-${day.weekday}'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: day.isToday
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            hasEntry ? Icons.check_rounded : Icons.circle,
            size: hasEntry ? 22 : 12,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.weekdayShortLabel(day.weekday),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ],
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
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _DeleteDrinkEntryDialog(entry: entry, parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.controllerOf(context);
    final timeLabel = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(entry.consumedAt);
    final locationAddress = _normalizedLocationAddress(entry.locationAddress);
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
                    if (locationAddress != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.location_on_outlined,
                            key: Key('feed-entry-location-icon-${entry.id}'),
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationAddress,
                              key: Key('feed-entry-location-${entry.id}'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                key: Key('feed-entry-actions-${entry.id}'),
                enabled: !controller.isBusy,
                onSelected: (action) {
                  _handleAction(context, action);
                },
                itemBuilder: (context) => <PopupMenuEntry<_DrinkEntryAction>>[
                  PopupMenuItem<_DrinkEntryAction>(
                    key: Key('feed-entry-edit-${entry.id}'),
                    value: _DrinkEntryAction.edit,
                    child: Text(AppLocalizations.of(context).editEntry),
                  ),
                  PopupMenuItem<_DrinkEntryAction>(
                    key: Key('feed-entry-delete-${entry.id}'),
                    value: _DrinkEntryAction.delete,
                    child: Text(
                      AppLocalizations.of(context).deleteEntry,
                      style: AppTheme.destructiveMenuTextStyle(theme),
                    ),
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
            AppPhotoPreview(
              key: Key('feed-entry-image-${entry.id}'),
              imagePath: entry.imagePath,
              cropPortraitToSquare: true,
              enableFullscreenOnTap: true,
            ),
          ],
        ],
      ),
    );
  }

  String? _normalizedLocationAddress(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
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
    final path = await pickImageForUpload(
      context,
      preset: ImageUploadPreset.feed,
    );
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
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final isBusy = controller.isBusy;
    final isSavingEntry = controller.isBusyFor(AppBusyAction.updateDrinkEntry);
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
                enabled: !isBusy,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '${l10n.comment} (${l10n.optional})',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    key: const Key('edit-entry-pick-photo-button'),
                    onPressed: isBusy ? null : _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _imagePath == null ? l10n.pickPhoto : l10n.changePhoto,
                    ),
                  ),
                  if (_imagePath != null)
                    OutlinedButton.icon(
                      key: const Key('edit-entry-remove-photo-button'),
                      style: AppTheme.destructiveOutlinedButtonStyle(
                        theme.colorScheme,
                      ),
                      onPressed: isBusy
                          ? null
                          : () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n.removePhoto),
                    ),
                ],
              ),
              if (_imagePath != null) ...<Widget>[
                const SizedBox(height: 12),
                AppPhotoPreview(
                  key: const Key('edit-entry-image-preview'),
                  imagePath: _imagePath,
                  cropPortraitToSquare: true,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('edit-entry-cancel-button'),
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('edit-entry-save-button'),
          onPressed: isBusy ? null : _save,
          child: isSavingEntry
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

class _DeleteDrinkEntryDialog extends StatefulWidget {
  const _DeleteDrinkEntryDialog({
    required this.entry,
    required this.parentContext,
  });

  final DrinkEntry entry;
  final BuildContext parentContext;

  @override
  State<_DeleteDrinkEntryDialog> createState() =>
      _DeleteDrinkEntryDialogState();
}

class _DeleteDrinkEntryDialogState extends State<_DeleteDrinkEntryDialog> {
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await controller.deleteDrinkEntry(widget.entry);
    final message = controller.takeFlashMessage(l10n);
    if (message != null && widget.parentContext.mounted) {
      ScaffoldMessenger.of(
        widget.parentContext,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (!mounted || !success) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final isBusy = controller.isBusy;
    final isDeleting = controller.isBusyFor(AppBusyAction.deleteDrinkEntry);

    return AlertDialog(
      title: Text(l10n.deleteEntry),
      content: Text(l10n.deleteEntryPrompt),
      actions: <Widget>[
        TextButton(
          key: const Key('delete-entry-cancel-button'),
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('delete-entry-confirm-button'),
          style: AppTheme.destructiveFilledButtonStyle(theme.colorScheme),
          onPressed: isBusy ? null : _delete,
          child: isDeleting
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onError,
                    ),
                  ),
                )
              : Text(l10n.deleteEntry),
        ),
      ],
    );
  }
}
