import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/widgets/drink_picker_catalog.dart';

import 'support/test_harness.dart';

void main() {
  const drinks = <DrinkDefinition>[
    DrinkDefinition(
      id: 'beer-pils',
      name: 'Pils',
      category: DrinkCategory.beer,
      volumeMl: 500,
    ),
  ];

  Future<void> pumpPicker(
    WidgetTester tester, {
    required Size size,
    AppController? controller,
    List<DrinkDefinition> availableDrinks = drinks,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final resolvedController = controller ?? await buildTestController();

    await tester.pumpWidget(
      AppScope(
        controller: resolvedController,
        photoService: const TestPhotoService(),
        importFileService: const TestImportFileService(),
        locationService: const TestLocationService(),
        routeMemory: RouteMemory.disabled(),
        localeMemory: LocaleMemory.disabled(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  key: const Key('open-picker-button'),
                  onPressed: () {
                    showDrinkPickerSheet(
                      context: context,
                      title: 'Pick a drink',
                      availableDrinks: availableDrinks,
                      recentDrinks: const <DrinkDefinition>[],
                      localeCode: 'en',
                      unit: AppUnit.ml,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-picker-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the drink picker as a bottom sheet on narrow screens', (
    tester,
  ) async {
    await pumpPicker(tester, size: const Size(400, 800));

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Pick a drink'), findsOneWidget);
  });

  testWidgets('opens the drink picker as a dialog on expanded screens', (
    tester,
  ) async {
    await pumpPicker(tester, size: const Size(900, 800));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Pick a drink'), findsOneWidget);

    await tester.tap(find.byKey(const Key('drink-picker-close-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a drink'), findsNothing);
  });

  testWidgets(
    'renders category sections in the stored custom order, not enum order',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'drink-picker-category-order@example.com',
        password: 'password123',
        displayName: 'Category Order Tester',
      );
      // Reversed enum order puts cocktails before wine before beer, which
      // is the opposite of DrinkCategory.values order.
      await controller.reorderGlobalCategories(
        DrinkCategory.values.reversed.toList(growable: false),
      );

      const multiCategoryDrinks = <DrinkDefinition>[
        DrinkDefinition(
          id: 'beer-pils',
          name: 'Pils',
          category: DrinkCategory.beer,
          volumeMl: 500,
        ),
        DrinkDefinition(
          id: 'wine-red',
          name: 'Red Wine',
          category: DrinkCategory.wine,
          volumeMl: 150,
        ),
        DrinkDefinition(
          id: 'cocktail-mojito',
          name: 'Mojito',
          category: DrinkCategory.cocktails,
          volumeMl: 300,
        ),
      ];

      await pumpPicker(
        tester,
        size: const Size(900, 1400),
        controller: controller,
        availableDrinks: multiCategoryDrinks,
      );

      final cocktailsY = tester
          .getTopLeft(find.byKey(const Key('drink-category-title-cocktails')))
          .dy;
      final wineY = tester
          .getTopLeft(find.byKey(const Key('drink-category-title-wine')))
          .dy;
      final beerY = tester
          .getTopLeft(find.byKey(const Key('drink-category-title-beer')))
          .dy;

      expect(cocktailsY, lessThan(wineY));
      expect(wineY, lessThan(beerY));
    },
  );
}
