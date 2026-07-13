import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/screens/custom_drink_dialog.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets(
    'category dropdown lists categories in the stored custom order, not '
    'enum order',
    (tester) async {
      final controller = await buildTestController();
      // Reversed enum order so the dropdown order can be distinguished from
      // DrinkCategory.values order.
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
            home: const Scaffold(body: CustomDrinkDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<DrinkCategory>>(
        find.byType(DropdownButton<DrinkCategory>),
      );
      final itemOrder = dropdown.items!
          .map((item) => item.value)
          .toList(growable: false);

      expect(itemOrder, reversed);
    },
  );
}
