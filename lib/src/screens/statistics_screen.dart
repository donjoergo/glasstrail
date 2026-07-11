import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_breakpoints.dart';
import '../app_controller.dart';
import '../app_routes.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../maplibre_web_registration.dart' as maplibre_web_registration;
import '../models.dart';
import '../runtime_platform.dart' as runtime_platform;
import '../widgets/adaptive_modal.dart';
import '../widgets/app_constrained_content.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_media.dart';
import '../widgets/drink_entry_detail_content.dart';
import '../widgets/resizable_master_detail.dart';
import '../widgets/statistics_overview_content.dart';
import 'statistics/statistics_map_web_cursor.dart' as statistics_map_web_cursor;

part 'statistics/statistics_screen_overview.dart';
part 'statistics/statistics_screen_map_logic.dart';
part 'statistics/statistics_screen_map_widgets.dart';
part 'statistics/statistics_screen_map_panel.dart';
part 'statistics/statistics_screen_map_view.dart';
part 'statistics/statistics_screen_entries.dart';

BorderSide _selectableChipBorder(ThemeData theme, bool selected) {
  final scheme = theme.colorScheme;
  return selected
      ? BorderSide(color: scheme.primary, width: 1.5)
      : BorderSide(color: scheme.outline.withValues(alpha: 0.45));
}

TextStyle? _selectableChipLabelStyle(ThemeData theme, bool selected) {
  return theme.textTheme.labelLarge?.copyWith(
    color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
  );
}

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

    if (AppBreakpoints.isLarge(context)) {
      final isHistory =
          AppRoutes.normalize(widget.routeName) == AppRoutes.statisticsHistory;

      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: SegmentedButton<bool>(
              key: const Key('statistics-wide-section-switcher'),
              showSelectedIcon: false,
              // A state-independent text style keeps the label layout stable
              // across selection changes; state-dependent styles trip a
              // TextPainter relayout assert inside _RenderSegmentedButton.
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll<TextStyle?>(
                  theme.textTheme.labelLarge,
                ),
              ),
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.statisticsDashboard, softWrap: false),
                  icon: const Icon(Icons.dashboard_outlined),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.history, softWrap: false),
                  icon: const Icon(Icons.history_rounded),
                ),
              ],
              selected: <bool>{isHistory},
              onSelectionChanged: (selection) {
                final wantsHistory = selection.single;
                if (wantsHistory == isHistory) {
                  return;
                }
                widget.onRouteSelected(
                  wantsHistory
                      ? AppRoutes.statisticsHistory
                      : AppRoutes.statistics,
                );
              },
            ),
          ),
          Expanded(
            child: isHistory
                ? const _StatisticsHistoryPage()
                : const _StatisticsDashboardPage(),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: AppConstrainedContent(
            maxWidth: AppBreakpoints.listContentMaxWidth,
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
