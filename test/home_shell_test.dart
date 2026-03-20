import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_localizations.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

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

  testWidgets(
    'shows localized global drink names on the add-drink screen during search',
    (tester) async {
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

      await tester.enterText(
        find.byKey(const Key('drink-search-field')),
        'rot',
      );
      await tester.pumpAndSettle();

      expect(find.text('Rotwein'), findsOneWidget);
      expect(find.text('Red Wine'), findsNothing);
    },
  );

  testWidgets('localizes drink names in feed and statistics', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'entry-locale@example.com',
      password: 'password123',
      displayName: 'Eintrag Beispiel',
    );
    controller.takeFlashMessage(AppLocalizations(const Locale('de')));

    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    final redWine = controller.availableDrinks.firstWhere(
      (drink) => drink.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: redWine, volumeMl: redWine.volumeMl);
    controller.takeFlashMessage(AppLocalizations(const Locale('de')));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rotwein'), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);

    await tester.tap(find.text('Statistiken'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Rotwein'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Rotwein'), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);
  });

  testWidgets('updates renamed custom drinks in feed and statistics', (
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
      email: 'custom-rename@example.com',
      password: 'password123',
      displayName: 'Custom Rename Example',
    );

    await controller.saveCustomDrink(
      name: 'Office Brew',
      category: DrinkCategory.nonAlcoholic,
      volumeMl: 300,
    );
    final customDrink = controller.customDrinks.single;
    await controller.addDrinkEntry(
      drink: customDrink,
      volumeMl: customDrink.volumeMl,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office Brew'), findsOneWidget);

    await controller.saveCustomDrink(
      drinkId: customDrink.id,
      name: 'Desk Coffee',
      category: customDrink.category,
      volumeMl: customDrink.volumeMl,
    );
    await tester.pumpAndSettle();

    expect(find.text('Desk Coffee'), findsOneWidget);
    expect(find.text('Office Brew'), findsNothing);

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Desk Coffee'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Desk Coffee'), findsOneWidget);
    expect(find.text('Office Brew'), findsNothing);
  });

  testWidgets('shows the streak card in the feed without a details button', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'streak-card@example.com',
      password: 'password123',
      displayName: 'Streak Card Example',
    );
    controller.takeFlashMessage(AppLocalizations(const Locale('en')));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-streak-card')), findsOneWidget);
    expect(
      tester.widget<Text>(
        find.byKey(const Key('history-streak-current-value')),
      ),
      isA<Text>().having((widget) => widget.data, 'data', '0 days'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('history-streak-message'))),
      isA<Text>().having(
        (widget) => widget.data,
        'data',
        'Log a drink now to start your streak.',
      ),
    );
    expect(find.text('Details'), findsNothing);
    expect(find.byKey(const Key('history-streak-day-1')), findsOneWidget);
    expect(find.byKey(const Key('history-streak-day-7')), findsOneWidget);
  });

  testWidgets('refreshes the feed with pull to refresh', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'feed-refresh@example.com',
      password: 'password123',
      displayName: 'Feed Refresh Example',
    );
    controller.takeFlashMessage(AppLocalizations(const Locale('en')));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(
        find.byKey(const Key('history-streak-current-value')),
      ),
      isA<Text>().having((widget) => widget.data, 'data', '0 days'),
    );
    expect(find.text('Pils'), findsNothing);

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: DateTime.now(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsNothing);

    await tester.drag(
      find.byKey(const Key('history-list-view')),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(
        find.byKey(const Key('history-streak-current-value')),
      ),
      isA<Text>().having((widget) => widget.data, 'data', '1 day'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('history-streak-message'))),
      isA<Text>().having(
        (widget) => widget.data,
        'data',
        'Very good! You started your streak today.',
      ),
    );
    expect(find.text('Pils'), findsOneWidget);
  });

  testWidgets('refreshes the statistics with pull to refresh', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-refresh@example.com',
      password: 'password123',
      displayName: 'Stats Refresh Example',
    );
    controller.takeFlashMessage(AppLocalizations(const Locale('en')));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-weekly'))),
      isA<Text>().having((widget) => widget.data, 'data', '0'),
    );

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: DateTime.now(),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('statistics-list-view')),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-weekly'))),
      isA<Text>().having((widget) => widget.data, 'data', '1'),
    );
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

    await tester.enterText(find.byKey(const Key('drink-search-field')), 'red');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drink-category-title-beer')), findsNothing);
    expect(find.text('Red Wine'), findsOneWidget);
    expect(find.byKey(const Key('drink-search-clear-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('drink-search-clear-button')));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextFormField>(
      find.byKey(const Key('drink-search-field')),
    );
    expect(searchField.controller?.text, isEmpty);
    expect(find.byKey(const Key('drink-category-title-beer')), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);
    expect(find.byKey(const Key('drink-search-clear-button')), findsNothing);
  });

  testWidgets(
    'keeps add-drink categories collapsed and closes them after selection',
    (tester) async {
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
    },
  );

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

  testWidgets(
    'edits entry comment and image from history without exposing drink controls',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'history-edit@example.com',
        password: 'password123',
        displayName: 'History Edit Example',
      );

      final drink = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'nonAlcoholic-water',
      );
      await controller.addDrinkEntry(
        drink: drink,
        volumeMl: drink.volumeMl,
        comment: 'Before edit',
        imagePath: '/tmp/before-edit.png',
      );
      final entryId = controller.entries.single.id;

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(path: '/tmp/updated-image.png'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('history-entry-actions-$entryId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('history-entry-edit-$entryId')));
      await tester.pumpAndSettle();

      final commentField = tester.widget<TextFormField>(
        find.byKey(const Key('edit-entry-comment-field')),
      );
      final imageLabel = tester.widget<Text>(
        find.byKey(const Key('edit-entry-image-name')),
      );
      expect(commentField.controller?.text, 'Before edit');
      expect(imageLabel.data, 'before-edit.png');
      expect(find.byKey(const Key('drink-search-field')), findsNothing);
      expect(find.byKey(const Key('drink-volume-field')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('edit-entry-comment-field')),
        'After edit',
      );
      await tester.tap(find.byKey(const Key('edit-entry-remove-photo-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-entry-save-button')));
      await tester.pumpAndSettle();

      expect(controller.entries.single.comment, 'After edit');
      expect(controller.entries.single.imagePath, isNull);
      expect(find.text('After edit'), findsOneWidget);
      expect(find.text('Before edit'), findsNothing);
      expect(find.text('before-edit.png'), findsNothing);
    },
  );

  testWidgets('deletes a logged drink from history after confirmation', (
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
      email: 'history-delete@example.com',
      password: 'password123',
      displayName: 'History Delete Example',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsOneWidget);

    await tester.tap(find.byKey(Key('history-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('history-entry-delete-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-entry-confirm-button')));
    await tester.pumpAndSettle();

    expect(controller.entries, isEmpty);
    expect(find.text('Pils'), findsNothing);
    expect(find.text('No drinks logged yet.'), findsOneWidget);

    final streakValue = tester.widget<Text>(
      find.byKey(const Key('history-streak-current-value')),
    );
    expect(streakValue.data, '0 days');
  });
}
