import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/app.dart';

void main() {
  testWidgets('shows onboarding flow on first launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GlassTrailApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to GlassTrail'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
