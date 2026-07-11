import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/widgets/drink_entry_detail_content.dart';

import 'support/test_harness.dart';

void main() {
  final entry = DrinkEntry(
    id: 'entry-1',
    userId: 'user-1',
    drinkId: 'drink-1',
    drinkName: 'Test Pils',
    category: DrinkCategory.beer,
    consumedAt: DateTime(2026, 5, 12, 20, 30),
    volumeMl: 500,
    comment: 'Great one',
    locationAddress: 'Teststraße 1, Köln',
  );

  Future<void> pumpDetail(WidgetTester tester, {String? keyPrefix}) async {
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
            body: SingleChildScrollView(
              child: keyPrefix == null
                  ? DrinkEntryDetailContent(
                      entry: entry,
                      accentColor: Colors.amber,
                    )
                  : DrinkEntryDetailContent(
                      entry: entry,
                      accentColor: Colors.amber,
                      keyPrefix: keyPrefix,
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders entry details under the statistics map sheet keys', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(
      find.byKey(const Key('statistics-map-sheet-entry-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('statistics-map-sheet-name-entry-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('statistics-map-sheet-volume-entry-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('statistics-map-sheet-location-entry-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('statistics-map-sheet-comment-entry-1')),
      findsOneWidget,
    );
    expect(find.text('Test Pils'), findsOneWidget);
  });

  testWidgets('builds keys from a custom key prefix', (tester) async {
    await pumpDetail(tester, keyPrefix: 'feed-detail');

    expect(find.byKey(const Key('feed-detail-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('feed-detail-name-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('statistics-map-sheet-entry-1')), findsNothing);
  });
}
