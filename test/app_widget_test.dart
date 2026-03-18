import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('boots into authentication flow', (tester) async {
    final app = await buildTestApp();

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Track every glass'), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
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

    expect(find.text('Your activity feed'), findsOneWidget);
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

  testWidgets('navigates to feed after sign-in from a protected route', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'protected-login@example.com',
      password: 'password123',
      displayName: 'Protected Login',
    );
    await controller.signOut();

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

    expect(find.text('Your activity feed'), findsOneWidget);
    expect(find.text('Category breakdown'), findsNothing);

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.feed);
  });

  testWidgets('navigates to feed after sign-up from a protected route', (
    tester,
  ) async {
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

    expect(find.text('Your activity feed'), findsOneWidget);
    expect(
      find.byKey(const Key('edit-profile-display-name-field')),
      findsNothing,
    );

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
