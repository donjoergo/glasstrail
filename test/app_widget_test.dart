import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

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

Future<void> _switchToSignUp(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('auth-mode-segmented')));
  await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a bootstrap screen until the controller is ready', (
    tester,
  ) async {
    final controllerCompleter = Completer<AppController>();

    await tester.pumpWidget(
      GlassTrailBootstrapApp(
        controllerFuture: controllerCompleter.future,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pump();

    expect(find.text('Glass Trail'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controllerCompleter.complete(await buildTestController());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Track every glass'), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });

  testWidgets(
    'accepts the browser initial route while the bootstrap shell is active',
    (tester) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          AppRoutes.statistics;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );

      final controllerCompleter = Completer<AppController>();

      await tester.pumpWidget(
        GlassTrailBootstrapApp(
          controllerFuture: controllerCompleter.future,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Glass Trail'), findsOneWidget);

      final controller = await buildTestController();
      await controller.signUp(
        email: 'bootstrap-route@example.com',
        password: 'password123',
        displayName: 'Bootstrap Route',
      );
      controllerCompleter.complete(controller);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Category breakdown'), findsOneWidget);
    },
  );

  testWidgets('restores the last visited bar route after a web reload', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    final routeMemory = await RouteMemory.create();

    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'reload-bar@example.com',
      password: 'password123',
      displayName: 'Reload Bar',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        routeMemory: routeMemory,
        initialRoute: AppRoutes.feed,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bar'));
    await tester.pumpAndSettle();
    final barRoute = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(barRoute?.settings.name, AppRoutes.bar);

    final reloadedController = await AppController.bootstrapWithRepository(
      repository,
    );
    await tester.pumpWidget(
      GlassTrailBootstrapApp(
        controllerFuture: Future<AppController>.value(reloadedController),
        photoService: const TestPhotoService(),
        routeMemoryFuture: Future<RouteMemory>.value(routeMemory),
      ),
    );
    await tester.pumpAndSettle();

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.bar);
  });

  testWidgets('starts in feed after a native app restart', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    final routeMemory = await RouteMemory.create();

    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'native-restart@example.com',
      password: 'password123',
      displayName: 'Native Restart',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        routeMemory: routeMemory,
        initialRoute: AppRoutes.feed,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bar'));
    await tester.pumpAndSettle();

    final restartedController = await AppController.bootstrapWithRepository(
      repository,
    );
    await tester.pumpWidget(
      GlassTrailBootstrapApp(
        controllerFuture: Future<AppController>.value(restartedController),
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.feed);
  });

  testWidgets('boots into authentication flow', (tester) async {
    final app = await buildTestApp();

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-brand-hero')), findsOneWidget);
    expect(find.byKey(const Key('auth-brand-icon')), findsOneWidget);
    expect(
      find.text(
        'The first release focuses on private tracking. Social features come later.',
      ),
      findsNothing,
    );
    final brandTitle = tester.widget<Text>(
      find.byKey(const Key('auth-brand-title')),
    );
    expect(brandTitle.maxLines, 1);
    expect(brandTitle.softWrap, isFalse);
    expect(find.text('Track every glass'), findsOneWidget);
    expect(find.text('Glass Trail'), findsOneWidget);
    expect(find.byKey(const Key('auth-language-selector')), findsOneWidget);
    expect(find.byKey(const Key('auth-language-dropdown')), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    expect(
      find.byKey(const Key('auth-language-segmented-control')),
      findsNothing,
    );
    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });

  testWidgets('shows the current auth language in a dedicated dropdown', (
    tester,
  ) async {
    final controller = await buildTestController();
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

    expect(find.byKey(const Key('auth-language-dropdown')), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Jedes Glas festhalten'), findsOneWidget);
  });

  testWidgets('updates and remembers auth language from the dropdown', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localeMemory = await LocaleMemory.create();
    final controller = await buildTestController();

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        localeMemory: localeMemory,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth-language-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(controller.settings.localeCode, 'de');
    expect(localeMemory.localeCode, 'de');
    expect(find.text('Jedes Glas festhalten'), findsOneWidget);
  });

  testWidgets('configures browser autofill hints for auth fields', (
    tester,
  ) async {
    final app = await buildTestApp();

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    TextField fieldByLabel(String labelText) {
      return tester
          .widgetList<TextField>(find.byType(TextField))
          .firstWhere((field) => field.decoration?.labelText == labelText);
    }

    final signInEmailField = fieldByLabel('Email');
    final signInPasswordField = fieldByLabel('Password');

    expect(signInEmailField.autofillHints, contains(AutofillHints.email));
    expect(signInPasswordField.autofillHints, contains(AutofillHints.password));

    await _switchToSignUp(tester);

    final signUpEmailField = fieldByLabel('Email');
    final signUpPasswordField = fieldByLabel('Password');
    final signUpDisplayNameField = fieldByLabel('Display name');

    expect(signUpEmailField.autofillHints, contains(AutofillHints.email));
    expect(
      signUpPasswordField.autofillHints,
      contains(AutofillHints.newPassword),
    );
    expect(signUpDisplayNameField.autofillHints, contains(AutofillHints.name));
  });

  testWidgets('uses a full-width auth mode toggle without selected icons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = await buildTestApp();

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final segmentedButtonFinder = find.byKey(const Key('auth-mode-segmented'));
    final segmentedButton = tester.widget<SegmentedButton<Object?>>(
      segmentedButtonFinder,
    );

    expect(segmentedButton.showSelectedIcon, isFalse);
    expect(segmentedButton.expandedInsets, EdgeInsets.zero);

    final cardRect = tester.getRect(find.byType(Card));
    final segmentedRect = tester.getRect(segmentedButtonFinder);
    expect(segmentedRect.width, closeTo(cardRect.width - 48, 0.01));
    expect(find.byKey(const Key('auth-language-dropdown')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _switchToSignUp(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a profile image preview on sign-up without a filename', (
    tester,
  ) async {
    final controller = await buildTestController();
    final photoService = RecordingPhotoService();

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await _switchToSignUp(tester);
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(find.byKey(const Key('auth-profile-image-preview')), findsOneWidget);
    expect(find.text('mock-image.png'), findsNothing);
    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.profile,
    ]);
  });

  testWidgets('offers the Android camera option for sign-up photos', (
    tester,
  ) async {
    final controller = await buildTestController();
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await _switchToSignUp(tester);
    await tester.ensureVisible(find.text('Pick photo'));
    await tester.tap(find.text('Pick photo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-source-camera-option')), findsOneWidget);
    expect(
      find.byKey(const Key('photo-source-gallery-option')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('photo-source-camera-option')));
    await tester.pumpAndSettle();

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.profile,
    ]);
    expect(photoService.pickedSources, <PhotoPickSource>[
      PhotoPickSource.camera,
    ]);
  });

  testWidgets('shows a loading spinner while sign-up is being submitted', (
    tester,
  ) async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.signUp,
    );
    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _switchToSignUp(tester);
    await tester.enterText(
      find.byKey(const Key('signup-email-field')),
      'busy-signup@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('signup-display-name-field')),
      'Busy Signup',
    );

    await tester.ensureVisible(find.byKey(const Key('auth-submit-button')));
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('auth-submit-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('signup-email-field')))
          .enabled,
      isFalse,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-streak-card')), findsOneWidget);
  });

  testWidgets('submits sign-in on enter from the password field', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'keyboard-login@example.com',
      password: 'password123',
      displayName: 'Keyboard Login',
    );
    await controller.signOut();

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('signin-email-field')),
      'keyboard-login@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signin-password-field')),
      'password123',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-streak-card')), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsNothing);
  });

  testWidgets('redirects the root route to feed', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'feed@example.com',
      password: 'password123',
      displayName: 'Feed Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.root,
      ),
    );
    await tester.pumpAndSettle();

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.feed);
  });

  testWidgets('opens bookmarked statistics route for authenticated users', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats@example.com',
      password: 'password123',
      displayName: 'Stats Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category breakdown'), findsOneWidget);
  });

  testWidgets('restores the protected route after sign-in', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    await repository.signUp(
      email: 'protected-login@example.com',
      password: 'password123',
      displayName: 'Protected Login',
    );
    await repository.signOut();
    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
    expect(find.text('Category breakdown'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('signin-email-field')),
      'protected-login@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signin-password-field')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('auth-submit-button')));
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-streak-card')), findsNothing);
    expect(find.text('Category breakdown'), findsOneWidget);

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.statistics);
  });

  testWidgets('restores the protected route after sign-up', (tester) async {
    final app = await buildTestApp(initialRoute: AppRoutes.editProfile);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
    expect(
      find.byKey(const Key('edit-profile-display-name-field')),
      findsNothing,
    );

    await _switchToSignUp(tester);

    await tester.enterText(
      find.byKey(const Key('signup-email-field')),
      'protected-signup@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('signup-display-name-field')),
      'Protected Signup',
    );

    await tester.ensureVisible(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('edit-profile-display-name-field')),
      findsOneWidget,
    );

    final route = ModalRoute.of(
      tester.element(find.byKey(const Key('edit-profile-display-name-field'))),
    );
    expect(route?.settings.name, AppRoutes.editProfile);
  });

  testWidgets('navigates to feed after login when the user logged out', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'logout-reset@example.com',
      password: 'password123',
      displayName: 'Logout Reset',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.feed,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('signin-email-field')),
      'logout-reset@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signin-password-field')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('auth-submit-button')));
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-streak-card')), findsOneWidget);
    expect(find.byType(HomeShell), findsOneWidget);

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.feed);
  });

  testWidgets('opens bookmarked edit-profile route for authenticated users', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile@example.com',
      password: 'password123',
      displayName: 'Profile Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.editProfile,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('edit-profile-display-name-field')),
      findsOneWidget,
    );
  });

  testWidgets('opens bookmarked bar route for authenticated users', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar@example.com',
      password: 'password123',
      displayName: 'Bar Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bar-global-section')), findsOneWidget);

    final route = ModalRoute.of(
      tester.element(find.byKey(const Key('bar-global-section'))),
    );
    expect(route?.settings.name, AppRoutes.bar);
  });
}
