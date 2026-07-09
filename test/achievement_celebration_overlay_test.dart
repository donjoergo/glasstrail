import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/app.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets('real-time unlocks show the full celebration queue with cards', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'celebrate@example.com',
      password: 'password123',
      displayName: 'Celebrate Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    final beer = controller.availableDrinks.firstWhere((d) => d.id == 'beer-classic');
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    await tester.pump();

    // First drink ever: unlocks total_drinks level 1 ("First Pour") and
    // occasion_first_sip_anniversary ("First Sip Anniversary") in the same
    // real-time batch.
    expect(find.text('First Pour'), findsWidgets);
    expect(find.text('First Sip Anniversary'), findsWidgets);
    expect(controller.pendingCelebrationUnlocks, isNotEmpty);
  });

  testWidgets('tapping the celebration card dismisses and surfaces it', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'dismiss@example.com',
      password: 'password123',
      displayName: 'Dismiss Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    final beer = controller.availableDrinks.firstWhere((d) => d.id == 'beer-classic');
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    await tester.pump();

    expect(controller.pendingCelebrationUnlocks, isNotEmpty);

    await tester.tap(find.text('First Pour').first);
    await tester.pump();

    expect(controller.pendingCelebrationUnlocks, isEmpty);
    expect(
      controller.achievementUnlocks.every((u) => u.surfacedAt != null),
      isTrue,
    );
  });
}
