import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/friend_profile_links.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:glasstrail/src/screens/profile_screen.dart';
import 'package:glasstrail/src/widgets/app_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

const _transparentPngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRSEAAAAASUVORK5CYII=';

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

Color? _foregroundColor(ButtonStyle? style) =>
    style?.foregroundColor?.resolve(<WidgetState>{});

BorderSide? _borderSide(ButtonStyle? style) =>
    style?.side?.resolve(<WidgetState>{});

String _rememberedRoute(WidgetTester tester) {
  return AppScope.routeMemoryOf(
    tester.element(find.byType(HomeShell)),
  ).lastRoute;
}

Finder _profileScrollable() => find.descendant(
  of: find.byType(ProfileScreen),
  matching: find.byType(Scrollable),
);

Future<void> _scrollProfileTargetIntoView(
  WidgetTester tester,
  Finder target,
) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: _profileScrollable(),
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
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

      expect(find.byKey(const Key('stats-overview-panel')), findsOneWidget);
    },
  );

  testWidgets('restores the last visited bar subroute after a web reload', (
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
    await tester.tap(find.byKey(const Key('bar-custom-tab')));
    await tester.pumpAndSettle();

    final barRoute = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(barRoute?.settings.name, AppRoutes.bar);
    expect(_rememberedRoute(tester), AppRoutes.barCustom);

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
    expect(route?.settings.name, AppRoutes.barCustom);
    expect(find.byKey(const Key('bar-custom-drinks-section')), findsOneWidget);
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

  testWidgets('styles sign-up remove actions as destructive', (tester) async {
    final controller = await buildTestController();
    final photoService = RecordingPhotoService();

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await _switchToSignUp(tester);
    await tester.tap(find.byKey(const Key('auth-birthday-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tapPhotoAction(tester, find.text('Pick photo'));

    final theme = Theme.of(
      tester.element(find.byKey(const Key('auth-remove-photo-button'))),
    );
    final removeBirthdayButton = tester.widget<IconButton>(
      find.byKey(const Key('auth-remove-birthday-button')),
    );
    final removePhotoButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('auth-remove-photo-button')),
    );

    expect(
      _foregroundColor(removeBirthdayButton.style),
      theme.colorScheme.error,
    );
    expect(_foregroundColor(removePhotoButton.style), theme.colorScheme.error);
    expect(
      _borderSide(removePhotoButton.style),
      BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.72)),
    );
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

    expect(find.byKey(const Key('feed-streak-card')), findsOneWidget);
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

    expect(find.byKey(const Key('feed-streak-card')), findsOneWidget);
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

    expect(find.byKey(const Key('stats-overview-panel')), findsOneWidget);
  });

  testWidgets('opens bookmarked statistics subroutes for authenticated users', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'statistics-subroute@example.com',
      password: 'password123',
      displayName: 'Statistics Subroute',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statisticsMap,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('statistics-map-empty-state')), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.statisticsMap);
  });

  testWidgets('opens bookmarked bar subroutes for authenticated users', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-subroute@example.com',
      password: 'password123',
      displayName: 'Bar Subroute',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.barCustom,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bar-custom-drinks-section')), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.barCustom);
  });

  testWidgets('uses transitionless routes for home shell subroutes', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'transitionless-subroute@example.com',
      password: 'password123',
      displayName: 'Transitionless Subroute',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statisticsMap,
      ),
    );
    await tester.pumpAndSettle();

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route, isA<PageRoute<void>>());
    expect((route! as PageRoute<void>).transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
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
    expect(find.byKey(const Key('stats-overview-panel')), findsNothing);

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

    expect(find.byKey(const Key('feed-streak-card')), findsNothing);
    expect(find.byKey(const Key('stats-overview-panel')), findsOneWidget);

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.statistics);
  });

  testWidgets('restores the protected bar subroute after sign-in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    await repository.signUp(
      email: 'protected-bar-login@example.com',
      password: 'password123',
      displayName: 'Protected Bar Login',
    );
    await repository.signOut();
    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.barCustom,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
    expect(find.byKey(const Key('bar-custom-drinks-section')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('signin-email-field')),
      'protected-bar-login@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signin-password-field')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('auth-submit-button')));
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bar-custom-drinks-section')), findsOneWidget);

    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.barCustom);
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

  testWidgets('shows the profile image on the app profile page', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-image@example.com',
      password: 'password123',
      displayName: 'Profile Image',
      profileImagePath: _transparentPngDataUrl,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    final avatar = find.byKey(const Key('profile-avatar'));
    expect(avatar, findsOneWidget);
    expect(
      find.descendant(of: avatar, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: avatar, matching: find.text('PI')),
      findsNothing,
    );
  });

  testWidgets('falls back to initials on the app profile page', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-initials@example.com',
      password: 'password123',
      displayName: 'Profile Initials',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    final avatar = find.byKey(const Key('profile-avatar'));
    expect(avatar, findsOneWidget);
    expect(
      find.descendant(of: avatar, matching: find.text('PI')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: avatar, matching: find.byType(Image)),
      findsNothing,
    );
  });

  testWidgets('shows reusable friend profile link from the profile screen', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'friend-link-owner@example.com',
      password: 'password123',
      displayName: 'Friend Link Owner',
    );
    final profile = await controller.loadOwnFriendProfile();

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-friends-section')), findsOneWidget);
    expect(find.byKey(const Key('profile-friends-empty')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('profile-friend-link-button')),
    );
    await tester.tap(find.byKey(const Key('profile-friend-link-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('friend-profile-link-dialog')), findsOneWidget);
    expect(find.byKey(const Key('friend-profile-qr-code')), findsOneWidget);
    expect(find.byKey(const Key('friend-profile-link-text')), findsOneWidget);
    expect(
      find.text(friendProfileLinkForCode(profile!.profileShareCode!)),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows public friend profile before sign-in and returns after auth',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final repository = LocalAppRepository(preferences);
      final owner = await repository.signUp(
        email: 'friend-owner@example.com',
        password: 'password123',
        displayName: 'Friend Owner',
      );
      final ownerProfile = await repository.getOwnFriendProfile(owner.id);
      await repository.signOut();
      await repository.signUp(
        email: 'friend-viewer@example.com',
        password: 'password123',
        displayName: 'Friend Viewer',
      );
      await repository.signOut();
      final controller = await AppController.bootstrapWithRepository(
        repository,
      );
      final routeMemory = await RouteMemory.create();
      await routeMemory.markLoggedOut();

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          routeMemory: routeMemory,
          initialRoute: AppRoutes.friendProfileRoute(
            ownerProfile.profileShareCode!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('friend-profile-link-screen')),
        findsOneWidget,
      );
      expect(find.text('Friend Owner'), findsOneWidget);
      expect(
        find.text('Friend Owner wants to be your friend on Glass Trail.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('friend-profile-email')), findsNothing);
      expect(
        find.byKey(const Key('friend-profile-sign-in-button')),
        findsOneWidget,
      );
      final avatar = tester.widget<AppAvatar>(
        find.byKey(const Key('friend-profile-avatar')),
      );
      expect(avatar.radius, 72);

      await tester.tap(find.byKey(const Key('friend-profile-sign-in-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('signin-email-field')),
        'friend-viewer@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signin-password-field')),
        'password123',
      );
      await tester.ensureVisible(find.byKey(const Key('auth-submit-button')));
      await tester.tap(find.byKey(const Key('auth-submit-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('friend-profile-link-screen')),
        findsOneWidget,
      );
      expect(find.text('Friend Owner'), findsOneWidget);
      expect(
        find.byKey(const Key('friend-profile-add-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('friend-profile-add-button')));
      await tester.pumpAndSettle();

      expect(controller.outgoingFriendRequests, hasLength(1));
      expect(controller.outgoingFriendRequests.single.profile.id, owner.id);
      expect(
        find.byKey(const Key('friend-profile-cancel-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('friend-profile-cancel-button')));
      await tester.pumpAndSettle();

      expect(controller.outgoingFriendRequests, isEmpty);
      expect(
        find.byKey(const Key('friend-profile-add-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets('withdraws outgoing friend requests from the profile screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    final requester = await repository.signUp(
      email: 'outgoing-requester@example.com',
      password: 'password123',
      displayName: 'Outgoing Requester',
    );
    await repository.signOut();
    final addressee = await repository.signUp(
      email: 'outgoing-addressee@example.com',
      password: 'password123',
      displayName: 'Outgoing Addressee',
    );
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.signOut();
    await repository.signIn(
      email: 'outgoing-requester@example.com',
      password: 'password123',
    );
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    final request = controller.outgoingFriendRequests.single;
    final cancelButton = find.byKey(Key('friend-request-cancel-${request.id}'));
    expect(cancelButton, findsOneWidget);
    expect(find.text('Waiting for response'), findsOneWidget);

    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(controller.outgoingFriendRequests, isEmpty);
    expect(find.text('No friends or pending requests yet.'), findsOneWidget);
  });

  testWidgets('returns to feed from an already connected friend profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);
    final requester = await repository.signUp(
      email: 'connected-requester@example.com',
      password: 'password123',
      displayName: 'Connected Requester',
    );
    await repository.signOut();
    final addressee = await repository.signUp(
      email: 'connected-addressee@example.com',
      password: 'password123',
      displayName: 'Connected Addressee',
    );
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    final addresseeConnections = await repository.loadFriendConnections(
      addressee.id,
    );
    await repository.acceptFriendRequest(
      userId: addressee.id,
      relationshipId: addresseeConnections.single.id,
    );
    await repository.signOut();
    await repository.signIn(
      email: 'connected-requester@example.com',
      password: 'password123',
    );
    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.friendProfileRoute(
          addresseeProfile.profileShareCode!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are already friends.'), findsOneWidget);
    expect(find.byKey(const Key('friend-profile-feed-button')), findsOneWidget);
    expect(find.byKey(const Key('friend-profile-add-button')), findsNothing);

    await tester.tap(find.byKey(const Key('friend-profile-feed-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-streak-card')), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(HomeShell)));
    expect(route?.settings.name, AppRoutes.feed);
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
    await _scrollProfileTargetIntoView(tester, logoutButton);
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

    expect(find.byKey(const Key('feed-streak-card')), findsOneWidget);
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
