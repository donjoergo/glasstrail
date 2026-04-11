import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:url_launcher/url_launcher.dart';

import '../app_routes.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../maplibre_web_registration.dart' as maplibre_web_registration;
import '../models.dart';
import '../runtime_platform.dart' as runtime_platform;
import '../stats_calculator.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_media.dart';

part 'statistics/statistics_screen_overview.dart';
part 'statistics/statistics_screen_map_logic.dart';
part 'statistics/statistics_screen_map_widgets.dart';
part 'statistics/statistics_screen_map_view.dart';
part 'statistics/statistics_screen_entries.dart';

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
    DrinkCategory.sparklingWines: theme.colorScheme.secondaryContainer,
    DrinkCategory.longdrinks: theme.colorScheme.tertiaryContainer,
    DrinkCategory.spirits: theme.colorScheme.tertiary,
    DrinkCategory.shots: theme.colorScheme.errorContainer,
    DrinkCategory.cocktails: theme.colorScheme.error,
    DrinkCategory.appleWines: theme.colorScheme.surfaceContainerHighest,
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

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.routeName,
    required this.onRouteSelected,
  });

  final String routeName;
  final ValueChanged<String> onRouteSelected;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 4;
  static const _settledTabOffsetEpsilon = 0.0001;

  late final TabController _tabController;
  bool _isUpdatingControllerFromRoute = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: AppRoutes.statisticsTabIndexForRoute(widget.routeName),
    )..addListener(_handleTabControllerChange);
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = AppRoutes.statisticsTabIndexForRoute(widget.routeName);
    if (_tabController.index == targetIndex) {
      return;
    }
    _isUpdatingControllerFromRoute = true;
    _tabController.index = targetIndex;
    _isUpdatingControllerFromRoute = false;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabControllerChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabControllerChange() {
    if (_isUpdatingControllerFromRoute ||
        !mounted ||
        _tabController.indexIsChanging ||
        _tabController.offset.abs() > _settledTabOffsetEpsilon) {
      return;
    }

    final currentIndex = AppRoutes.statisticsTabIndexForRoute(widget.routeName);
    if (_tabController.index == currentIndex) {
      return;
    }

    widget.onRouteSelected(
      AppRoutes.statisticsRouteForIndex(_tabController.index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              key: const Key('statistics-tab-bar'),
              controller: _tabController,
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
            controller: _tabController,
            children: <Widget>[
              const _StatisticsOverviewPage(),
              const _StatisticsMapPage(),
              const _StatisticsGalleryPage(),
              const _StatisticsHistoryPage(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatisticsEmptyStateCard extends StatelessWidget {
  const _StatisticsEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateCard(icon: icon, title: title, body: body);
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
