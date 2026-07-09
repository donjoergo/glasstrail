import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/app.dart';

import 'support/test_harness.dart';

Future<void> _openAchievementsTab(WidgetTester tester) async {
  await tester.tap(find.text('Achievements'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('main shell has five tabs including Achievements', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'shell@example.com',
      password: 'password123',
      displayName: 'Shell Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsWidgets);
    expect(find.text('Statistics'), findsWidgets);
    expect(find.text('Bar'), findsWidgets);
    expect(find.text('Achievements'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('filters switch between all/unlocked/locked', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'filters@example.com',
      password: 'password123',
      displayName: 'Filters Example',
    );
    final beer = controller.availableDrinks.firstWhere((d) => d.id == 'beer-classic');
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    await _openAchievementsTab(tester);
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);

    await tester.tap(find.text('Unlocked'));
    await tester.pumpAndSettle();
    expect(controller.achievementsFilter.toString(), contains('unlocked'));

    await tester.tap(find.text('Locked'));
    await tester.pumpAndSettle();
    expect(controller.achievementsFilter.toString(), contains('locked'));
  });

  testWidgets('detail sheet opens without hiding the global add-drink FAB', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'detail@example.com',
      password: 'password123',
      displayName: 'Detail Example',
    );
    final beer = controller.availableDrinks.firstWhere((d) => d.id == 'beer-classic');
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    await _openAchievementsTab(tester);
    await tester.pumpAndSettle();

    // Open the Cheers Chase (total drinks) family card, which is unlocked.
    await tester.tap(find.text('Cheers Chase'));
    await tester.pumpAndSettle();

    // "First Pour" appears both in the recently-unlocked strip and in the
    // opened detail sheet's level list.
    expect(find.text('First Pour'), findsNWidgets(2));
    expect(find.byKey(const Key('global-add-drink-fab')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    // Only the recently-unlocked strip's copy remains once the sheet closes.
    expect(find.text('First Pour'), findsOneWidget);
  });
}
