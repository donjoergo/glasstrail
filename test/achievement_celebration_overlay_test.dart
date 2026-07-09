import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/achievements/catalog_models.dart';
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

  testWidgets('caps animated cards at 3 with an overflow summary for 4+ unlocks', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'overflow@example.com',
      password: 'password123',
      displayName: 'Overflow Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    await controller.setSavedPlace(
      placeType: SavedPlaceType.home,
      latitude: 52.5200,
      longitude: 13.4050,
    );

    final beer = controller.availableDrinks.firstWhere((d) => d.id == 'beer-classic');
    // First-ever entry at the saved Home coordinates with a country set
    // unlocks 4 families in one real-time batch: total_drinks(1),
    // occasion_first_sip_anniversary(1), place_home(1), and country_de(1).
    await controller.addDrinkEntry(
      drink: beer,
      volumeMl: beer.volumeMl,
      countryCode: 'de',
      locationLatitude: 52.5200,
      locationLongitude: 13.4050,
      locationPrecision: LocationPrecision.precise,
    );
    await tester.pump();

    expect(controller.pendingCelebrationUnlocks.length, 4);
    expect(find.text('+1 more unlocked'), findsOneWidget);
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
