import 'package:flutter/material.dart';

import '../app_breakpoints.dart';
import '../app_routes.dart';
import 'home_navigation_rail.dart';

/// Wraps a pushed screen (add-drink, friend stats profile) so that on wide
/// screens it renders next to the shared [HomeNavigationRail] instead of
/// covering the whole window. Below the expanded breakpoint it renders
/// [child] bare, so mobile behavior (full-screen route) is unchanged.
///
/// Deliberately has no [Scaffold] of its own — [child] brings its own, and a
/// second one here would duplicate anything shown via
/// `ScaffoldMessenger.of(context).showSnackBar`.
class ShellEmbeddedScreen extends StatelessWidget {
  const ShellEmbeddedScreen({
    super.key,
    required this.routeName,
    required this.child,
  });

  final String routeName;
  final Widget child;

  int? get _selectedIndex => routeName == AppRoutes.addDrink
      ? HomeNavigationRail.addDrinkDestinationIndex
      : null;

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == HomeNavigationRail.addDrinkDestinationIndex) {
      if (routeName == AppRoutes.addDrink) {
        return;
      }
      Navigator.of(context).pushNamed(AppRoutes.addDrink);
      return;
    }
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.pushReplacementNamed(
      HomeNavigationRail.targetRouteForIndex(context, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isExpanded(context)) {
      return child;
    }
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: <Widget>[
          SafeArea(
            child: HomeNavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
