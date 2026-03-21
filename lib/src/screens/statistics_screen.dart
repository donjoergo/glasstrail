import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';
import '../stats_calculator.dart';
import '../widgets/app_media.dart';

Future<void> _refreshStatistics(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.controllerOf(context);
  final success = await controller.refreshData();
  if (!context.mounted || success) {
    return;
  }
  final message = controller.takeFlashMessage(l10n);
  if (message != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

Map<DrinkCategory, Color> _statisticsCategoryColors(ThemeData theme) {
  return <DrinkCategory, Color>{
    DrinkCategory.beer: theme.colorScheme.primary,
    DrinkCategory.wine: theme.colorScheme.secondary,
    DrinkCategory.spirits: theme.colorScheme.tertiary,
    DrinkCategory.cocktails: theme.colorScheme.error,
    DrinkCategory.nonAlcoholic: theme.colorScheme.primaryContainer,
  };
}

bool _statisticsGalleryHasImage(DrinkEntry entry) {
  final imagePath = entry.imagePath?.trim();
  return imagePath != null && imagePath.isNotEmpty;
}

int _statisticsGalleryCrossAxisCount(double maxWidth) {
  if (maxWidth >= 900) {
    return 5;
  }
  if (maxWidth >= 600) {
    return 4;
  }
  return 3;
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                key: const Key('statistics-tab-bar'),
                isScrollable: true,
                padding: const EdgeInsets.all(6),
                labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                dividerColor: Colors.transparent,
                tabs: <Widget>[
                  Tab(text: l10n.statisticsOverview),
                  Tab(text: l10n.statisticsMap),
                  Tab(text: l10n.statisticsGallery),
                  Tab(text: l10n.history),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                const _StatisticsOverviewPage(),
                _StatisticsPlaceholderPage(
                  listKey: const Key('statistics-map-list-view'),
                  placeholderKey: const Key('statistics-map-placeholder'),
                  icon: Icons.map_rounded,
                  title: l10n.statisticsMapPlaceholderTitle,
                  body: l10n.statisticsMapPlaceholderBody,
                ),
                const _StatisticsGalleryPage(),
                const _StatisticsHistoryPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _StatisticsHistoryPage extends StatefulWidget {
  const _StatisticsHistoryPage();

  @override
  State<_StatisticsHistoryPage> createState() => _StatisticsHistoryPageState();
}

class _StatisticsHistoryPageState extends State<_StatisticsHistoryPage> {
  DrinkCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = _selectedCategory == null
        ? controller.entries
        : controller.entries
              .where((entry) => entry.category == _selectedCategory)
              .toList();

    return RefreshIndicator(
      key: const Key('statistics-history-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: ListView(
        key: const Key('statistics-history-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: DrinkCategory.values.map((category) {
                final count =
                    controller.statistics.categoryCounts[category] ?? 0;
                return FilterChip(
                  selected: _selectedCategory == category,
                  showCheckmark: false,
                  avatar: Icon(
                    category.icon,
                    key: Key(
                      'statistics-history-category-chip-icon-${category.storageValue}',
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
          ),
          const SizedBox(height: 24),
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
                child: _StatisticsHistoryEntryCard(entry: entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatisticsHistoryEntryCard extends StatelessWidget {
  const _StatisticsHistoryEntryCard({required this.entry});

  final DrinkEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final locationAddress = _normalizedLocationAddress(entry.locationAddress);

    return Container(
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
                if (locationAddress != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        key: Key(
                          'statistics-history-location-icon-${entry.id}',
                        ),
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationAddress,
                          key: Key('statistics-history-location-${entry.id}'),
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
          Text(controller.settings.unit.formatVolume(entry.volumeMl)),
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

class _StatisticsGalleryPage extends StatelessWidget {
  const _StatisticsGalleryPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final entries = controller.entries
        .where(_statisticsGalleryHasImage)
        .toList(growable: false);
    final galleryItems = entries
        .map(
          (entry) => AppGalleryViewerItem(
            imagePath: entry.imagePath!.trim(),
            drinkName: controller.localizedEntryDrinkName(
              entry,
              localeCode: localeCode,
            ),
            metadata: <String>[
              l10n.categoryLabel(entry.category),
              DateFormat.yMMMd(localeCode).add_Hm().format(entry.consumedAt),
              if (entry.volumeMl != null) unit.formatVolume(entry.volumeMl),
              if (_normalizedLocationAddress(entry.locationAddress) != null)
                _normalizedLocationAddress(entry.locationAddress)!,
            ],
            comment: _normalizedGalleryComment(entry.comment),
          ),
        )
        .toList(growable: false);

    if (entries.isEmpty) {
      final theme = Theme.of(context);
      return RefreshIndicator(
        key: const Key('statistics-gallery-refresh-indicator'),
        onRefresh: () => _refreshStatistics(context),
        child: ListView(
          key: const Key('statistics-gallery-list-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            Container(
              key: const Key('statistics-gallery-empty-state'),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.statisticsGalleryEmptyTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.statisticsGalleryEmptyBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const Key('statistics-gallery-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            key: const Key('statistics-gallery-grid'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _statisticsGalleryCrossAxisCount(
                constraints.maxWidth,
              ),
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final galleryItem = galleryItems[index];

              return _StatisticsGalleryTile(
                key: Key('statistics-gallery-tile-${entry.id}'),
                imagePath: galleryItem.imagePath,
                onTap: () {
                  showAppGalleryViewerDialog(
                    context,
                    items: galleryItems,
                    initialIndex: index,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String? _normalizedGalleryComment(String? comment) {
    final normalized = comment?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _normalizedLocationAddress(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

class _StatisticsGalleryTile extends StatefulWidget {
  const _StatisticsGalleryTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  final String imagePath;
  final VoidCallback onTap;

  @override
  State<_StatisticsGalleryTile> createState() => _StatisticsGalleryTileState();
}

class _StatisticsGalleryTileState extends State<_StatisticsGalleryTile> {
  late Future<ImageProvider<Object>?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateImageFuture();
  }

  @override
  void didUpdateWidget(covariant _StatisticsGalleryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _updateImageFuture();
    }
  }

  void _updateImageFuture() {
    _imageFuture = AppMediaResolver.resolveImageProvider(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: FutureBuilder<ImageProvider<Object>?>(
                future: _imageFuture,
                builder: (context, snapshot) {
                  final imageProvider = snapshot.data;
                  if (imageProvider == null) {
                    return Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    );
                  }
                  return Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsPlaceholderPage extends StatelessWidget {
  const _StatisticsPlaceholderPage({
    required this.listKey,
    required this.placeholderKey,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Key listKey;
  final Key placeholderKey;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => _refreshStatistics(context),
      child: ListView(
        key: listKey,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          Container(
            key: placeholderKey,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 36, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _StatisticsLegendChip extends StatelessWidget {
  const _StatisticsLegendChip({
    required this.iconKey,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final Key iconKey;
  final String label;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withValues(alpha: 0.1),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, key: iconKey, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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

    if (DateUtils.isSameDay(start, end)) {
      return DateFormat.MMMd(localeCode).format(start);
    }

    final formatter = start.year == end.year
        ? DateFormat.MMMd(localeCode)
        : DateFormat.yMMMd(localeCode);
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
