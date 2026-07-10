import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/screens/statistics_screen.dart';

import 'support/test_harness.dart';

DrinkEntry _entry({required String id, required DateTime consumedAt}) {
  return DrinkEntry(
    id: id,
    userId: 'user-1',
    drinkId: 'drink-$id',
    drinkName: 'Drink $id',
    category: DrinkCategory.beer,
    consumedAt: consumedAt,
    volumeMl: 500,
    locationLatitude: 52.52,
    locationLongitude: 13.405,
  );
}

void main() {
  final olderEntry = _entry(id: 'older', consumedAt: DateTime(2026, 5, 10, 18));
  final newerEntry = _entry(id: 'newer', consumedAt: DateTime(2026, 5, 12, 21));

  Future<void> pumpPanel(
    WidgetTester tester, {
    required List<DrinkEntry> entries,
    DrinkEntry? detailEntry,
    VoidCallback? onClose,
    ValueChanged<DrinkEntry>? onDetailSelected,
    VoidCallback? onBackToList,
  }) async {
    final controller = await buildTestController();
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        photoService: const TestPhotoService(),
        importFileService: const TestImportFileService(),
        locationService: const TestLocationService(),
        routeMemory: RouteMemory.disabled(),
        localeMemory: LocaleMemory.disabled(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                height: 600,
                child: buildStatisticsMapEntryPanelForTesting(
                  entries: entries,
                  detailEntry: detailEntry,
                  onClose: onClose ?? () {},
                  onDetailSelected: onDetailSelected ?? (_) {},
                  onBackToList: onBackToList ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists cluster entries newest first and reports taps', (
    tester,
  ) async {
    DrinkEntry? selectedEntry;
    await pumpPanel(
      tester,
      entries: <DrinkEntry>[olderEntry, newerEntry],
      onDetailSelected: (entry) => selectedEntry = entry,
    );

    expect(find.byKey(const Key('statistics-map-panel-title')), findsOneWidget);
    expect(find.text('2 drinks here'), findsOneWidget);
    expect(find.byKey(const Key('statistics-map-panel-back')), findsNothing);

    final newerTop = tester
        .getTopLeft(find.byKey(const Key('statistics-map-panel-item-newer')))
        .dy;
    final olderTop = tester
        .getTopLeft(find.byKey(const Key('statistics-map-panel-item-older')))
        .dy;
    expect(newerTop, lessThan(olderTop));

    await tester.tap(find.byKey(const Key('statistics-map-panel-item-older')));
    await tester.pumpAndSettle();
    expect(selectedEntry?.id, 'older');
  });

  testWidgets('shows a back button for cluster details only', (tester) async {
    var backToListCalls = 0;
    await pumpPanel(
      tester,
      entries: <DrinkEntry>[olderEntry, newerEntry],
      detailEntry: newerEntry,
      onBackToList: () => backToListCalls++,
    );

    expect(find.byKey(const Key('statistics-map-panel-newer')), findsOneWidget);
    expect(find.byKey(const Key('statistics-map-panel-back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('statistics-map-panel-back')));
    await tester.pumpAndSettle();
    expect(backToListCalls, 1);
  });

  testWidgets('hides the back button for single marker details', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      entries: <DrinkEntry>[newerEntry],
      detailEntry: newerEntry,
    );

    expect(find.byKey(const Key('statistics-map-panel-newer')), findsOneWidget);
    expect(find.byKey(const Key('statistics-map-panel-back')), findsNothing);
  });
}
