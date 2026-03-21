import 'package:flutter/foundation.dart';

import 'app_localizations.dart';
import 'backend_config.dart';
import 'birthday.dart';
import 'models.dart';
import 'repository/app_repository.dart';
import 'repository/repository_factory.dart';
import 'stats_calculator.dart';

enum _FlashMessageKind {
  welcomeToGlassTrail,
  welcomeBack,
  profileUpdated,
  customDrinkSaved,
  drinkLogged,
  drinkEntryUpdated,
  drinkEntryDeleted,
  genericError,
  raw,
}

enum AppBusyAction {
  signIn,
  signUp,
  signOut,
  updateProfile,
  saveCustomDrink,
  addDrinkEntry,
  updateSettings,
  updateDrinkEntry,
  deleteDrinkEntry,
}

class _FlashMessage {
  const _FlashMessage.simple(this.kind)
    : rawMessage = null,
      drinkId = null,
      fallbackDrinkName = null;

  const _FlashMessage.drinkLogged({
    required this.drinkId,
    required this.fallbackDrinkName,
  }) : kind = _FlashMessageKind.drinkLogged,
       rawMessage = null;

  const _FlashMessage.raw(this.rawMessage)
    : kind = _FlashMessageKind.raw,
      drinkId = null,
      fallbackDrinkName = null;

  final _FlashMessageKind kind;
  final String? rawMessage;
  final String? drinkId;
  final String? fallbackDrinkName;
}

class AppController extends ChangeNotifier {
  AppController._(this._repository);

  final AppRepository _repository;

  AppUser? _currentUser;
  UserSettings _settings = UserSettings.defaults();
  List<DrinkDefinition> _defaultCatalog = const <DrinkDefinition>[];
  List<DrinkDefinition> _customDrinks = const <DrinkDefinition>[];
  List<DrinkEntry> _entries = const <DrinkEntry>[];
  bool _isBusy = false;
  AppBusyAction? _busyAction;
  _FlashMessage? _flashMessage;

  static Future<AppController> bootstrap({BackendConfig? backendConfig}) async {
    final repository = await createRepository(backendConfig: backendConfig);
    final controller = AppController._(repository);
    await controller._initialize();
    return controller;
  }

  static Future<AppController> bootstrapWithRepository(
    AppRepository repository,
  ) async {
    final controller = AppController._(repository);
    await controller._initialize();
    return controller;
  }

  AppUser? get currentUser => _currentUser;
  UserSettings get settings => _settings;
  List<DrinkDefinition> get defaultCatalog =>
      List.unmodifiable(_defaultCatalog);
  List<DrinkDefinition> get customDrinks =>
      List.unmodifiable(_sortedCustomDrinks());
  List<DrinkDefinition> get allDrinks => List.unmodifiable(<DrinkDefinition>[
    ..._defaultCatalog,
    ..._customDrinks,
  ]);
  List<DrinkEntry> get entries => List.unmodifiable(_entries);
  bool get isBusy => _isBusy;
  AppBusyAction? get busyAction => _busyAction;
  bool get isAuthenticated => _currentUser != null;
  String get backendLabel => _repository.backendLabel;
  bool get usesRemoteBackend => _repository.usesRemoteBackend;
  AppStatistics get statistics => StatsCalculator.fromEntries(_entries);

  bool isBusyFor(AppBusyAction action) => _busyAction == action;

  List<DrinkDefinition> get availableDrinks {
    final drinks = <DrinkDefinition>[];
    for (final category in DrinkCategory.values) {
      drinks.addAll(sortableDrinksForCategory(category));
    }
    return drinks;
  }

  List<DrinkDefinition> get recentDrinks {
    final byId = {for (final drink in availableDrinks) drink.id: drink};
    final seen = <String>{};
    final result = <DrinkDefinition>[];
    for (final entry in _entries) {
      if (!seen.add(entry.drinkId)) {
        continue;
      }
      final drink = byId[entry.drinkId];
      if (drink != null) {
        result.add(drink);
      }
      if (result.length == 6) {
        break;
      }
    }
    return result;
  }

  bool isGlobalCategoryHidden(DrinkCategory category) {
    return _hiddenGlobalCategorySet().contains(category);
  }

  List<DrinkDefinition> customDrinksForCategory(DrinkCategory category) {
    final drinks =
        _customDrinks
            .where((drink) => drink.category == category)
            .toList(growable: false)
          ..sort(_localizedDrinkComparer);
    return drinks;
  }

  List<DrinkDefinition> sortableDrinksForCategory(DrinkCategory category) {
    final globals = visibleGlobalDrinksForCategory(category);
    final customs = customDrinksForCategory(category);
    final visible = <DrinkDefinition>[...globals, ...customs];
    final byId = {for (final drink in visible) drink.id: drink};
    final ordered = <DrinkDefinition>[];
    final seen = <String>{};

    for (final id in _globalOrderOverrideForCategory(category)) {
      final drink = byId[id];
      if (drink != null && seen.add(id)) {
        ordered.add(drink);
      }
    }

    final remaining =
        visible
            .where((drink) => !seen.contains(drink.id))
            .toList(growable: false)
          ..sort(_localizedDrinkComparer);
    return <DrinkDefinition>[...ordered, ...remaining];
  }

  List<DrinkDefinition> visibleGlobalDrinksForCategory(DrinkCategory category) {
    if (isGlobalCategoryHidden(category)) {
      return const <DrinkDefinition>[];
    }
    final hiddenIds = _hiddenGlobalDrinkIdSet();
    final visible = _defaultCatalog
        .where(
          (drink) =>
              drink.category == category && !hiddenIds.contains(drink.id),
        )
        .toList(growable: false);
    final byId = {for (final drink in visible) drink.id: drink};
    final ordered = <DrinkDefinition>[];
    final seen = <String>{};

    for (final id in _globalOrderOverrideForCategory(category)) {
      final drink = byId[id];
      if (drink != null && seen.add(id)) {
        ordered.add(drink);
      }
    }

    final remaining =
        visible
            .where((drink) => !seen.contains(drink.id))
            .toList(growable: false)
          ..sort(_localizedDrinkComparer);
    return <DrinkDefinition>[...ordered, ...remaining];
  }

  List<DrinkDefinition> hiddenGlobalDrinksForCategory(DrinkCategory category) {
    final hiddenIds = _hiddenGlobalDrinkIdSet();
    final categoryHidden = isGlobalCategoryHidden(category);
    final hidden =
        _defaultCatalog
            .where(
              (drink) =>
                  drink.category == category &&
                  (categoryHidden || hiddenIds.contains(drink.id)),
            )
            .toList(growable: false)
          ..sort(_localizedDrinkComparer);
    return hidden;
  }

  Future<bool> reorderGlobalDrinks({
    required DrinkCategory category,
    required List<String> orderedDrinkIds,
  }) async {
    final currentIds = sortableDrinksForCategory(
      category,
    ).map((drink) => drink.id).toList(growable: false);
    final nextIds = _sanitizeOrderOverrideIds(
      orderedDrinkIds,
      allowedIds: currentIds.toSet(),
    );
    if (listEquals(currentIds, nextIds)) {
      return true;
    }

    final nextOverrides = _copyGlobalDrinkOrderOverrides();
    if (nextIds.isEmpty) {
      nextOverrides.remove(category);
    } else {
      nextOverrides[category] = nextIds;
    }
    return updateSettings(
      _settings.copyWith(globalDrinkOrderOverrides: nextOverrides),
    );
  }

  Future<bool> hideGlobalDrink(String drinkId) async {
    if (!_defaultCatalog.any((drink) => drink.id == drinkId)) {
      return false;
    }
    final hiddenIds = _settings.hiddenGlobalDrinkIds.toList(growable: true);
    if (hiddenIds.contains(drinkId)) {
      return true;
    }
    hiddenIds.add(drinkId);

    final nextOverrides = _copyGlobalDrinkOrderOverrides();
    for (final ids in nextOverrides.values) {
      ids.removeWhere((candidate) => candidate == drinkId);
    }
    nextOverrides.removeWhere((_, ids) => ids.isEmpty);

    return updateSettings(
      _settings.copyWith(
        hiddenGlobalDrinkIds: hiddenIds,
        globalDrinkOrderOverrides: nextOverrides,
      ),
    );
  }

  Future<bool> hideGlobalCategory(DrinkCategory category) async {
    if (!_defaultCatalog.any((drink) => drink.category == category)) {
      return false;
    }
    final hiddenCategories = _settings.hiddenGlobalDrinkCategories.toList(
      growable: true,
    );
    if (hiddenCategories.contains(category)) {
      return true;
    }
    hiddenCategories.add(category);
    return updateSettings(
      _settings.copyWith(hiddenGlobalDrinkCategories: hiddenCategories),
    );
  }

  Future<bool> showGlobalDrink(String drinkId) async {
    if (!_defaultCatalog.any((drink) => drink.id == drinkId)) {
      return false;
    }
    final hiddenIds = _settings.hiddenGlobalDrinkIds.toList(growable: true);
    if (!hiddenIds.remove(drinkId)) {
      return true;
    }
    return updateSettings(_settings.copyWith(hiddenGlobalDrinkIds: hiddenIds));
  }

  Future<bool> showGlobalCategory(DrinkCategory category) async {
    final hiddenCategories = _settings.hiddenGlobalDrinkCategories.toList(
      growable: true,
    );
    if (!hiddenCategories.remove(category)) {
      return true;
    }
    return updateSettings(
      _settings.copyWith(hiddenGlobalDrinkCategories: hiddenCategories),
    );
  }

  String? takeFlashMessage(AppLocalizations l10n) {
    final message = _flashMessage;
    _flashMessage = null;
    if (message == null) {
      return null;
    }
    return switch (message.kind) {
      _FlashMessageKind.welcomeToGlassTrail => l10n.welcomeToGlassTrail,
      _FlashMessageKind.welcomeBack => l10n.welcomeBack,
      _FlashMessageKind.profileUpdated => l10n.profileUpdated,
      _FlashMessageKind.customDrinkSaved => l10n.customDrinkSaved,
      _FlashMessageKind.drinkLogged => l10n.drinkLogged(
        localizedDrinkName(
          message.drinkId!,
          message.fallbackDrinkName!,
          l10n.locale.languageCode,
        ),
      ),
      _FlashMessageKind.drinkEntryUpdated => l10n.entryUpdated,
      _FlashMessageKind.drinkEntryDeleted => l10n.entryDeleted,
      _FlashMessageKind.genericError => l10n.somethingWentWrong,
      _FlashMessageKind.raw => _localizedRawMessage(message.rawMessage!, l10n),
    };
  }

  String localizedDrinkName(
    String drinkId,
    String fallbackName,
    String localeCode,
  ) {
    for (final drink in allDrinks) {
      if (drink.id == drinkId) {
        return drink.displayName(localeCode);
      }
    }
    return fallbackName;
  }

  String localizedEntryDrinkName(DrinkEntry entry, {String? localeCode}) {
    return localizedDrinkName(
      entry.drinkId,
      entry.drinkName,
      localeCode ?? settings.localeCode,
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) async {
    return _guardFor(AppBusyAction.signUp, () async {
      _currentUser = await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
        birthday: normalizeBirthdayOrNull(birthday),
        profileImagePath: profileImagePath,
      );
      await _reloadUserScope();
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.welcomeToGlassTrail,
      );
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _guardFor(AppBusyAction.signIn, () async {
      _currentUser = await _repository.signIn(email: email, password: password);
      await _reloadUserScope();
      _flashMessage = const _FlashMessage.simple(_FlashMessageKind.welcomeBack);
    });
  }

  Future<bool> signOut() async {
    return _guardFor(AppBusyAction.signOut, () async {
      await _repository.signOut();
      _currentUser = null;
      _customDrinks = const <DrinkDefinition>[];
      _entries = const <DrinkEntry>[];
    });
  }

  Future<bool> updateProfile({
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
    bool clearBirthday = false,
    bool clearProfileImage = false,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.updateProfile, () async {
      _currentUser = await _repository.updateProfile(
        user.copyWith(
          displayName: displayName.trim(),
          birthday: normalizeBirthdayOrNull(birthday),
          clearBirthday: clearBirthday,
          profileImagePath: profileImagePath,
          clearProfileImage: clearProfileImage,
        ),
      );
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.profileUpdated,
      );
    });
  }

  Future<bool> saveCustomDrink({
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    String? imagePath,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.saveCustomDrink, () async {
      final drink = await _repository.saveCustomDrink(
        userId: user.id,
        drinkId: drinkId,
        name: name,
        category: category,
        volumeMl: volumeMl,
        imagePath: imagePath,
      );

      final next = [..._customDrinks];
      final index = next.indexWhere((candidate) => candidate.id == drink.id);
      if (index == -1) {
        next.add(drink);
      } else {
        next[index] = drink;
      }
      next.sort((left, right) => left.name.compareTo(right.name));
      _customDrinks = next;
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.customDrinkSaved,
      );
    });
  }

  Future<bool> addDrinkEntry({
    required DrinkDefinition drink,
    required double? volumeMl,
    String? comment,
    String? imagePath,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.addDrinkEntry, () async {
      final entry = await _repository.addDrinkEntry(
        user: user,
        drink: drink,
        volumeMl: volumeMl,
        comment: comment,
        imagePath: imagePath,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        locationAddress: locationAddress,
      );
      _entries = [entry, ..._entries]
        ..sort((left, right) => right.consumedAt.compareTo(left.consumedAt));
      _flashMessage = _FlashMessage.drinkLogged(
        drinkId: entry.drinkId,
        fallbackDrinkName: entry.drinkName,
      );
    });
  }

  Future<bool> updateSettings(UserSettings settings) async {
    final user = _currentUser;
    if (user == null) {
      _settings = settings;
      notifyListeners();
      return true;
    }
    return _guardFor(AppBusyAction.updateSettings, () async {
      _settings = await _repository.saveSettings(user.id, settings);
    });
  }

  Future<bool> updateDrinkEntry({
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.updateDrinkEntry, () async {
      final updated = await _repository.updateDrinkEntry(
        user: user,
        entry: entry,
        comment: comment,
        imagePath: imagePath,
      );
      _entries =
          _entries
              .map(
                (candidate) => candidate.id == updated.id ? updated : candidate,
              )
              .toList(growable: false)
            ..sort(
              (left, right) => right.consumedAt.compareTo(left.consumedAt),
            );
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.drinkEntryUpdated,
      );
    });
  }

  Future<bool> deleteDrinkEntry(DrinkEntry entry) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.deleteDrinkEntry, () async {
      await _repository.deleteDrinkEntry(userId: user.id, entry: entry);
      _entries = _entries
          .where((candidate) => candidate.id != entry.id)
          .toList(growable: false);
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.drinkEntryDeleted,
      );
    });
  }

  Future<bool> refreshData() async {
    return _guard(() async {
      await _reloadAppData();
    });
  }

  Future<void> _initialize() async {
    final defaultCatalogFuture = _repository.loadDefaultCatalog();
    final currentUserFuture = _repository.restoreSession();

    _defaultCatalog = await defaultCatalogFuture;
    _currentUser = await currentUserFuture;
    if (_currentUser != null) {
      await _reloadUserScope();
    }
  }

  Future<void> _reloadAppData() async {
    final defaultCatalogFuture = _repository.loadDefaultCatalog();
    final user = _currentUser;
    final customDrinksFuture = user == null
        ? null
        : _repository.loadCustomDrinks(user.id);
    final entriesFuture = user == null
        ? null
        : _repository.loadEntries(user.id);
    final settingsFuture = user == null
        ? null
        : _repository.loadSettings(user.id);

    _defaultCatalog = await defaultCatalogFuture;
    if (user == null) {
      return;
    }

    _customDrinks = await customDrinksFuture!;
    _entries = await entriesFuture!;
    _settings = await settingsFuture!;
  }

  Future<void> _reloadUserScope() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    final customDrinksFuture = _repository.loadCustomDrinks(user.id);
    final entriesFuture = _repository.loadEntries(user.id);
    final settingsFuture = _repository.loadSettings(user.id);

    _customDrinks = await customDrinksFuture;
    _entries = await entriesFuture;
    _settings = await settingsFuture;
  }

  Set<String> _hiddenGlobalDrinkIdSet() =>
      _settings.hiddenGlobalDrinkIds.toSet();

  Set<DrinkCategory> _hiddenGlobalCategorySet() =>
      _settings.hiddenGlobalDrinkCategories.toSet();

  List<String> _globalOrderOverrideForCategory(DrinkCategory category) {
    return _settings.globalDrinkOrderOverrides[category] ?? const <String>[];
  }

  int _localizedDrinkComparer(DrinkDefinition left, DrinkDefinition right) {
    return left
        .displayName(_settings.localeCode)
        .compareTo(right.displayName(_settings.localeCode));
  }

  Map<DrinkCategory, List<String>> _copyGlobalDrinkOrderOverrides() {
    return <DrinkCategory, List<String>>{
      for (final entry in _settings.globalDrinkOrderOverrides.entries)
        entry.key: entry.value.toList(growable: true),
    };
  }

  List<DrinkDefinition> _sortedCustomDrinks() =>
      _customDrinks.toList(growable: false)..sort(_localizedDrinkComparer);

  List<String> _sanitizeOrderOverrideIds(
    List<String> orderedDrinkIds, {
    required Set<String> allowedIds,
  }) {
    final result = <String>[];
    for (final id in orderedDrinkIds) {
      if (allowedIds.contains(id) && !result.contains(id)) {
        result.add(id);
      }
    }
    for (final id in allowedIds) {
      if (!result.contains(id)) {
        result.add(id);
      }
    }
    return result;
  }

  Future<bool> _guard(Future<void> Function() action) async {
    return _guardInternal(action);
  }

  Future<bool> _guardFor(
    AppBusyAction action,
    Future<void> Function() body,
  ) async {
    return _guardInternal(body, busyAction: action);
  }

  Future<bool> _guardInternal(
    Future<void> Function() action, {
    AppBusyAction? busyAction,
  }) async {
    _isBusy = true;
    _busyAction = busyAction;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (error) {
      _flashMessage = _FlashMessage.raw(error.message);
      return false;
    } catch (_) {
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.genericError,
      );
      return false;
    } finally {
      _isBusy = false;
      _busyAction = null;
      notifyListeners();
    }
  }

  String _localizedRawMessage(String message, AppLocalizations l10n) {
    return switch (message) {
      'An account with that email already exists.' => l10n.accountAlreadyExists,
      'The email or password is incorrect.' => l10n.invalidCredentials,
      'The profile could not be updated.' => l10n.profileUpdateFailed,
      'You already have a custom drink with that name.' =>
        l10n.customDrinkAlreadyExists,
      'Sign-up did not return a user.' => l10n.signUpMissingUser,
      'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.' =>
        l10n.signUpConfirmationRequired,
      'The drink entry could not be updated.' => l10n.entryUpdateFailed,
      'The drink entry could not be deleted.' => l10n.entryDeleteFailed,
      'Something went wrong. Please try again.' => l10n.somethingWentWrong,
      _ => message,
    };
  }
}
