import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_routes.dart';
import '../app_scope.dart';
import '../models.dart';
import 'bar_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.routeName});

  final String routeName;

  static const _pages = <Widget>[
    HistoryScreen(),
    StatisticsScreen(),
    BarScreen(),
    ProfileScreen(),
  ];

  Future<void> _openAddDrink(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoutes.addDrink);
  }

  void _openHomeRoute(BuildContext context, int index) {
    final targetRoute = AppRoutes.homeRouteForIndex(index);
    final currentRoute = AppRoutes.homeRouteForIndex(
      AppRoutes.homeTabIndex(routeName),
    );
    if (targetRoute == currentRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = AppRoutes.homeTabIndex(routeName);
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final handedness = controller.settings.handedness;
    final isLeftHanded = handedness == AppHandedness.left;
    final titles = <String>[l10n.feed, l10n.statistics, l10n.bar, l10n.profile];
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
                Expanded(child: _pages[currentIndex]),
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
      ),
      body: _pages[currentIndex],
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
