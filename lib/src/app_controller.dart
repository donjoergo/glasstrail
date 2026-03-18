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
  genericError,
  raw,
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
  List<DrinkDefinition> get customDrinks => List.unmodifiable(_customDrinks);
  List<DrinkEntry> get entries => List.unmodifiable(_entries);
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _currentUser != null;
  String get backendLabel => _repository.backendLabel;
  bool get usesRemoteBackend => _repository.usesRemoteBackend;
  AppStatistics get statistics => StatsCalculator.fromEntries(_entries);

  List<DrinkDefinition> get availableDrinks {
    final drinks = <DrinkDefinition>[..._defaultCatalog, ..._customDrinks];
    drinks.sort((left, right) {
      final categoryComparison = left.category.index.compareTo(
        right.category.index,
      );
      if (categoryComparison != 0) {
        return categoryComparison;
      }
      return left.name.compareTo(right.name);
    });
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
      _FlashMessageKind.genericError => l10n.somethingWentWrong,
      _FlashMessageKind.raw => _localizedRawMessage(message.rawMessage!, l10n),
    };
  }

  String localizedDrinkName(
    String drinkId,
    String fallbackName,
    String localeCode,
  ) {
    for (final drink in availableDrinks) {
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
    return _guard(() async {
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
    return _guard(() async {
      _currentUser = await _repository.signIn(email: email, password: password);
      await _reloadUserScope();
      _flashMessage = const _FlashMessage.simple(_FlashMessageKind.welcomeBack);
    });
  }

  Future<bool> signOut() async {
    return _guard(() async {
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
    return _guard(() async {
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
    return _guard(() async {
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
  }) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guard(() async {
      final entry = await _repository.addDrinkEntry(
        user: user,
        drink: drink,
        volumeMl: volumeMl,
        comment: comment,
        imagePath: imagePath,
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
    return _guard(() async {
      _settings = await _repository.saveSettings(user.id, settings);
    });
  }

  Future<void> _initialize() async {
    _defaultCatalog = await _repository.loadDefaultCatalog();
    _currentUser = await _repository.restoreSession();
    if (_currentUser != null) {
      await _reloadUserScope();
    }
  }

  Future<void> _reloadUserScope() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    _customDrinks = await _repository.loadCustomDrinks(user.id);
    _entries = await _repository.loadEntries(user.id);
    _settings = await _repository.loadSettings(user.id);
  }

  Future<bool> _guard(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (error) {
      _flashMessage = _FlashMessage.raw(error.message);
      return false;
    } catch (_) {
      _flashMessage = const _FlashMessage.simple(_FlashMessageKind.genericError);
      return false;
    } finally {
      _isBusy = false;
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
      'Something went wrong. Please try again.' => l10n.somethingWentWrong,
      _ => message,
    };
  }
}
