import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign up and log a drink end-to-end', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final app = await buildTestApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('signup-email-field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('signup-nickname-field')),
      'alice',
    );
    await tester.enterText(
      find.byKey(const Key('signup-display-name-field')),
      'Alice Example',
    );

    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Your activity feed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('drink-search-field')),
      'Water',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('confirm-drink-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pumpAndSettle();

    expect(find.text('Water'), findsWidgets);

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    expect(find.text('Category breakdown'), findsOneWidget);
    expect(find.text('Water'), findsWidgets);
  });
}
