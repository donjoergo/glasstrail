import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:glasstrail/src/screens/profile_screen.dart';

import '../test/support/test_harness.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final maxPumps = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }
  if (finder.evaluate().isEmpty) {
    fail('Timed out waiting for expected widget.');
  }
}

Future<void> _scrollProfileTargetIntoView(
  WidgetTester tester,
  Finder target,
) async {
  final profileScrollable = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(target, 200, scrollable: profileScrollable);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
}

Future<void> _waitOutSnackBars(WidgetTester tester) async {
  // Flash messages (for example the post-sign-in welcome message) overlay
  // the FAB area; let them time out before tapping bottom-anchored widgets.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _logDrinkWithComment(WidgetTester tester, String comment) async {
  await _waitOutSnackBars(tester);
  await tester.tap(find.byKey(const Key('global-add-drink-fab')));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('drink-search-field')), 'Water');
  await tester.pumpAndSettle();

  await tester.tap(find.text('Water').last);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.byKey(const Key('drink-comment-field')));
  await tester.enterText(find.byKey(const Key('drink-comment-field')), comment);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.byKey(const Key('confirm-drink-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-drink-button')));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'signs up, logs a drink, changes a setting, and keeps data after re-login',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const email = 'alice@example.com';
      const password = 'password123';
      const comment = 'Logged by integration test';

      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('signup-email-field')),
        email,
      );
      await tester.enterText(
        find.byKey(const Key('signup-password-field')),
        password,
      );
      await tester.enterText(
        find.byKey(const Key('signup-display-name-field')),
        'Alice Example',
      );

      await tester.tap(find.byKey(const Key('auth-submit-button')));
      await tester.pumpAndSettle();

      final beerWithMeLaterButton = find.byKey(
        const Key('post-signup-beer-with-me-later-button'),
      );
      expect(beerWithMeLaterButton, findsOneWidget);
      await tester.tap(beerWithMeLaterButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feed-empty-state')), findsOneWidget);

      await _logDrinkWithComment(tester, comment);

      expect(find.text(comment), findsWidgets);

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      expect(find.text('Category breakdown'), findsOneWidget);
      expect(find.textContaining('Water'), findsWidgets);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      final shareStatsSwitch = find.byKey(
        const Key('share-stats-settings-switch'),
      );
      await _scrollProfileTargetIntoView(tester, shareStatsSwitch);
      expect(tester.widget<Switch>(shareStatsSwitch).value, isTrue);

      await tester.tap(shareStatsSwitch);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(shareStatsSwitch).value, isFalse);

      final logoutButton = find.byKey(const Key('profile-logout-button'));
      await _scrollProfileTargetIntoView(tester, logoutButton);
      await tester.tap(logoutButton);
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('auth-submit-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsNothing);

      await tester.enterText(
        find.byKey(const Key('signin-email-field')),
        email,
      );
      await tester.enterText(
        find.byKey(const Key('signin-password-field')),
        password,
      );
      await tester.tap(find.byKey(const Key('auth-submit-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feed-list-view')), findsOneWidget);
      expect(find.text(comment), findsWidgets);

      await _waitOutSnackBars(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await _scrollProfileTargetIntoView(tester, shareStatsSwitch);
      expect(tester.widget<Switch>(shareStatsSwitch).value, isFalse);
    },
  );
}
