import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/screens/statistics_screen.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets(
    'history filter chips list categories in the stored custom order, not '
    'enum order',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'statistics-history-category-order@example.com',
        password: 'password123',
        displayName: 'Category Order Tester',
      );

      const beer = DrinkDefinition(
        id: 'beer-pils',
        name: 'Pils',
        category: DrinkCategory.beer,
        volumeMl: 500,
      );
      const wine = DrinkDefinition(
        id: 'wine-red',
        name: 'Red Wine',
        category: DrinkCategory.wine,
        volumeMl: 150,
      );
      const cocktail = DrinkDefinition(
        id: 'cocktail-mojito',
        name: 'Mojito',
        category: DrinkCategory.cocktails,
        volumeMl: 300,
      );
      for (final drink in <DrinkDefinition>[beer, wine, cocktail]) {
        final added = await controller.addDrinkEntry(
          drink: drink,
          volumeMl: drink.volumeMl,
        );
        expect(added, isTrue);
      }

      // Reversed enum order so the chip order can be distinguished from
      // DrinkCategory.values order. Puts cocktails before wine before beer.
      final reversed = DrinkCategory.values.reversed.toList(growable: false);
      await controller.reorderGlobalCategories(reversed);

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
              body: StatisticsScreen(
                routeName: AppRoutes.statisticsHistory,
                onRouteSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList(growable: false);
      final chipCategoryOrder = chips
          .map(
            (chip) => ((chip.avatar! as Icon).key! as ValueKey<String>).value,
          )
          .toList(growable: false);
      // Only beer, wine, and cocktails have entries (count > 0), so only
      // those three chips render; assert their relative order.
      final expectedOrder =
          <DrinkCategory>[
                DrinkCategory.cocktails,
                DrinkCategory.wine,
                DrinkCategory.beer,
              ]
              .map(
                (category) =>
                    'statistics-history-category-chip-icon-${category.name}',
              )
              .toList(growable: false);

      expect(chipCategoryOrder, expectedOrder);
    },
  );
}
