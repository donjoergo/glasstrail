import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_media.dart';
import '../widgets/statistics_overview_content.dart';
import 'statistics/statistics_map_web_cursor.dart' as statistics_map_web_cursor;

part 'statistics/statistics_screen_overview.dart';
part 'statistics/statistics_screen_map_logic.dart';
part 'statistics/statistics_screen_map_widgets.dart';
part 'statistics/statistics_screen_map_view.dart';
part 'statistics/statistics_screen_entries.dart';

Future<void> _refreshStatistics(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.controllerOf(context);
  final success = await controller.refreshData();
  // This is a top-level function (not State), so use the BuildContext
  // extension's `mounted` rather than a State field to detect if the widget
  // tree was torn down while the refresh was in flight.
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

bool _statisticsGalleryHasImage(DrinkEntry entry) {
  final imagePath = entry.imagePath?.trim();
  return imagePath != null && imagePath.isNotEmpty;
}

// Widen the gallery grid as more horizontal space becomes available (phone
// -> tablet -> desktop) so thumbnails stay a reasonable, tappable size
// instead of shrinking indefinitely or leaving excess whitespace.
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
  // TabController.offset rarely lands exactly on 0 even once a swipe has
  // visually settled, so treat "close enough" as settled to avoid missing
  // route updates due to float imprecision.
  static const _settledTabOffsetEpsilon = 0.0001;

  late final TabController _tabController;
  // Route name and tab index are two sources of truth kept in sync; this
  // flag stops the route->controller sync from re-triggering the
  // controller->route listener and causing a feedback loop.
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
    // Setting .index fires the listener synchronously, so guard it to
    // prevent bouncing back into onRouteSelected.
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
    // Skip changes we triggered ourselves and in-progress swipe animations
    // (indexIsChanging / non-zero offset) so a route update only fires once
    // the tab has actually settled on its new index.
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
