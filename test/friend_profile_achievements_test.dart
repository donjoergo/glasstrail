import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

import 'support/test_harness.dart';

Future<void> _scrollToAchievementsOpenButton(WidgetTester tester) {
  return tester.scrollUntilVisible(
    find.byKey(const Key('friend-achievements-open-button')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets('shows shared achievements when the friend shares them', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);

    final requester = await repository.signUp(
      email: 'fa-requester@example.com',
      password: 'password123',
      displayName: 'Requester',
    );
    await repository.signOut();

    await repository.signUp(
      email: 'fa-addressee@example.com',
      password: 'password123',
      displayName: 'Addressee',
    );
    var addresseeController = await AppController.bootstrapWithRepository(
      repository,
    );
    final beer = addresseeController.availableDrinks.firstWhere(
      (d) => d.id == 'beer-classic',
    );
    await addresseeController.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    final addressee = addresseeController.currentUser!;
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.signOut();

    await repository.signIn(
      email: 'fa-requester@example.com',
      password: 'password123',
    );
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    final addresseeConnections = await repository.loadFriendConnections(
      addressee.id,
    );
    await repository.acceptFriendRequest(
      userId: addressee.id,
      relationshipId: addresseeConnections.single.id,
    );

    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.friendStatsProfileRoute(addressee.id),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToAchievementsOpenButton(tester);
    final openButton = find.byKey(const Key('friend-achievements-open-button'));
    expect(openButton, findsOneWidget);
    await tester.tap(openButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('friend-achievements-section')), findsOneWidget);
    expect(find.text('First Pour'), findsOneWidget);
    // Friend view never shows progress bars, locked levels, or timestamps.
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows nothing when the friend does not share achievements', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalAppRepository(preferences);

    final requester = await repository.signUp(
      email: 'fa2-requester@example.com',
      password: 'password123',
      displayName: 'Requester',
    );
    await repository.signOut();

    await repository.signUp(
      email: 'fa2-addressee@example.com',
      password: 'password123',
      displayName: 'Addressee',
    );
    var addresseeController = await AppController.bootstrapWithRepository(
      repository,
    );
    final beer = addresseeController.availableDrinks.firstWhere(
      (d) => d.id == 'beer-classic',
    );
    await addresseeController.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    await addresseeController.updateSettings(
      addresseeController.settings.copyWith(shareAchievements: false),
    );
    final addressee = addresseeController.currentUser!;
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.signOut();

    await repository.signIn(
      email: 'fa2-requester@example.com',
      password: 'password123',
    );
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    final addresseeConnections = await repository.loadFriendConnections(
      addressee.id,
    );
    await repository.acceptFriendRequest(
      userId: addressee.id,
      relationshipId: addresseeConnections.single.id,
    );

    final controller = await AppController.bootstrapWithRepository(repository);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.friendStatsProfileRoute(addressee.id),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToAchievementsOpenButton(tester);
    await tester.tap(find.byKey(const Key('friend-achievements-open-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('friend-achievements-section')), findsNothing);
  });
}
