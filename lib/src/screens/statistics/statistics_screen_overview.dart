part of '../statistics_screen.dart';

class _StatisticsOverviewPage extends StatelessWidget {
  const _StatisticsOverviewPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = controller.statistics;
    final localeCode = controller.settings.localeCode;
    final colors = _statisticsCategoryColors(theme);

    return RefreshIndicator(
      key: const Key('statistics-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: ListView(
        key: const Key('statistics-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          _StatisticsOverviewPanel(stats: stats, localeCode: localeCode),
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
                      sections: _buildSections(context, stats, colors),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: DrinkCategory.values.map((category) {
                    final count = stats.categoryCounts[category] ?? 0;
                    return _StatisticsLegendChip(
                      iconKey: Key(
                        'stats-category-chip-icon-${category.storageValue}',
                      ),
                      label: '${l10n.categoryLabel(category)} ($count)',
                      icon: category.icon,
                      accentColor: colors[category]!,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    BuildContext context,
    AppStatistics stats,
    Map<DrinkCategory, Color> colors,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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

class _StatisticsOverviewPanel extends StatelessWidget {
  const _StatisticsOverviewPanel({
    required this.stats,
    required this.localeCode,
  });

  final AppStatistics stats;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final panelPadding = isCompact ? 16.0 : 20.0;
        final tileSpacing = isCompact ? 8.0 : 12.0;

        return Container(
          key: const Key('stats-overview-panel'),
          padding: EdgeInsets.all(panelPadding),
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
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  key: const Key('stats-overview-totals-row'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.calendar_view_week_rounded,
                        iconKey: const Key('stats-card-icon-weekly'),
                        label: l10n.weeklyTotal,
                        value: '${stats.weeklyTotal}',
                        valueKey: const Key('stats-card-value-weekly'),
                        accentColor: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        isCompact: isCompact,
                      ),
                    ),
                    SizedBox(width: tileSpacing),
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.calendar_month_rounded,
                        iconKey: const Key('stats-card-icon-monthly'),
                        label: l10n.monthlyTotal,
                        value: '${stats.monthlyTotal}',
                        valueKey: const Key('stats-card-value-monthly'),
                        accentColor: theme.colorScheme.secondary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        isCompact: isCompact,
                      ),
                    ),
                    SizedBox(width: tileSpacing),
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.event_available_rounded,
                        iconKey: const Key('stats-card-icon-yearly'),
                        label: l10n.yearlyTotal,
                        value: '${stats.yearlyTotal}',
                        valueKey: const Key('stats-card-value-yearly'),
                        accentColor: theme.colorScheme.tertiary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tileSpacing),
              IntrinsicHeight(
                child: Row(
                  key: const Key('stats-overview-streaks-row'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.local_fire_department_rounded,
                        iconKey: const Key('stats-card-icon-current-streak'),
                        label: l10n.currentStreak,
                        value:
                            '${stats.currentStreak} ${l10n.dayLabel(stats.currentStreak)}',
                        valueKey: const Key('stats-card-value-current-streak'),
                        accentColor: _currentStreakAccentColor(theme, stats),
                        backgroundColor: _currentStreakBackgroundColor(
                          theme,
                          stats,
                        ),
                        isCompact: isCompact,
                        isEmphasized: true,
                      ),
                    ),
                    SizedBox(width: tileSpacing),
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.emoji_events_rounded,
                        iconKey: const Key('stats-card-icon-best-streak'),
                        label: l10n.bestStreak,
                        value:
                            '${stats.bestStreak} ${l10n.dayLabel(stats.bestStreak)}',
                        valueKey: const Key('stats-card-value-best-streak'),
                        subtitle: _formatBestStreakRange(stats),
                        subtitleKey: const Key('stats-card-best-streak-range'),
                        accentColor: theme.colorScheme.secondary,
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.secondary.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.22
                                : 0.1,
                          ),
                          theme.colorScheme.surface,
                        ),
                        isCompact: isCompact,
                        isEmphasized: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _formatBestStreakRange(AppStatistics stats) {
    final start = stats.bestStreakStart;
    final end = stats.bestStreakEnd;
    if (start == null || end == null || stats.bestStreak == 0) {
      return null;
    }

    final currentYear = DateTime.now().year;
    final showYear = start.year != currentYear || end.year != currentYear;

    if (DateUtils.isSameDay(start, end)) {
      final singleDayFormatter = showYear
          ? DateFormat.yMMMd(localeCode)
          : DateFormat.MMMd(localeCode);
      return singleDayFormatter.format(start);
    }

    final formatter = showYear || start.year != end.year
        ? DateFormat.yMMMd(localeCode)
        : DateFormat.MMMd(localeCode);
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  Color _currentStreakAccentColor(ThemeData theme, AppStatistics stats) {
    final scheme = theme.colorScheme;
    return switch (stats.streakMessageState) {
      StreakMessageState.start => scheme.onSurfaceVariant,
      StreakMessageState.keepAlive =>
        theme.brightness == Brightness.dark
            ? scheme.tertiary
            : const Color(0xFF8A5A00),
      StreakMessageState.startedToday =>
        theme.brightness == Brightness.dark
            ? scheme.secondary
            : const Color(0xFF2F6F6D),
      StreakMessageState.continuedToday => scheme.primary,
    };
  }

  Color _currentStreakBackgroundColor(ThemeData theme, AppStatistics stats) {
    final accentColor = _currentStreakAccentColor(theme, stats);
    return Color.alphaBlend(
      accentColor.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.22 : 0.1,
      ),
      theme.colorScheme.surface,
    );
  }
}

class _OverviewMetricTile extends StatelessWidget {
  const _OverviewMetricTile({
    required this.icon,
    required this.iconKey,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.backgroundColor,
    required this.isCompact,
    this.valueKey,
    this.subtitle,
    this.subtitleKey,
    this.isEmphasized = false,
  });

  final IconData icon;
  final Key iconKey;
  final String label;
  final String value;
  final Color accentColor;
  final Color backgroundColor;
  final bool isCompact;
  final Key? valueKey;
  final String? subtitle;
  final Key? subtitleKey;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = isCompact ? 16.0 : 18.0;
    final badgePadding = isCompact ? 7.0 : 8.0;
    final tilePadding = isCompact ? 12.0 : 14.0;
    final labelStyle =
        (isEmphasized
                ? theme.textTheme.labelLarge
                : theme.textTheme.labelMedium)
            ?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            );
    final valueStyle =
        (isEmphasized
                ? theme.textTheme.headlineSmall
                : theme.textTheme.titleLarge)
            ?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.05,
            );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return Container(
      padding: EdgeInsets.all(tilePadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(badgePadding),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, key: iconKey, color: accentColor, size: iconSize),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            label,
            maxLines: isEmphasized ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(key: valueKey, value, style: valueStyle),
          ),
          if (subtitle != null) ...<Widget>[
            SizedBox(height: isCompact ? 8 : 10),
            Text(
              key: subtitleKey,
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ],
        ],
      ),
    );
  }
}
