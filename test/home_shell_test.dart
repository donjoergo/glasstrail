import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/models.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets('opens profile editing on a separate screen', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'alice@example.com',
      password: 'password123',
      displayName: 'Alice Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('edit-profile-display-name-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('edit-profile-save-button')), findsOneWidget);
  });

  testWidgets('moves the add-drink fab for left-handed mode', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'fab@example.com',
      password: 'password123',
      displayName: 'Fab Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    final rightRect = tester.getRect(
      find.byKey(const Key('global-add-drink-fab')),
    );
    expect(
      rightRect.center.dx,
      greaterThan(tester.view.physicalSize.width / 2),
    );

    await controller.updateSettings(
      controller.settings.copyWith(handedness: AppHandedness.left),
    );
    await tester.pumpAndSettle();

    final leftRect = tester.getRect(
      find.byKey(const Key('global-add-drink-fab')),
    );
    expect(leftRect.center.dx, lessThan(tester.view.physicalSize.width / 2));
  });

  testWidgets('shows and saves add-drink volumes in selected units', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'oz@example.com',
      password: 'password123',
      displayName: 'Oz Example',
    );
    await controller.updateSettings(
      controller.settings.copyWith(unit: AppUnit.oz),
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    expect(find.text('330 ml'), findsNothing);

    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();

    expect(find.text('11.2 oz'), findsWidgets);

    final pilsTile = find.widgetWithText(ListTile, 'Pils');
    await tester.ensureVisible(pilsTile);
    await tester.tap(pilsTile);
    await tester.pumpAndSettle();

    expect(find.text('Volume (oz)'), findsOneWidget);

    final volumeField = tester.widget<TextFormField>(
      find.byKey(const Key('drink-volume-field')),
    );
    expect(volumeField.controller?.text, '11.2');

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pumpAndSettle();

    expect(controller.entries, hasLength(1));
    expect(controller.entries.single.volumeMl, closeTo(330, 0.2));
  });

  testWidgets('shows localized global drink names on the add-drink screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'de@example.com',
      password: 'password123',
      displayName: 'Deutsch Beispiel',
    );
    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('drink-search-field')), 'rot');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('drink-category-title-wine')));
    await tester.pumpAndSettle();

    expect(find.text('Rotwein'), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);
  });

  testWidgets('clears the add-drink search input and restores categories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'clear-search@example.com',
      password: 'password123',
      displayName: 'Clear Search Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('drink-search-field')), 'rot');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drink-category-title-beer')), findsNothing);
    expect(
      find.byKey(const Key('drink-search-clear-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('drink-search-clear-button')));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextFormField>(
      find.byKey(const Key('drink-search-field')),
    );
    expect(searchField.controller?.text, isEmpty);
    expect(find.byKey(const Key('drink-category-title-beer')), findsOneWidget);
    expect(
      find.byKey(const Key('drink-search-clear-button')),
      findsNothing,
    );
  });

  testWidgets(
    'keeps add-drink categories collapsed and closes them after selection',
    (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'accordion@example.com',
      password: 'password123',
      displayName: 'Accordion Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsNothing);
    expect(find.text('Red Wine'), findsNothing);

    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();

    final pilsTile = find.widgetWithText(ListTile, 'Pils');
    expect(pilsTile, findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Red Wine'), findsNothing);

    await tester.tap(pilsTile);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Pils'), findsNothing);
    expect(find.byKey(const Key('drink-volume-field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('drink-category-title-wine')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Pils'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Red Wine'), findsOneWidget);
  });

  testWidgets('shows icons for recent drinks and statistics cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'icons@example.com',
      password: 'password123',
      displayName: 'Icon Beispiel',
    );
    await controller.addDrinkEntry(
      drink: controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-pils',
      ),
      volumeMl: 330,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('recent-drink-icon-beer-pils')),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-card-icon-weekly')), findsOneWidget);
    expect(find.byKey(const Key('stats-card-icon-monthly')), findsOneWidget);
    expect(find.byKey(const Key('stats-card-icon-yearly')), findsOneWidget);
    expect(
      find.byKey(const Key('stats-card-icon-current-streak')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-card-icon-best-streak')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-category-chip-icon-beer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-category-chip-icon-wine')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-category-chip-icon-spirits')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-category-chip-icon-cocktails')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-category-chip-icon-nonAlcoholic')),
      findsOneWidget,
    );
  });
}
