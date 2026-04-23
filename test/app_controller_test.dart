import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/beer_with_me_import.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/app_repository.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/stats_calculator.dart';

import 'support/test_harness.dart';

AppLocalizations _l10n(String languageCode) =>
    lookupAppLocalizations(Locale(languageCode));

void main() {
  test('bootstraps independent repository reads in parallel', () async {
    final repository = _BootstrapProbeRepository();

    final bootstrapFuture = AppController.bootstrapWithRepository(repository);

    expect(repository.loadDefaultCatalogCalls, 1);
    expect(repository.restoreSessionCalls, 1);
    expect(repository.loadCustomDrinksCalls, 0);
    expect(repository.loadEntriesCalls, 0);
    expect(repository.loadSettingsCalls, 0);
    expect(repository.loadFriendConnectionsCalls, 0);

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
    expect(repository.loadFriendConnectionsCalls, 1);

    repository.customDrinksCompleter.complete(const <DrinkDefinition>[]);
    repository.entriesCompleter.complete(const <DrinkEntry>[]);
    repository.settingsCompleter.complete(UserSettings.defaults());
    repository.friendConnectionsCompleter.complete(const <FriendConnection>[]);

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
    repository.friendConnectionsCompleter.complete(const <FriendConnection>[]);

    final controller = await AppController.bootstrapWithRepository(repository);

    final success = await controller.refreshData();

    expect(success, isTrue);
    expect(repository.loadDefaultCatalogCalls, 2);
    expect(repository.loadCustomDrinksCalls, 2);
    expect(repository.loadEntriesCalls, 2);
    expect(repository.loadSettingsCalls, 2);
    expect(repository.loadFriendConnectionsCalls, 2);
  });

  test('tracks sign-up as the active busy action while pending', () async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.signUp,
    );
    final controller = await AppController.bootstrapWithRepository(repository);

    final signUpFuture = controller.signUp(
      email: 'busy-signup@example.com',
      password: 'password123',
      displayName: 'Busy Signup',
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.isBusy, isTrue);
    expect(controller.busyAction, AppBusyAction.signUp);
    expect(controller.isBusyFor(AppBusyAction.signUp), isTrue);

    repository.unblock();
    await signUpFuture;

    expect(controller.isBusy, isFalse);
    expect(controller.busyAction, isNull);
  });

  test('tracks settings updates separately from other busy actions', () async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.updateSettings,
    );
    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'busy-settings@example.com',
      password: 'password123',
      displayName: 'Busy Settings',
    );

    final updateFuture = controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.isBusy, isTrue);
    expect(controller.busyAction, AppBusyAction.updateSettings);
    expect(controller.isBusyFor(AppBusyAction.updateSettings), isTrue);
    expect(controller.isBusyFor(AppBusyAction.signOut), isFalse);

    repository.unblock();
    await updateFuture;

    expect(controller.isBusy, isFalse);
    expect(controller.busyAction, isNull);
  });

  test('localizes success flash messages and drink names', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

    await controller.signUp(
      email: 'flash@example.com',
      password: 'password123',
      displayName: 'Flash Beispiel',
    );
    expect(controller.takeFlashMessage(german), 'Willkommen bei Glass Trail.');

    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    final redWine = controller.availableDrinks.firstWhere(
      (drink) => drink.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: redWine, volumeMl: redWine.volumeMl);

    expect(controller.takeFlashMessage(german), 'Rotwein erfasst.');
  });

  test(
    'imports BeerWithMe exports with duplicates, errors, and no_address',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');
      await controller.signUp(
        email: 'import@example.com',
        password: 'password123',
        displayName: 'Import Beispiel',
      );
      await controller.updateSettings(
        controller.settings.copyWith(localeCode: 'de'),
      );

      final exportFile = parseBeerWithMeExportFile('''
      [
        {
          "id": 172120176,
          "timestamp": "2022-06-06T22:55:15.000+02:00",
          "glassType": "WineRose",
          "address": "no_address"
        },
        {
          "id": 172120177,
          "timestamp": "2022-06-06T23:10:00.000+02:00",
          "glassType": "Beer",
          "longitude": 10.8827774,
          "latitude": 49.5635995,
          "address": "Am Buck 19\\nHerzogenaurach\\nDeutschland"
        },
        {
          "id": 172120178,
          "timestamp": "2022-06-06T23:20:00.000+02:00",
          "glassType": "UnknownType"
        }
      ]
    ''');

      final firstImport = await controller.importBeerWithMeExport(exportFile);

      expect(firstImport.totalRows, 3);
      expect(firstImport.importedCount, 2);
      expect(firstImport.skippedDuplicateCount, 0);
      expect(firstImport.errorCount, 1);
      expect(
        firstImport.errors.single.message,
        german.beerWithMeImportUnknownGlassType('UnknownType'),
      );

      final rose = controller.entries.firstWhere(
        (entry) => entry.importSourceId == '172120176',
      );
      expect(rose.drinkId, 'wine-rosé-wine');
      expect(rose.volumeMl, 150);
      expect(rose.locationAddress, isNull);
      expect(rose.locationLatitude, isNull);
      expect(rose.locationLongitude, isNull);

      final beer = controller.entries.firstWhere(
        (entry) => entry.importSourceId == '172120177',
      );
      expect(beer.drinkId, 'beer-classic');
      expect(beer.volumeMl, 500);
      expect(beer.locationAddress, 'Am Buck 19, Herzogenaurach, Deutschland');
      expect(beer.locationLatitude, 49.5635995);
      expect(beer.locationLongitude, 10.8827774);
      expect(beer.importSource, beerWithMeImportSource);

      final secondImport = await controller.importBeerWithMeExport(exportFile);

      expect(secondImport.totalRows, 3);
      expect(secondImport.importedCount, 0);
      expect(secondImport.skippedDuplicateCount, 2);
      expect(secondImport.errorCount, 1);
    },
  );

  test(
    'publishes BeerWithMe import progress while the import is pending',
    () async {
      final repository = await buildBlockingLocalRepository(
        blockedAction: AppBusyAction.addDrinkEntry,
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
      );
      await controller.signUp(
        email: 'import-progress@example.com',
        password: 'password123',
        displayName: 'Import Progress Example',
      );

      final exportFile = parseBeerWithMeExportFile('''
      [
        {
          "id": 172120179,
          "timestamp": "2022-06-06T22:55:15.000+02:00",
          "glassType": "WineRose",
          "address": "no_address"
        }
      ]
    ''');

      final importFuture = controller.importBeerWithMeExport(exportFile);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isBusyFor(AppBusyAction.importBeerWithMe), isTrue);
      expect(
        controller.beerWithMeImportProgress,
        const TypeMatcher<BeerWithMeImportProgress>(),
      );
      expect(controller.beerWithMeImportProgress?.totalCount, 1);
      expect(controller.beerWithMeImportProgress?.processedCount, 0);
      expect(controller.beerWithMeImportProgress?.importedCount, 0);
      expect(controller.beerWithMeImportProgress?.errorCount, 0);

      repository.unblock();
      final result = await importFuture;

      expect(result.importedCount, 1);
      expect(controller.beerWithMeImportProgress, isNull);
      expect(controller.isBusy, isFalse);
    },
  );

  test('cancels BeerWithMe import after the current row finishes', () async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.addDrinkEntry,
    );
    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'import-cancel@example.com',
      password: 'password123',
      displayName: 'Import Cancel Example',
    );

    final exportFile = parseBeerWithMeExportFile('''
      [
        {
          "id": 172120180,
          "timestamp": "2022-06-06T22:55:15.000+02:00",
          "glassType": "WineRose",
          "address": "no_address"
        },
        {
          "id": 172120181,
          "timestamp": "2022-06-06T23:10:00.000+02:00",
          "glassType": "Beer",
          "address": "no_address"
        }
      ]
    ''');

    final importFuture = controller.importBeerWithMeExport(exportFile);
    await Future<void>.delayed(Duration.zero);

    expect(controller.requestBeerWithMeImportCancellation(), isTrue);
    expect(controller.isBeerWithMeImportCancellationRequested, isTrue);

    repository.unblock();
    final result = await importFuture;

    expect(result.wasCancelled, isTrue);
    expect(result.totalRows, 2);
    expect(result.processedCount, 1);
    expect(result.importedCount, 1);
    expect(result.skippedDuplicateCount, 0);
    expect(result.errorCount, 0);
    expect(
      controller.entries.map((entry) => entry.importSourceId),
      contains('172120180'),
    );
    expect(
      controller.entries.map((entry) => entry.importSourceId),
      isNot(contains('172120181')),
    );
    expect(controller.isBeerWithMeImportCancellationRequested, isFalse);
    expect(controller.isBusy, isFalse);
  });

  test(
    'hides global drinks from selectors while keeping history localization',
    () async {
      final controller = await buildTestController();

      await controller.signUp(
        email: 'hide-global@example.com',
        password: 'password123',
        displayName: 'Hide Global Example',
      );

      final redWine = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'wine-red-wine',
      );
      await controller.addDrinkEntry(
        drink: redWine,
        volumeMl: redWine.volumeMl,
      );

      final hidden = await controller.hideGlobalDrink(redWine.id);

      expect(hidden, isTrue);
      expect(
        controller.availableDrinks.any((drink) => drink.id == redWine.id),
        isFalse,
      );
      expect(
        controller.recentDrinks.any((drink) => drink.id == redWine.id),
        isFalse,
      );
      expect(
        controller.localizedEntryDrinkName(
          controller.entries.first,
          localeCode: 'de',
        ),
        'Rotwein',
      );
    },
  );

  test(
    'hides whole global categories from selectors while keeping history localization',
    () async {
      final controller = await buildTestController();

      await controller.signUp(
        email: 'hide-category@example.com',
        password: 'password123',
        displayName: 'Hide Category Example',
      );

      final pils = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-pils',
      );
      await controller.addDrinkEntry(drink: pils, volumeMl: pils.volumeMl);

      final hidden = await controller.hideGlobalCategory(DrinkCategory.beer);

      expect(hidden, isTrue);
      expect(controller.isGlobalCategoryHidden(DrinkCategory.beer), isTrue);
      expect(controller.settings.hiddenGlobalDrinkCategories, <DrinkCategory>[
        DrinkCategory.beer,
      ]);
      expect(
        controller.availableDrinks.any(
          (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
        ),
        isFalse,
      );
      expect(
        controller.recentDrinks.any(
          (drink) => drink.category == DrinkCategory.beer,
        ),
        isFalse,
      );
      expect(
        controller.localizedEntryDrinkName(
          controller.entries.first,
          localeCode: 'de',
        ),
        'Pils',
      );

      final shown = await controller.showGlobalCategory(DrinkCategory.beer);

      expect(shown, isTrue);
      expect(controller.isGlobalCategoryHidden(DrinkCategory.beer), isFalse);
      expect(
        controller.availableDrinks.any((drink) => drink.id == pils.id),
        isTrue,
      );
    },
  );

  test('reorders visible global drinks inside a category', () async {
    final controller = await buildTestController();

    await controller.signUp(
      email: 'reorder-global@example.com',
      password: 'password123',
      displayName: 'Reorder Global Example',
    );

    final initialBeerIds = controller.availableDrinks
        .where(
          (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
        )
        .map((drink) => drink.id)
        .toList(growable: false);
    final reorderedIds = <String>[
      initialBeerIds[1],
      initialBeerIds[0],
      ...initialBeerIds.skip(2),
    ];

    final success = await controller.reorderGlobalDrinks(
      category: DrinkCategory.beer,
      orderedDrinkIds: reorderedIds,
    );

    expect(success, isTrue);
    final updatedBeerIds = controller.availableDrinks
        .where(
          (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
        )
        .map((drink) => drink.id)
        .toList(growable: false);
    expect(updatedBeerIds, reorderedIds);
  });

  test(
    'reorders custom drinks together with global drinks inside a category',
    () async {
      final controller = await buildTestController();

      await controller.signUp(
        email: 'reorder-custom@example.com',
        password: 'password123',
        displayName: 'Reorder Custom Example',
      );
      await controller.saveCustomDrink(
        name: 'Zulu Tonic',
        category: DrinkCategory.cocktails,
        volumeMl: 200,
      );
      final customDrink = controller.customDrinks.single;
      final mojito = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'cocktails-mojito',
      );
      final currentCocktailIds = controller.availableDrinks
          .where((drink) => drink.category == DrinkCategory.cocktails)
          .map((drink) => drink.id)
          .toList(growable: false);

      final success = await controller.reorderGlobalDrinks(
        category: DrinkCategory.cocktails,
        orderedDrinkIds: <String>[
          customDrink.id,
          mojito.id,
          ...currentCocktailIds.where(
            (id) => id != customDrink.id && id != mojito.id,
          ),
        ],
      );

      expect(success, isTrue);
      final updatedCocktailIds = controller.availableDrinks
          .where((drink) => drink.category == DrinkCategory.cocktails)
          .map((drink) => drink.id)
          .toList(growable: false);
      expect(updatedCocktailIds.first, customDrink.id);
      expect(updatedCocktailIds[1], mojito.id);
      expect(
        controller
            .settings
            .globalDrinkOrderOverrides[DrinkCategory.cocktails]
            ?.first,
        customDrink.id,
      );
    },
  );

  test(
    'removes a custom drink photo when saving an existing custom drink',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');

      await controller.signUp(
        email: 'custom-photo-remove@example.com',
        password: 'password123',
        displayName: 'Custom Photo Remove',
      );
      controller.takeFlashMessage(german);

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
        imagePath: '/tmp/custom-drink.png',
      );
      controller.takeFlashMessage(german);

      final existing = controller.customDrinks.single;

      final success = await controller.saveCustomDrink(
        drinkId: existing.id,
        name: existing.name,
        category: existing.category,
        volumeMl: existing.volumeMl,
        imagePath: null,
      );

      expect(success, isTrue);
      expect(controller.customDrinks.single.imagePath, isNull);
      expect(
        controller.takeFlashMessage(german),
        'Eigenes Getränk gespeichert.',
      );
    },
  );

  test('localizes mapped repository error messages', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

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
      final german = _l10n('de');

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
    final german = _l10n('de');

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

  test(
    'deletes a custom drink and emits a localized success message',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');

      await controller.signUp(
        email: 'delete-custom-drink@example.com',
        password: 'password123',
        displayName: 'Delete Custom Drink Example',
      );
      controller.takeFlashMessage(german);

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
      );
      controller.takeFlashMessage(german);

      final drink = controller.customDrinks.single;
      await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
      controller.takeFlashMessage(german);

      final success = await controller.deleteCustomDrink(drink);

      expect(success, isTrue);
      expect(controller.customDrinks, isEmpty);
      expect(controller.entries, hasLength(1));
      expect(
        controller.localizedEntryDrinkName(
          controller.entries.single,
          localeCode: 'de',
        ),
        'Office Brew',
      );
      expect(controller.takeFlashMessage(german), 'Eigenes Getränk gelöscht.');
    },
  );

  test('deletes a drink entry and emits a localized success message', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

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
    controller.takeFlashMessage(_l10n('en'));

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
  final friendConnectionsCompleter = Completer<List<FriendConnection>>();

  int loadDefaultCatalogCalls = 0;
  int restoreSessionCalls = 0;
  int loadCustomDrinksCalls = 0;
  int loadEntriesCalls = 0;
  int loadSettingsCalls = 0;
  int loadFriendConnectionsCalls = 0;

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
  Future<List<FriendConnection>> loadFriendConnections(String userId) {
    loadFriendConnectionsCalls++;
    return friendConnectionsCompleter.future;
  }

  @override
  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    DateTime? consumedAt,
    String? importSource,
    String? importSourceId,
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
  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> acceptFriendRequest({
    required String userId,
    required String relationshipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FriendProfile> getOwnFriendProfile(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> rejectFriendRequest({
    required String userId,
    required String relationshipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> cancelFriendRequest({
    required String userId,
    required String relationshipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> removeFriend({
    required String userId,
    required String friendUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FriendProfile> resolveFriendProfileLink(String shareCode) {
    throw UnimplementedError();
  }

  @override
  Future<PublicFriendProfile> resolvePublicFriendProfileLink(String shareCode) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> sendFriendRequestToProfile({
    required String userId,
    required String shareCode,
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
