import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets('boots into authentication flow', (tester) async {
    final app = await buildTestApp();

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Track every glass'), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });
}
