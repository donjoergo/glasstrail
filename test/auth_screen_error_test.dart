import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

AppLocalizations get _l10n => lookupAppLocalizations(const Locale('en'));

class _ConfirmationRequiredRepository extends LocalAppRepository {
  _ConfirmationRequiredRepository(super.preferences);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) async {
    throw const AppException(
      'Supabase sign-up succeeded, but email confirmation is enabled. '
      'Confirm the email first, then sign in.',
    );
  }
}

Future<void> _submitSignUp(
  WidgetTester tester, {
  required String email,
  required String password,
  required String displayName,
}) async {
  await tester.ensureVisible(find.byKey(const Key('auth-mode-segmented')));
  await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('signup-email-field')), email);
  await tester.enterText(
    find.byKey(const Key('signup-password-field')),
    password,
  );
  await tester.enterText(
    find.byKey(const Key('signup-display-name-field')),
    displayName,
  );
  await tester.ensureVisible(find.byKey(const Key('auth-submit-button')).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('auth-submit-button')).last);
  await tester.pumpAndSettle();
}

Future<void> _submitSignIn(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(find.byKey(const Key('signin-email-field')), email);
  await tester.enterText(
    find.byKey(const Key('signin-password-field')),
    password,
  );
  await tester.ensureVisible(find.byKey(const Key('auth-submit-button')).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('auth-submit-button')).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows account-exists message and stays on auth for duplicate sign-up',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'taken@example.com',
        password: 'password123',
        displayName: 'First Owner',
      );
      await controller.signOut();

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _submitSignUp(
        tester,
        email: 'taken@example.com',
        password: 'password123',
        displayName: 'Second Owner',
      );

      expect(find.text(_l10n.accountAlreadyExists), findsOneWidget);
      expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
    },
  );

  testWidgets(
    'shows invalid-credentials message and stays on auth for bad sign-in',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'real@example.com',
        password: 'password123',
        displayName: 'Real User',
      );
      await controller.signOut();

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _submitSignIn(
        tester,
        email: 'real@example.com',
        password: 'wrong-password',
      );

      expect(find.text(_l10n.invalidCredentials), findsOneWidget);
      expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
    },
  );

  testWidgets(
    'shows confirmation-required message without navigating when sign-up '
    'returns no session',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final repository = _ConfirmationRequiredRepository(preferences);
      final controller = await AppController.bootstrapWithRepository(
        repository,
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _submitSignUp(
        tester,
        email: 'confirm@example.com',
        password: 'password123',
        displayName: 'Needs Confirmation',
      );

      expect(find.text(_l10n.signUpConfirmationRequired), findsOneWidget);
      expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
    },
  );
}
