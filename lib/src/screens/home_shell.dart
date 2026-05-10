import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_routes.dart';
import '../app_scope.dart';
import '../models.dart';
import 'bar_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.routeName});

  final String routeName;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late String _currentRouteName;

  @override
  void initState() {
    super.initState();
    _currentRouteName = AppRoutes.normalize(widget.routeName);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeName == widget.routeName) {
      return;
    }
    final normalizedRoute = AppRoutes.normalize(widget.routeName);
    if (_currentRouteName == normalizedRoute) {
      return;
    }
    _currentRouteName = normalizedRoute;
  }

  Future<void> _openAddDrink(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoutes.addDrink);
  }

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoutes.notifications);
  }

  String _targetRouteForHomeIndex(BuildContext context, int index) {
    final routeMemory = AppScope.routeMemoryOf(context).lastRoute;
    return switch (index) {
      0 => AppRoutes.feed,
      1 =>
        AppRoutes.isStatisticsRoute(routeMemory)
            ? routeMemory
            : AppRoutes.statistics,
      2 => AppRoutes.isBarRoute(routeMemory) ? routeMemory : AppRoutes.bar,
      3 => AppRoutes.profile,
      _ => AppRoutes.feed,
    };
  }

  void _openHomeRoute(BuildContext context, int index) {
    final targetRoute = _targetRouteForHomeIndex(context, index);
    final currentRoute = AppRoutes.homePrimaryRoute(_currentRouteName);
    if (AppRoutes.homePrimaryRoute(targetRoute) == currentRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  void _updateHomeSubroute(String routeName) {
    final normalizedRoute = AppRoutes.normalize(routeName);
    if (_currentRouteName == normalizedRoute) {
      return;
    }

    setState(() {
      _currentRouteName = normalizedRoute;
    });

    final routeMemory = AppScope.routeMemoryOf(context);
    unawaited(routeMemory.rememberRoute(normalizedRoute));
    unawaited(
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(normalizedRoute),
        replace: true,
      ),
    );
  }

  Widget _buildCurrentPage() {
    return switch (AppRoutes.homePrimaryRoute(_currentRouteName)) {
      AppRoutes.feed => const FeedScreen(),
      AppRoutes.statistics => StatisticsScreen(
        routeName: _currentRouteName,
        onRouteSelected: _updateHomeSubroute,
      ),
      AppRoutes.bar => BarScreen(
        routeName: _currentRouteName,
        onRouteSelected: _updateHomeSubroute,
      ),
      AppRoutes.profile => const ProfileScreen(),
      _ => const FeedScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = AppRoutes.homeTabIndex(_currentRouteName);
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final handedness = controller.settings.handedness;
    final isLeftHanded = handedness == AppHandedness.left;
    final titles = <String>[l10n.feed, l10n.statistics, l10n.bar, l10n.profile];
    final currentPage = _buildCurrentPage();
    final appBarActions = <Widget>[
      _NotificationsAppBarButton(
        unreadCount: controller.unreadNotificationCount,
        tooltip: l10n.notificationsTooltip,
        onPressed: () => _openNotifications(context),
      ),
    ];
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final appBarTitleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontSize: isWide ? 24 : 20,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      height: 1,
      // letterSpacing: -0.4,
    );
    final fab = FloatingActionButton.extended(
      key: const Key('global-add-drink-fab'),
      onPressed: () => _openAddDrink(context),
      icon: const Icon(Icons.add_rounded),
      label: Text(l10n.addDrink),
    );

    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(titles[currentIndex], style: appBarTitleStyle),
          actions: appBarActions,
        ),
        body: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  key: const Key('home-shell-wide-rail-shell'),
                  width: 112,
                  margin: const EdgeInsets.all(16),
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: NavigationRail(
                    selectedIndex: currentIndex,
                    useIndicator: true,
                    onDestinationSelected: (index) =>
                        _openHomeRoute(context, index),
                    destinations: <NavigationRailDestination>[
                      NavigationRailDestination(
                        icon: const Icon(Icons.rss_feed_outlined),
                        selectedIcon: const Icon(Icons.rss_feed_rounded),
                        label: Text(l10n.feed),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.bar_chart_outlined),
                        selectedIcon: const Icon(Icons.bar_chart_rounded),
                        label: Text(l10n.statistics),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.local_bar_outlined),
                        selectedIcon: const Icon(Icons.local_bar_rounded),
                        label: Text(l10n.bar),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.person_outline_rounded),
                        selectedIcon: const Icon(Icons.person_rounded),
                        label: Text(l10n.profile),
                      ),
                    ],
                  ),
                ),
                Expanded(child: currentPage),
              ],
            ),
            PositionedDirectional(
              start: isLeftHanded ? 160 : null,
              end: isLeftHanded ? null : 32,
              bottom: 32,
              child: fab,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex], style: appBarTitleStyle),
        actions: appBarActions,
      ),
      body: currentPage,
      floatingActionButton: fab,
      floatingActionButtonLocation: isLeftHanded
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _openHomeRoute(context, index),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.rss_feed_outlined),
            selectedIcon: const Icon(Icons.rss_feed_rounded),
            label: l10n.feed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l10n.statistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_bar_outlined),
            selectedIcon: const Icon(Icons.local_bar_rounded),
            label: l10n.bar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

class _NotificationsAppBarButton extends StatelessWidget {
  const _NotificationsAppBarButton({
    required this.unreadCount,
    required this.tooltip,
    required this.onPressed,
  });

  final int unreadCount;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Badge.count(
        key: const Key('home-notifications-badge'),
        count: unreadCount,
        isLabelVisible: unreadCount > 0,
        child: IconButton(
          key: const Key('home-notifications-button'),
          tooltip: tooltip,
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_none_rounded),
          selectedIcon: const Icon(Icons.notifications_rounded),
        ),
      ),
    );
  }
}
