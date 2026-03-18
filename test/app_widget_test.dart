import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
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
