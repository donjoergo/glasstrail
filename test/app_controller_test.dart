import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_localizations.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/app_repository.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/stats_calculator.dart';

import 'support/test_harness.dart';

void main() {
  test('bootstraps independent repository reads in parallel', () async {
    final repository = _BootstrapProbeRepository();

    final bootstrapFuture = AppController.bootstrapWithRepository(repository);

    expect(repository.loadDefaultCatalogCalls, 1);
    expect(repository.restoreSessionCalls, 1);
    expect(repository.loadCustomDrinksCalls, 0);
    expect(repository.loadEntriesCalls, 0);
    expect(repository.loadSettingsCalls, 0);

    repository.defaultCatalogCompleter.complete(buildDefaultDrinkCatalog());
    repository.restoreSessionCompleter.complete(
      const AppUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User Example',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(repository.loadCustomDrinksCalls, 1);
    expect(repository.loadEntriesCalls, 1);
    expect(repository.loadSettingsCalls, 1);

    repository.customDrinksCompleter.complete(const <DrinkDefinition>[]);
    repository.entriesCompleter.complete(const <DrinkEntry>[]);
    repository.settingsCompleter.complete(UserSettings.defaults());

    final controller = await bootstrapFuture;
    expect(controller.isAuthenticated, isTrue);
    expect(controller.availableDrinks, isNotEmpty);
  });

  test('refreshes app data through the repository again', () async {
    final repository = _BootstrapProbeRepository();
    repository.defaultCatalogCompleter.complete(buildDefaultDrinkCatalog());
    repository.restoreSessionCompleter.complete(
      const AppUser(
        id: 'refresh-user',
        email: 'refresh@example.com',
        displayName: 'Refresh Example',
      ),
    );
    repository.customDrinksCompleter.complete(const <DrinkDefinition>[]);
    repository.entriesCompleter.complete(const <DrinkEntry>[]);
    repository.settingsCompleter.complete(UserSettings.defaults());

    final controller = await AppController.bootstrapWithRepository(repository);

    final success = await controller.refreshData();

    expect(success, isTrue);
    expect(repository.loadDefaultCatalogCalls, 2);
    expect(repository.loadCustomDrinksCalls, 2);
    expect(repository.loadEntriesCalls, 2);
    expect(repository.loadSettingsCalls, 2);
  });

  test('localizes success flash messages and drink names', () async {
    final controller = await buildTestController();
    final german = AppLocalizations(const Locale('de'));

    await controller.signUp(
      email: 'flash@example.com',
      password: 'password123',
      displayName: 'Flash Beispiel',
    );
    expect(controller.takeFlashMessage(german), 'Willkommen bei GlassTrail.');

    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    final redWine = controller.availableDrinks.firstWhere(
      (drink) => drink.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: redWine, volumeMl: redWine.volumeMl);

    expect(controller.takeFlashMessage(german), 'Rotwein erfasst.');
  });

  test('localizes mapped repository error messages', () async {
    final controller = await buildTestController();
    final german = AppLocalizations(const Locale('de'));

    await controller.signUp(
      email: 'duplicate@example.com',
      password: 'password123',
      displayName: 'Erstes Konto',
    );
    controller.takeFlashMessage(german);

    final success = await controller.signUp(
      email: 'duplicate@example.com',
      password: 'password123',
      displayName: 'Zweites Konto',
    );

    expect(success, isFalse);
    expect(
      controller.takeFlashMessage(german),
      'Es gibt bereits ein Konto mit dieser E-Mail-Adresse.',
    );
  });

  test(
    'removes the current user profile image when updating the profile',
    () async {
      final controller = await buildTestController();
      final german = AppLocalizations(const Locale('de'));

      await controller.signUp(
        email: 'profile-image@example.com',
        password: 'password123',
        displayName: 'Profile Image Example',
        profileImagePath: '/tmp/profile-before.png',
      );
      controller.takeFlashMessage(german);

      final success = await controller.updateProfile(
        displayName: 'Profile Image Example',
        profileImagePath: null,
        clearProfileImage: true,
      );

      expect(success, isTrue);
      expect(controller.currentUser?.profileImagePath, isNull);
      expect(controller.takeFlashMessage(german), 'Profil aktualisiert.');
    },
  );

  test('updates a drink entry and emits a localized success message', () async {
    final controller = await buildTestController();
    final german = AppLocalizations(const Locale('de'));

    await controller.signUp(
      email: 'edit-entry@example.com',
      password: 'password123',
      displayName: 'Edit Entry Example',
    );
    controller.takeFlashMessage(german);

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Vorher',
      imagePath: '/tmp/initial-image.png',
    );
    controller.takeFlashMessage(german);

    final success = await controller.updateDrinkEntry(
      entry: controller.entries.single,
      comment: 'Nachher',
      imagePath: null,
    );

    expect(success, isTrue);
    expect(controller.entries.single.comment, 'Nachher');
    expect(controller.entries.single.imagePath, isNull);
    expect(controller.takeFlashMessage(german), 'Eintrag aktualisiert.');
  });

  test('deletes a drink entry and emits a localized success message', () async {
    final controller = await buildTestController();
    final german = AppLocalizations(const Locale('de'));

    await controller.signUp(
      email: 'delete-entry@example.com',
      password: 'password123',
      displayName: 'Delete Entry Example',
    );
    controller.takeFlashMessage(german);

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    controller.takeFlashMessage(german);

    final success = await controller.deleteDrinkEntry(
      controller.entries.single,
    );

    expect(success, isTrue);
    expect(controller.entries, isEmpty);
    expect(controller.takeFlashMessage(german), 'Eintrag gelöscht.');
  });

  test('re-evaluates streak statistics after deleting a drink entry', () async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'streak-delete@example.com',
      password: 'password123',
      displayName: 'Streak Delete Example',
    );
    controller.takeFlashMessage(AppLocalizations(const Locale('en')));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final yesterday = today.subtract(const Duration(days: 1));

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: yesterday,
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: today,
    );

    await controller.refreshData();

    expect(controller.statistics.currentStreak, 2);
    expect(
      controller.statistics.streakMessageState,
      StreakMessageState.continuedToday,
    );

    final entryToDelete = controller.entries.firstWhere(
      (entry) =>
          entry.consumedAt.year == today.year &&
          entry.consumedAt.month == today.month &&
          entry.consumedAt.day == today.day,
    );

    final success = await controller.deleteDrinkEntry(entryToDelete);

    expect(success, isTrue);
    expect(controller.statistics.currentStreak, 0);
    expect(controller.statistics.streakThroughYesterday, 1);
    expect(
      controller.statistics.streakMessageState,
      StreakMessageState.keepAlive,
    );
  });
}

class _BootstrapProbeRepository implements AppRepository {
  final defaultCatalogCompleter = Completer<List<DrinkDefinition>>();
  final restoreSessionCompleter = Completer<AppUser?>();
  final customDrinksCompleter = Completer<List<DrinkDefinition>>();
  final entriesCompleter = Completer<List<DrinkEntry>>();
  final settingsCompleter = Completer<UserSettings>();

  int loadDefaultCatalogCalls = 0;
  int restoreSessionCalls = 0;
  int loadCustomDrinksCalls = 0;
  int loadEntriesCalls = 0;
  int loadSettingsCalls = 0;

  @override
  String get backendLabel => 'probe';

  @override
  bool get usesRemoteBackend => false;

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog() {
    loadDefaultCatalogCalls++;
    return defaultCatalogCompleter.future;
  }

  @override
  Future<AppUser?> restoreSession() {
    restoreSessionCalls++;
    return restoreSessionCompleter.future;
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(String userId) {
    loadCustomDrinksCalls++;
    return customDrinksCompleter.future;
  }

  @override
  Future<List<DrinkEntry>> loadEntries(String userId) {
    loadEntriesCalls++;
    return entriesCompleter.future;
  }

  @override
  Future<UserSettings> loadSettings(String userId) {
    loadSettingsCalls++;
    return settingsCompleter.future;
  }

  @override
  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    DateTime? consumedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    String? imagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserSettings> saveSettings(String userId, UserSettings settings) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> updateProfile(AppUser user) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  }) {
    throw UnimplementedError();
  }
}
