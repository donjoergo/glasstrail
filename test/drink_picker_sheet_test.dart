import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/widgets/drink_picker_catalog.dart';

void main() {
  const drinks = <DrinkDefinition>[
    DrinkDefinition(
      id: 'beer-pils',
      name: 'Pils',
      category: DrinkCategory.beer,
      volumeMl: 500,
    ),
  ];

  Future<void> pumpPicker(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
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
                    availableDrinks: drinks,
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
}
