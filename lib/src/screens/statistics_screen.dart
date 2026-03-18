import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DrinkCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final stats = controller.statistics;
    final entries = _selectedCategory == null
        ? controller.entries
        : controller.entries
              .where((entry) => entry.category == _selectedCategory)
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _StatCard(
              icon: Icons.calendar_view_week_rounded,
              iconKey: const Key('stats-card-icon-weekly'),
              label: l10n.weeklyTotal,
              value: '${stats.weeklyTotal}',
            ),
            _StatCard(
              icon: Icons.calendar_month_rounded,
              iconKey: const Key('stats-card-icon-monthly'),
              label: l10n.monthlyTotal,
              value: '${stats.monthlyTotal}',
            ),
            _StatCard(
              icon: Icons.event_available_rounded,
              iconKey: const Key('stats-card-icon-yearly'),
              label: l10n.yearlyTotal,
              value: '${stats.yearlyTotal}',
            ),
            _StatCard(
              icon: Icons.local_fire_department_rounded,
              iconKey: const Key('stats-card-icon-current-streak'),
              label: l10n.currentStreak,
              value:
                  '${stats.currentStreak} ${l10n.dayLabel(stats.currentStreak)}',
            ),
            _StatCard(
              icon: Icons.emoji_events_rounded,
              iconKey: const Key('stats-card-icon-best-streak'),
              label: l10n.bestStreak,
              value: '${stats.bestStreak} ${l10n.dayLabel(stats.bestStreak)}',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.categoryBreakdown,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                    sections: _buildSections(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: DrinkCategory.values.map((category) {
                  final count = stats.categoryCounts[category] ?? 0;
                  return FilterChip(
                    selected: _selectedCategory == category,
                    avatar: Icon(
                      category.icon,
                      key: Key(
                        'stats-category-chip-icon-${category.storageValue}',
                      ),
                      size: 18,
                    ),
                    label: Text('${l10n.categoryLabel(category)} ($count)'),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = _selectedCategory == category
                            ? null
                            : category;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.history,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(l10n.emptyFilter),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(entry.category.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            controller.localizedEntryDrinkName(entry),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd(
                              controller.settings.localeCode,
                            ).format(entry.consumedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(controller.settings.unit.formatVolume(entry.volumeMl)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = AppScope.controllerOf(context).statistics;
    final colors = <DrinkCategory, Color>{
      DrinkCategory.beer: theme.colorScheme.primary,
      DrinkCategory.wine: theme.colorScheme.secondary,
      DrinkCategory.spirits: theme.colorScheme.tertiary,
      DrinkCategory.cocktails: theme.colorScheme.error,
      DrinkCategory.nonAlcoholic: theme.colorScheme.primaryContainer,
    };

    return DrinkCategory.values.map((category) {
      final count = stats.categoryCounts[category] ?? 0;
      return PieChartSectionData(
        value: count.toDouble(),
        color: colors[category],
        radius: 48,
        title: count == 0 ? '' : '${l10n.categoryLabel(category)}\n$count',
        titleStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimary,
        ),
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconKey,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Key iconKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              key: iconKey,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
