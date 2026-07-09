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
    // This test seeds history before the widget tree even mounts; surface
    // the resulting celebration now so it doesn't cover the achievements
    // grid on the very first frame (a separate concern from what this test
    // actually verifies).
    await controller.markAchievementUnlocksSurfaced(
      controller.pendingCelebrationUnlocks.map((u) => u.ref).toList(),
    );

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

  testWidgets('birthday badge detail shows the setup-required state and a Set up now action', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'setup-required-screen@example.com',
      password: 'password123',
      displayName: 'Setup Required Screen',
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    await _openAchievementsTab(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Birthday Bash'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Birthday Bash'));
    await tester.pumpAndSettle();

    expect(find.text('Setup required'), findsWidgets);
    expect(find.text('Set up now'), findsOneWidget);
  });

  testWidgets('shows the Earnable today pill when the birthday matches today and is not yet earned', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'earnable-screen@example.com',
      password: 'password123',
      displayName: 'Earnable Screen',
    );
    final today = DateTime.now();
    await controller.updateProfile(
      displayName: 'Earnable Screen',
      birthday: DateTime(1990, today.month, today.day),
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    await _openAchievementsTab(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Birthday Bash'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Birthday Bash'));
    await tester.pumpAndSettle();

    expect(find.text('Earnable today'), findsOneWidget);
  });

  testWidgets('profile preview shows the earned count and latest badge, and opens the Achievements tab', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-preview@example.com',
      password: 'password123',
      displayName: 'Profile Preview',
    );
    final beer = controller.availableDrinks.firstWhere((d) => d.id == 'beer-classic');
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    await controller.markAchievementUnlocksSurfaced(
      controller.pendingCelebrationUnlocks.map((u) => u.ref).toList(),
    );

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final previewFinder = find.byKey(const Key('profile-achievements-preview'));
    await tester.scrollUntilVisible(previewFinder, 300, scrollable: find.byType(Scrollable).first);

    expect(
      find.descendant(of: previewFinder, matching: find.textContaining('2 ')),
      findsOneWidget,
      reason: 'first drink unlocks both total_drinks(1) and the anniversary badge',
    );

    await tester.tap(previewFinder);
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
  });
}
