import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/catalog.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

void main() {
  group('AppController achievements', () {
    test('add drink grants new unlocks', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'achiever@example.com',
        password: 'password123',
        displayName: 'Achiever',
      );

      final beer = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-classic',
      );
      await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);

      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == AchievementFamilyIds.totalDrinks && u.level == 1,
        ),
        isTrue,
      );
      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == AchievementFamilyIds.typeBeer && u.level == 10,
        ),
        isFalse,
      );
    });

    test('re-running evaluation is idempotent', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'idempotent@example.com',
        password: 'password123',
        displayName: 'Idempotent',
      );
      final beer = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-classic',
      );
      await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
      final firstCount = controller.achievementUnlocks.length;

      await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
      // Total drinks 1 already earned; 2nd drink does not re-grant level 1
      // and does not hit the next total-drinks threshold (10) yet.
      expect(controller.achievementUnlocks.length, firstCount);
    });

    test('deleting an entry recomputes progress without revoking earned levels', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'delete-safe@example.com',
        password: 'password123',
        displayName: 'Delete Safe',
      );
      final beer = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-classic',
      );
      await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == AchievementFamilyIds.totalDrinks && u.level == 1,
        ),
        isTrue,
      );

      await controller.deleteDrinkEntry(controller.entries.single);

      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == AchievementFamilyIds.totalDrinks && u.level == 1,
        ),
        isTrue,
        reason: 'earned levels must remain permanent after deletion',
      );
      final totalDrinksProgress = controller.achievementProgress.firstWhere(
        (p) => p.familyId == AchievementFamilyIds.totalDrinks,
      );
      expect(totalDrinksProgress.currentValue, 0);
    });

    test('surfaced unlocks do not reappear in pendingCelebrationUnlocks', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'surfaced@example.com',
        password: 'password123',
        displayName: 'Surfaced',
      );
      final beer = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-classic',
      );
      await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
      expect(controller.pendingCelebrationUnlocks, isNotEmpty);

      final refs = controller.pendingCelebrationUnlocks
          .map((u) => u.ref)
          .toList(growable: false);
      await controller.markAchievementUnlocksSurfaced(refs);

      expect(controller.pendingCelebrationUnlocks, isEmpty);
      expect(
        controller.achievementUnlocks.every((u) => u.surfacedAt != null),
        isTrue,
      );
    });

    test('setting a saved home place unlocks the home ladder retroactively', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'home@example.com',
        password: 'password123',
        displayName: 'Home',
      );
      final beer = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-classic',
      );
      await controller.addDrinkEntry(
        drink: beer,
        volumeMl: beer.volumeMl,
        locationLatitude: 52.5200,
        locationLongitude: 13.4050,
        locationPrecision: LocationPrecision.precise,
      );
      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == AchievementFamilyIds.placeHome,
        ),
        isFalse,
        reason: 'no saved Home yet',
      );

      final success = await controller.setSavedPlace(
        placeType: SavedPlaceType.home,
        latitude: 52.5200,
        longitude: 13.4050,
      );
      expect(success, isTrue);

      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == AchievementFamilyIds.placeHome && u.level == 1,
        ),
        isTrue,
      );
    });

    test('occasion_birthday is setup-required until a birthday is set', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'setup-required@example.com',
        password: 'password123',
        displayName: 'Setup Required',
      );

      final birthdayFamily = achievementFamilyById(
        AchievementFamilyIds.occasionBirthday,
      )!;
      expect(
        controller.achievementProgress
            .firstWhere((p) => p.familyId == birthdayFamily.familyId)
            .setupRequired,
        isTrue,
      );

      await controller.updateProfile(
        displayName: 'Setup Required',
        birthday: DateTime(1990, 6, 15),
      );

      expect(
        controller.achievementProgress
            .firstWhere((p) => p.familyId == birthdayFamily.familyId)
            .setupRequired,
        isFalse,
      );
    });

    test('isAchievementFamilyEarnableToday tracks the birthday window and stops once earned', () async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'earnable@example.com',
        password: 'password123',
        displayName: 'Earnable',
      );

      final birthdayFamily = achievementFamilyById(
        AchievementFamilyIds.occasionBirthday,
      )!;
      expect(controller.isAchievementFamilyEarnableToday(birthdayFamily), isFalse);

      final today = DateTime.now();
      await controller.updateProfile(
        displayName: 'Earnable',
        birthday: DateTime(1990, today.month, today.day),
      );
      expect(controller.isAchievementFamilyEarnableToday(birthdayFamily), isTrue);

      final beer = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-classic',
      );
      await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);

      expect(
        controller.achievementUnlocks.any(
          (u) => u.familyId == birthdayFamily.familyId,
        ),
        isTrue,
      );
      expect(controller.isAchievementFamilyEarnableToday(birthdayFamily), isFalse);
    });

    test('catalog-version backfill runs once on cold start and persists the seen version', () async {
      // Backfill only needs to run at true app cold start (session
      // restore), not on every sign-up/sign-in -- those already trigger
      // fresh evaluation via addDrinkEntry etc. Simulate a restart by
      // bootstrapping a second controller against the same persisted
      // preferences.
      WidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final firstRepository = LocalAppRepository(preferences);
      final firstController = await AppController.bootstrapWithRepository(
        firstRepository,
      );
      await firstController.signUp(
        email: 'backfill@example.com',
        password: 'password123',
        displayName: 'Backfill',
      );
      expect(firstController.settings.achievementCatalogVersionSeen, 0);

      final secondRepository = LocalAppRepository(preferences);
      final secondController = await AppController.bootstrapWithRepository(
        secondRepository,
      );

      expect(
        secondController.settings.achievementCatalogVersionSeen,
        achievementCatalogVersion,
      );
    });
  });
}
