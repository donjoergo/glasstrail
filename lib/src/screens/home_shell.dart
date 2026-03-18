import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';
import 'add_drink_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HistoryScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  Future<void> _openAddDrink() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AddDrinkScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final handedness = controller.settings.handedness;
    final isLeftHanded = handedness == AppHandedness.left;
    final titles = <String>[l10n.feed, l10n.statistics, l10n.profile];
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final fab = FloatingActionButton.extended(
      key: const Key('global-add-drink-fab'),
      onPressed: _openAddDrink,
      icon: const Icon(Icons.add_rounded),
      label: Text(l10n.addDrink),
    );

    if (isWide) {
      return Scaffold(
        appBar: AppBar(title: Text(titles[_currentIndex])),
        body: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 112,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: NavigationRail(
                    selectedIndex: _currentIndex,
                    useIndicator: true,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    destinations: <NavigationRailDestination>[
                      NavigationRailDestination(
                        icon: const Icon(Icons.view_timeline_outlined),
                        selectedIcon: const Icon(Icons.view_timeline_rounded),
                        label: Text(l10n.feed),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.pie_chart_outline_rounded),
                        selectedIcon: const Icon(Icons.pie_chart_rounded),
                        label: Text(l10n.statistics),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.person_outline_rounded),
                        selectedIcon: const Icon(Icons.person_rounded),
                        label: Text(l10n.profile),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
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
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: fab,
      floatingActionButtonLocation: isLeftHanded
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.view_timeline_outlined),
            selectedIcon: const Icon(Icons.view_timeline_rounded),
            label: l10n.feed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: const Icon(Icons.pie_chart_rounded),
            label: l10n.statistics,
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
