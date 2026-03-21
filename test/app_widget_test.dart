import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

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

    expect(find.text('GlassTrail'), findsOneWidget);
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
      expect(find.text('GlassTrail'), findsOneWidget);

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

  testWidgets('restores the last visited route after a web reload', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    final routeMemory = await RouteMemory.create();

    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'reload-profile@example.com',
      password: 'password123',
      displayName: 'Reload Profile',
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

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final profileRoute = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(profileRoute?.settings.name, AppRoutes.profile);

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
    expect(route?.settings.name, AppRoutes.profile);
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

    await tester.tap(find.text('Profile'));
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

    expect(find.text('Track every glass'), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
    await tester.pumpAndSettle();

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

  testWidgets('shows a profile image preview on sign-up without a filename', (
    tester,
  ) async {
    final controller = await buildTestController();
    final photoService = RecordingPhotoService();

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pick photo'));
    await tester.tap(find.text('Pick photo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-profile-image-preview')), findsOneWidget);
    expect(find.text('mock-image.png'), findsNothing);
    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.profile,
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

    await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
    await tester.pumpAndSettle();

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
}
