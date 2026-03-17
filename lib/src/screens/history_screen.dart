import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final entries = controller.entries;
    final locale = controller.settings.localeCode;

    return ListView(
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
                  ),
                  _MetricBadge(
                    label: l10n.currentStreak,
                    value: '${controller.statistics.currentStreak} ${l10n.days}',
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
                locale: locale,
                unit: controller.settings.unit,
                categoryLabel: l10n.categoryLabel(entry.category),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DrinkEntryCard extends StatelessWidget {
  const _DrinkEntryCard({
    required this.entry,
    required this.locale,
    required this.unit,
    required this.categoryLabel,
  });

  final DrinkEntry entry;
  final String locale;
  final AppUnit unit;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat.yMMMd(locale).add_Hm().format(entry.consumedAt);
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
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: theme.colorScheme.primary,
                child: Icon(entry.category.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.drinkName,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(unit.formatVolume(entry.volumeMl)),
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
