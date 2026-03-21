import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_localizations.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

import 'support/test_harness.dart';

Future<({AppController controller, BlockingLocalAppRepository repository})>
_buildBlockedHarness(AppBusyAction action) async {
  final repository = await buildBlockingLocalRepository(blockedAction: action);
  final controller = await AppController.bootstrapWithRepository(repository);
  return (controller: controller, repository: repository);
}

Future<void> _openProfileTab(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

Future<void> _openStatisticsTab(
  WidgetTester tester, {
  String label = 'Statistics',
}) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _openStatisticsSection(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byKey(const Key('statistics-tab-bar')),
    matching: find.text(label, skipOffstage: false),
  );
  await tester.ensureVisible(tab.first);
  await tester.tap(tab.first);
  await tester.pumpAndSettle();
}

Future<void> _tapPhotoAction(
  WidgetTester tester,
  Finder button, {
  PhotoPickSource source = PhotoPickSource.gallery,
}) async {
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();

  final sourceOption = switch (source) {
    PhotoPickSource.camera => find.byKey(
      const Key('photo-source-camera-option'),
    ),
    PhotoPickSource.gallery => find.byKey(
      const Key('photo-source-gallery-option'),
    ),
  };
  if (sourceOption.evaluate().isEmpty) {
    return;
  }

  await tester.tap(sourceOption);
  await tester.pumpAndSettle();
}

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

  testWidgets('shows a spinner while saving the profile', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.updateProfile);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'profile-busy@example.com',
      password: 'password123',
      displayName: 'Profile Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-profile-display-name-field')),
      'Profile Busy Updated',
    );
    await tester.tap(find.byKey(const Key('edit-profile-save-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('edit-profile-save-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('edit-profile-display-name-field')),
          )
          .enabled,
      isFalse,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.text('Profile Busy Updated'), findsOneWidget);
  });

  testWidgets('stretches edit-profile action buttons to the right edge', (
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
      email: 'profile-actions@example.com',
      password: 'password123',
      displayName: 'Profile Actions',
      birthday: DateTime(1990, 7, 13),
      profileImagePath: '/tmp/mock-image.png',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('edit-profile-save-button')),
    );
    await tester.pumpAndSettle();

    final saveRect = tester.getRect(
      find.byKey(const Key('edit-profile-save-button')),
    );
    final changePhotoRect = tester.getRect(
      find.byKey(const Key('edit-profile-change-photo-button')),
    );
    final removePhotoRect = tester.getRect(
      find.byKey(const Key('edit-profile-remove-photo-button')),
    );
    final birthdayRect = tester.getRect(
      find.byKey(const Key('edit-profile-birthday-button')),
    );
    final removeBirthdayRect = tester.getRect(
      find.byKey(const Key('edit-profile-remove-birthday-button')),
    );

    expect(
      changePhotoRect.right,
      moreOrLessEquals(saveRect.right, epsilon: 0.01),
    );
    expect(
      removePhotoRect.right,
      moreOrLessEquals(saveRect.right, epsilon: 0.01),
    );
    expect(
      removeBirthdayRect.right,
      moreOrLessEquals(saveRect.right, epsilon: 0.01),
    );
    expect(removeBirthdayRect.width, greaterThan(birthdayRect.width));
    expect(
      birthdayRect.top,
      moreOrLessEquals(removeBirthdayRect.top, epsilon: 0.01),
    );
  });

  testWidgets('uses the profile preset when changing the profile photo', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-photo-preset@example.com',
      password: 'password123',
      displayName: 'Profile Photo Preset',
    );
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.profile,
    ]);
  });

  testWidgets('shows a field-local spinner while saving settings', (
    tester,
  ) async {
    final harness = await _buildBlockedHarness(AppBusyAction.updateSettings);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'settings-busy@example.com',
      password: 'password123',
      displayName: 'Settings Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.ensureVisible(
      find.byKey(const Key('language-segmented-control')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('language-segmented-control')),
        matching: find.text('German'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('language-settings-loading')), findsOneWidget);
    expect(find.byKey(const Key('theme-settings-loading')), findsNothing);

    repository.unblock();
    await tester.pumpAndSettle();

    expect(controller.settings.localeCode, 'de');
    expect(find.byKey(const Key('language-settings-loading')), findsNothing);
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

  testWidgets('shows a spinner while confirming a new drink entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final harness = await _buildBlockedHarness(AppBusyAction.addDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'add-busy@example.com',
      password: 'password123',
      displayName: 'Add Busy',
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
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pils'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('confirm-drink-button')));
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('confirm-drink-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('drink-comment-field')))
          .enabled,
      isFalse,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(controller.entries, hasLength(1));
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

    await _openStatisticsTab(tester, label: 'Statistiken');
    await _openStatisticsSection(tester, 'Historie');

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

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Desk Coffee'), findsOneWidget);
    expect(find.text('Office Brew'), findsNothing);
  });

  testWidgets('shows a spinner while saving a custom drink', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.saveCustomDrink);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'custom-busy@example.com',
      password: 'password123',
      displayName: 'Custom Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('profile-add-custom-drink-button'),
    );
    await tester.scrollUntilVisible(
      addCustomDrinkButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(addCustomDrinkButton);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Night Cap');
    await tester.tap(find.byKey(const Key('custom-drink-save-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('custom-drink-save-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('custom-drink-cancel-button')),
          )
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.text('Night Cap'), findsOneWidget);
  });

  testWidgets('uses the feed preset when picking an add-drink photo', (
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
      email: 'add-drink-photo-preset@example.com',
      password: 'password123',
      displayName: 'Add Drink Photo Preset',
    );
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    final pilsTile = find.widgetWithText(ListTile, 'Pils');
    await tester.ensureVisible(pilsTile);
    await tester.tap(pilsTile);
    await tester.pumpAndSettle();
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.feed,
    ]);
  });

  testWidgets('uses the feed preset when picking a custom drink photo', (
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
      email: 'custom-drink-photo-preset@example.com',
      password: 'password123',
      displayName: 'Custom Drink Photo Preset',
    );
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('profile-add-custom-drink-button'),
    );
    await tester.scrollUntilVisible(
      addCustomDrinkButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(addCustomDrinkButton);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('custom-drink-save-button')), findsOneWidget);
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.feed,
    ]);
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

    await _openStatisticsTab(tester);

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

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pils'));
    await tester.pumpAndSettle();

    final recentDrinkChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Pils'),
    );
    expect(recentDrinkChip.selected, isTrue);
    expect(recentDrinkChip.showCheckmark, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);

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

  testWidgets('keeps totals and streaks in fixed overview rows', (
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
      email: 'stats-overview@example.com',
      password: 'password123',
      displayName: 'Stats Overview Example',
    );
    controller.takeFlashMessage(AppLocalizations(const Locale('en')));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );
    final today = DateTime.now();
    final bestStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 2));
    final bestEnd = bestStart.add(const Duration(days: 2));

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestStart,
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestStart.add(const Duration(days: 1)),
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestEnd,
    );
    await controller.refreshData();

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);

    expect(tester.takeException(), isNull);

    final weeklyIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-weekly')),
    );
    final monthlyIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-monthly')),
    );
    final yearlyIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-yearly')),
    );
    final currentStreakIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-current-streak')),
    );
    final bestStreakIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-best-streak')),
    );

    expect(monthlyIconOffset.dy, closeTo(weeklyIconOffset.dy, 0.1));
    expect(yearlyIconOffset.dy, closeTo(weeklyIconOffset.dy, 0.1));
    expect(currentStreakIconOffset.dy, greaterThan(weeklyIconOffset.dy));
    expect(bestStreakIconOffset.dy, closeTo(currentStreakIconOffset.dy, 0.1));

    final expectedRange =
        '${DateFormat.MMMd(controller.settings.localeCode).format(bestStart)} - '
        '${DateFormat.MMMd(controller.settings.localeCode).format(bestEnd)}';
    expect(
      tester.widget<Text>(
        find.byKey(const Key('stats-card-best-streak-range')),
      ),
      isA<Text>().having((widget) => widget.data, 'data', expectedRange),
    );
  });

  testWidgets('shows a compact history view inside statistics', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-history-compact@example.com',
      password: 'password123',
      displayName: 'Stats History Compact',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Should stay out of compact stats history',
      imagePath: '/tmp/stats-history-image.png',
    );
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Should stay out of compact stats history'), findsNothing);
    expect(find.byKey(Key('history-entry-image-$entryId')), findsNothing);
    expect(find.byKey(Key('history-entry-actions-$entryId')), findsNothing);
  });

  testWidgets('filters the compact statistics history by category', (
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
      email: 'stats-history-filter@example.com',
      password: 'password123',
      displayName: 'Stats History Filter',
    );

    final beer = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final wine = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    await controller.addDrinkEntry(drink: wine, volumeMl: wine.volumeMl);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Pils'), findsOneWidget);
    expect(find.text('Red Wine'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Wine (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsNothing);
    expect(find.text('Red Wine'), findsOneWidget);
  });

  testWidgets('shows placeholder tabs for map and gallery in statistics', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-placeholders@example.com',
      password: 'password123',
      displayName: 'Stats Placeholders',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Map');

    expect(find.text('Drink map coming soon'), findsOneWidget);
    expect(
      find.text('Logged drinks will appear here on a map in a later step.'),
      findsOneWidget,
    );

    await _openStatisticsSection(tester, 'Gallery');

    expect(find.text('Gallery coming soon'), findsOneWidget);
    expect(
      find.text('Drink photos from your log will appear here in a later step.'),
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

      expect(find.byKey(Key('history-entry-image-$entryId')), findsOneWidget);
      expect(find.text('before-edit.png'), findsNothing);

      await tester.tap(find.byKey(Key('history-entry-actions-$entryId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('history-entry-edit-$entryId')));
      await tester.pumpAndSettle();

      final commentField = tester.widget<TextFormField>(
        find.byKey(const Key('edit-entry-comment-field')),
      );
      expect(commentField.controller?.text, 'Before edit');
      expect(find.byKey(const Key('edit-entry-image-preview')), findsOneWidget);
      expect(find.text('before-edit.png'), findsNothing);
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

  testWidgets('uses the feed preset when picking a history entry photo', (
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
      email: 'history-photo-preset@example.com',
      password: 'password123',
      displayName: 'History Photo Preset',
    );
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    final entryId = controller.entries.single.id;
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('history-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('history-entry-edit-$entryId')));
    await tester.pumpAndSettle();
    await _tapPhotoAction(
      tester,
      find.byKey(const Key('edit-entry-pick-photo-button')),
    );

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.feed,
    ]);
  });

  testWidgets('shows a spinner while saving an edited entry', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.updateDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'edit-busy@example.com',
      password: 'password123',
      displayName: 'Edit Busy',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Before edit',
    );
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('history-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('history-entry-edit-$entryId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-entry-comment-field')),
      'After edit',
    );
    await tester.tap(find.byKey(const Key('edit-entry-save-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('edit-entry-save-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('edit-entry-cancel-button')))
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.text('After edit'), findsOneWidget);
  });

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

  testWidgets('shows a spinner while deleting an entry', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.deleteDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'delete-busy@example.com',
      password: 'password123',
      displayName: 'Delete Busy',
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

    await tester.tap(find.byKey(Key('history-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('history-entry-delete-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-entry-confirm-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('delete-entry-confirm-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('delete-entry-cancel-button')),
          )
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(controller.entries, isEmpty);
  });

  testWidgets('shows a spinner while signing out', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.signOut);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'logout-busy@example.com',
      password: 'password123',
      displayName: 'Logout Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    final logoutButton = find.byKey(const Key('profile-logout-button'));
    await tester.scrollUntilVisible(
      logoutButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(logoutButton);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-logout-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });
}
