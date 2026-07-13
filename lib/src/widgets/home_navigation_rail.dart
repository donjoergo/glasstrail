import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_routes.dart';
import '../app_scope.dart';

/// Shared wide-screen navigation rail for the home shell's four main tabs
/// plus a 5th add-drink destination, used both by [HomeShell] itself and by
/// screens embedded next to it via `ShellEmbeddedScreen`.
class HomeNavigationRail extends StatelessWidget {
  const HomeNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const addDrinkDestinationIndex = 4;

  // Statistics and Bar have their own internal sub-tabs; if the user was
  // last on a specific sub-tab, tapping the nav item should return them
  // there instead of always resetting to that section's default view.
  static String targetRouteForIndex(BuildContext context, int index) {
    final routeMemory = AppScope.routeMemoryOf(context).lastRoute;
    return switch (index) {
      0 => AppRoutes.feed,
      1 =>
        AppRoutes.isStatisticsRoute(routeMemory)
            ? routeMemory
            : AppRoutes.statistics,
      2 => AppRoutes.isBarRoute(routeMemory) ? routeMemory : AppRoutes.bar,
      3 => AppRoutes.profile,
      addDrinkDestinationIndex => AppRoutes.addDrink,
      _ => AppRoutes.feed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-shell-wide-rail-shell'),
      width: 112,
      margin: const EdgeInsets.all(16),
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        useIndicator: true,
        labelType: NavigationRailLabelType.all,
        onDestinationSelected: onDestinationSelected,
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
          NavigationRailDestination(
            icon: const Icon(
              Icons.add_rounded,
              key: Key('home-rail-add-drink-destination'),
            ),
            selectedIcon: const Icon(Icons.add_circle_rounded),
            label: Text(l10n.addDrinkNavLabel),
          ),
        ],
      ),
    );
  }
}
