import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/state/app_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.controller,
    required this.location,
    super.key,
  });

  final Widget child;
  final AppController controller;
  final String location;

  int _indexForLocation() {
    if (location.startsWith('/map')) {
      return 1;
    }
    if (location.startsWith('/stats')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }

  String _addDrinkRoute() {
    return '/drink/new?from=${Uri.encodeComponent(location)}';
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/feed');
        return;
      case 1:
        context.go('/map');
        return;
      case 2:
        context.go(_addDrinkRoute());
        return;
      case 3:
        context.go('/stats');
        return;
      case 4:
        context.go('/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedIndex = _indexForLocation();

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(_addDrinkRoute()),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed),
            label: l10n.navFeed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.navAdd,
          ),
          NavigationDestination(
            icon: const Icon(Icons.query_stats_outlined),
            selectedIcon: const Icon(Icons.query_stats),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
