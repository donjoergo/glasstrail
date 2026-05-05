import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:glasstrail/l10n/app_localizations.dart';

import 'app_routes.dart';
import 'backend_config.dart';
import 'beer_with_me_import.dart';
import 'birthday.dart';
import 'friend_stats_profile.dart';
import 'l10n_extensions.dart';
import 'models.dart';
import 'push_notification_service.dart';
import 'repository/app_repository.dart';
import 'repository/repository_factory.dart';
import 'stats_calculator.dart';

enum _FlashMessageKind {
  welcomeToGlassTrail,
  welcomeBack,
  profileUpdated,
  customDrinkSaved,
  customDrinkDeleted,
  drinkLogged,
  drinkEntryUpdated,
  drinkEntryDeleted,
  friendRequestSent,
  friendRequestAccepted,
  friendRequestRejected,
  friendRequestCanceled,
  friendRemoved,
  genericError,
  raw,
}

enum AppBusyAction {
  signIn,
  signUp,
  signOut,
  updateProfile,
  saveCustomDrink,
  deleteCustomDrink,
  addDrinkEntry,
  importBeerWithMe,
  updateSettings,
  updateDrinkEntry,
  deleteDrinkEntry,
  loadFriendProfile,
  sendFriendRequest,
  acceptFriendRequest,
  rejectFriendRequest,
  cancelFriendRequest,
  removeFriend,
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

@immutable
class BeerWithMeImportProgress {
  const BeerWithMeImportProgress({
    required this.totalCount,
    required this.processedCount,
    required this.importedCount,
    required this.skippedDuplicateCount,
    required this.errorCount,
  });

  final int totalCount;
  final int processedCount;
  final int importedCount;
  final int skippedDuplicateCount;
  final int errorCount;

  double get progressValue {
    if (totalCount <= 0) {
      return 0;
    }
    final value = processedCount / totalCount;
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}

class AppController extends ChangeNotifier {
  AppController._(
    this._repository, {
    PushNotificationService pushNotificationService =
        const DisabledPushNotificationService(),
  }) : _pushNotificationService = pushNotificationService;

  static const _feedPageSize = 20;

  final AppRepository _repository;
  final PushNotificationService _pushNotificationService;

  AppUser? _currentUser;
  UserSettings _settings = UserSettings.defaults();
  List<DrinkDefinition> _defaultCatalog = const <DrinkDefinition>[];
  List<DrinkDefinition> _customDrinks = const <DrinkDefinition>[];
  List<DrinkEntry> _entries = const <DrinkEntry>[];
  List<FeedDrinkPost> _feedPosts = const <FeedDrinkPost>[];
  FeedDrinkPostCursor? _feedCursor;
  bool _hasMoreFeedPosts = false;
  bool _isLoadingMoreFeedPosts = false;
  List<FriendConnection> _friendConnections = const <FriendConnection>[];
  List<AppNotification> _notifications = const <AppNotification>[];
  final Map<String, DateTime> _notificationReadOverrides = <String, DateTime>{};
  bool _isBusy = false;
  AppBusyAction? _busyAction;
  BeerWithMeImportProgress? _beerWithMeImportProgress;
  bool _cancelBeerWithMeImportRequested = false;
  _FlashMessage? _flashMessage;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  StreamSubscription<PushDeviceToken>? _pushTokenSubscription;
  PushDeviceToken? _registeredPushToken;
  String? _registeredPushTokenUserId;

  static Future<AppController> bootstrap({
    BackendConfig? backendConfig,
    PushNotificationService pushNotificationService =
        const DisabledPushNotificationService(),
  }) async {
    final repository = await createRepository(backendConfig: backendConfig);
    final controller = AppController._(
      repository,
      pushNotificationService: pushNotificationService,
    );
    await controller._initialize();
    return controller;
  }

  static Future<AppController> bootstrapWithRepository(
    AppRepository repository, {
    PushNotificationService pushNotificationService =
        const DisabledPushNotificationService(),
  }) async {
    final controller = AppController._(
      repository,
      pushNotificationService: pushNotificationService,
    );
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
  List<FeedDrinkPost> get feedPosts => List.unmodifiable(_feedPosts);
  bool get hasMoreFeedPosts => _hasMoreFeedPosts;
  bool get isLoadingMoreFeedPosts => _isLoadingMoreFeedPosts;
  List<FriendConnection> get friendConnections =>
      List.unmodifiable(_friendConnections);
  List<FriendConnection> get friends => List.unmodifiable(
    _friendConnections.where((connection) => connection.isAccepted),
  );
  List<FriendConnection> get incomingFriendRequests => List.unmodifiable(
    _friendConnections.where(
      (connection) => connection.isPending && connection.isIncoming,
    ),
  );
  List<FriendConnection> get outgoingFriendRequests => List.unmodifiable(
    _friendConnections.where(
      (connection) => connection.isPending && connection.isOutgoing,
    ),
  );
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationCount =>
      _notifications.where((notification) => notification.isUnread).length;
  bool get isBusy => _isBusy;
  AppBusyAction? get busyAction => _busyAction;
  BeerWithMeImportProgress? get beerWithMeImportProgress =>
      _beerWithMeImportProgress;
  bool get isBeerWithMeImportCancellationRequested =>
      _cancelBeerWithMeImportRequested;
  bool get isAuthenticated => _currentUser != null;
  String get backendLabel => _repository.backendLabel;
  bool get usesRemoteBackend => _repository.usesRemoteBackend;
  AppStatistics get statistics => StatsCalculator.fromEntries(_entries);

  bool isBusyFor(AppBusyAction action) => _busyAction == action;

  @override
  void dispose() {
    unawaited(_notificationSubscription?.cancel());
    unawaited(_pushTokenSubscription?.cancel());
    super.dispose();
  }

  bool requestBeerWithMeImportCancellation() {
    if (_busyAction != AppBusyAction.importBeerWithMe ||
        _cancelBeerWithMeImportRequested) {
      return false;
    }
    _cancelBeerWithMeImportRequested = true;
    notifyListeners();
    return true;
  }

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
      _FlashMessageKind.customDrinkDeleted => l10n.customDrinkDeleted,
      _FlashMessageKind.drinkLogged => l10n.drinkLogged(
        localizedDrinkName(
          message.drinkId!,
          message.fallbackDrinkName!,
          l10n.locale.languageCode,
        ),
      ),
      _FlashMessageKind.drinkEntryUpdated => l10n.entryUpdated,
      _FlashMessageKind.drinkEntryDeleted => l10n.entryDeleted,
      _FlashMessageKind.friendRequestSent => l10n.friendRequestSent,
      _FlashMessageKind.friendRequestAccepted => l10n.friendRequestAccepted,
      _FlashMessageKind.friendRequestRejected => l10n.friendRequestRejected,
      _FlashMessageKind.friendRequestCanceled => l10n.friendRequestCanceled,
      _FlashMessageKind.friendRemoved => l10n.friendRemoved,
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

  String localizedFeedPostDrinkName(FeedDrinkPost post, {String? localeCode}) {
    return localizedEntryDrinkName(post.entry, localeCode: localeCode);
  }

  String localizedNotificationTitle(
    AppNotification notification,
    AppLocalizations l10n,
  ) {
    if (notification.type != AppNotificationTypes.friendDrinkLogged) {
      return notification.title(l10n);
    }
    return appNotificationTitle(
      l10n: l10n,
      type: notification.type,
      senderDisplayName: notification.templateSenderDisplayName,
      drinkName: localizedDrinkName(
        notification.templateDrinkId ?? '',
        notification.templateDrinkName ?? '',
        l10n.locale.languageCode,
      ),
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
      await _unregisterPushTokenBestEffort();
      _currentUser = await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
        birthday: normalizeBirthdayOrNull(birthday),
        profileImagePath: profileImagePath,
      );
      _notificationReadOverrides.clear();
      await _reloadUserScope();
      _subscribeToNotifications();
      await _registerPushTokenBestEffort();
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.welcomeToGlassTrail,
      );
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _guardFor(AppBusyAction.signIn, () async {
      await _unregisterPushTokenBestEffort();
      _currentUser = await _repository.signIn(email: email, password: password);
      _notificationReadOverrides.clear();
      await _reloadUserScope();
      _subscribeToNotifications();
      await _registerPushTokenBestEffort();
      _flashMessage = const _FlashMessage.simple(_FlashMessageKind.welcomeBack);
    });
  }

  Future<bool> signOut() async {
    return _guardFor(AppBusyAction.signOut, () async {
      await _unregisterPushTokenBestEffort();
      unawaited(_notificationSubscription?.cancel());
      _notificationSubscription = null;
      await _repository.signOut();
      _currentUser = null;
      _customDrinks = const <DrinkDefinition>[];
      _entries = const <DrinkEntry>[];
      _feedPosts = const <FeedDrinkPost>[];
      _feedCursor = null;
      _hasMoreFeedPosts = false;
      _friendConnections = const <FriendConnection>[];
      _notifications = const <AppNotification>[];
      _notificationReadOverrides.clear();
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
    bool isAlcoholFree = false,
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
        isAlcoholFree: switch (category) {
          DrinkCategory.nonAlcoholic => true,
          DrinkCategory.beer => isAlcoholFree,
          _ => false,
        },
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

  Future<bool> deleteCustomDrink(DrinkDefinition drink) async {
    final user = _currentUser;
    if (user == null || !drink.isCustom) {
      return false;
    }
    return _guardFor(AppBusyAction.deleteCustomDrink, () async {
      await _repository.deleteCustomDrink(userId: user.id, drink: drink);
      _customDrinks = _customDrinks
          .where((candidate) => candidate.id != drink.id)
          .toList(growable: false);
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.customDrinkDeleted,
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
      _upsertFeedPost(
        FeedDrinkPost(
          entry: entry,
          authorProfile: FriendProfile.fromUser(user),
          isOwnEntry: true,
        ),
      );
      _flashMessage = _FlashMessage.drinkLogged(
        drinkId: entry.drinkId,
        fallbackDrinkName: entry.drinkName,
      );
    });
  }

  Future<BeerWithMeImportResult> importBeerWithMeExport(
    BeerWithMeImportFile exportFile,
  ) async {
    final user = _currentUser;
    final l10n = lookupAppLocalizations(Locale(_settings.localeCode));
    final totalRows = exportFile.rows.length;
    if (user == null) {
      return BeerWithMeImportResult(
        totalRows: totalRows,
        processedCount: 0,
        importedCount: 0,
        skippedDuplicateCount: 0,
        errors: <BeerWithMeImportError>[
          BeerWithMeImportError(rowNumber: 0, message: l10n.somethingWentWrong),
        ],
      );
    }

    _isBusy = true;
    _busyAction = AppBusyAction.importBeerWithMe;
    _cancelBeerWithMeImportRequested = false;
    _beerWithMeImportProgress = BeerWithMeImportProgress(
      totalCount: totalRows,
      processedCount: 0,
      importedCount: 0,
      skippedDuplicateCount: 0,
      errorCount: 0,
    );
    notifyListeners();

    try {
      final entries = <DrinkEntry>[..._entries];
      final knownImportIds = _entries
          .where(
            (entry) =>
                entry.importSource == beerWithMeImportSource &&
                entry.importSourceId != null &&
                entry.importSourceId!.isNotEmpty,
          )
          .map((entry) => entry.importSourceId!)
          .toSet();
      final drinksById = <String, DrinkDefinition>{
        for (final drink in allDrinks) drink.id: drink,
      };

      var importedCount = 0;
      var skippedDuplicateCount = 0;
      var processedCount = 0;
      var wasCancelled = false;
      final errors = <BeerWithMeImportError>[];

      void publishProgress() {
        _beerWithMeImportProgress = BeerWithMeImportProgress(
          totalCount: totalRows,
          processedCount: processedCount,
          importedCount: importedCount,
          skippedDuplicateCount: skippedDuplicateCount,
          errorCount: errors.length,
        );
        notifyListeners();
      }

      for (final row in exportFile.rows) {
        if (_cancelBeerWithMeImportRequested) {
          wasCancelled = true;
          break;
        }
        try {
          BeerWithMeImportRecord record;
          try {
            record = decodeBeerWithMeImportRow(row);
          } on BeerWithMeImportRowException catch (error) {
            errors.add(
              BeerWithMeImportError(
                rowNumber: error.rowNumber,
                sourceId: error.sourceId,
                glassType: error.glassType,
                message: _beerWithMeRowErrorMessage(l10n, error),
              ),
            );
            continue;
          } catch (_) {
            errors.add(
              BeerWithMeImportError(
                rowNumber: row.rowNumber,
                message: l10n.beerWithMeImportInvalidEntry,
              ),
            );
            continue;
          }

          if (knownImportIds.contains(record.sourceId)) {
            skippedDuplicateCount++;
            continue;
          }

          final mappedDrinkId = beerWithMeGlassTypeToDrinkId[record.glassType];
          if (mappedDrinkId == null) {
            errors.add(
              BeerWithMeImportError(
                rowNumber: record.rowNumber,
                sourceId: record.sourceId,
                glassType: record.glassType,
                message: l10n.beerWithMeImportUnknownGlassType(
                  record.glassType,
                ),
              ),
            );
            continue;
          }

          final drink = drinksById[mappedDrinkId];
          if (drink == null) {
            errors.add(
              BeerWithMeImportError(
                rowNumber: record.rowNumber,
                sourceId: record.sourceId,
                glassType: record.glassType,
                message: l10n.beerWithMeImportMissingMappedDrink(
                  record.glassType,
                ),
              ),
            );
            continue;
          }

          try {
            final entry = await _repository.addDrinkEntry(
              user: user,
              drink: drink,
              volumeMl: drink.volumeMl,
              locationLatitude: record.locationLatitude,
              locationLongitude: record.locationLongitude,
              locationAddress: record.locationAddress,
              consumedAt: record.consumedAt,
              importSource: beerWithMeImportSource,
              importSourceId: record.sourceId,
            );
            entries.add(entry);
            knownImportIds.add(record.sourceId);
            importedCount++;
          } on AppException catch (error) {
            final localizedMessage = _localizedRawMessage(error.message, l10n);
            if (localizedMessage == l10n.beerWithMeImportAlreadyImported) {
              skippedDuplicateCount++;
              knownImportIds.add(record.sourceId);
              continue;
            }
            errors.add(
              BeerWithMeImportError(
                rowNumber: record.rowNumber,
                sourceId: record.sourceId,
                glassType: record.glassType,
                message: localizedMessage,
              ),
            );
          } catch (_) {
            errors.add(
              BeerWithMeImportError(
                rowNumber: record.rowNumber,
                sourceId: record.sourceId,
                glassType: record.glassType,
                message: l10n.somethingWentWrong,
              ),
            );
          }
        } finally {
          processedCount++;
          publishProgress();
        }
      }

      entries.sort(
        (left, right) => right.consumedAt.compareTo(left.consumedAt),
      );
      _entries = entries;
      await _reloadInitialFeedPosts(user.id);
      return BeerWithMeImportResult(
        totalRows: totalRows,
        processedCount: processedCount,
        importedCount: importedCount,
        skippedDuplicateCount: skippedDuplicateCount,
        errors: List<BeerWithMeImportError>.unmodifiable(errors),
        wasCancelled: wasCancelled,
      );
    } finally {
      _cancelBeerWithMeImportRequested = false;
      _beerWithMeImportProgress = null;
      _isBusy = false;
      _busyAction = null;
      notifyListeners();
    }
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
      _feedPosts =
          _feedPosts
              .map(
                (post) => post.entry.id == updated.id
                    ? FeedDrinkPost(
                        entry: updated,
                        authorProfile: post.authorProfile,
                        isOwnEntry: post.isOwnEntry,
                      )
                    : post,
              )
              .toList(growable: false)
            ..sort(_compareFeedPosts);
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
      _feedPosts = _feedPosts
          .where((post) => post.entry.id != entry.id)
          .toList(growable: false);
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.drinkEntryDeleted,
      );
    });
  }

  Future<FriendProfile?> loadOwnFriendProfile() async {
    final user = _currentUser;
    if (user == null) {
      return null;
    }
    return _loadFriendProfileFor(
      AppBusyAction.loadFriendProfile,
      () => _repository.getOwnFriendProfile(user.id),
    );
  }

  Future<FriendStatsProfile?> loadFriendStatsProfile(
    String friendUserId,
  ) async {
    final user = _currentUser;
    final normalizedFriendUserId = friendUserId.trim();
    if (user == null || normalizedFriendUserId.isEmpty) {
      return null;
    }
    return _loadFriendProfileFor(
      AppBusyAction.loadFriendProfile,
      () => _repository.loadFriendStatsProfile(
        userId: user.id,
        friendUserId: normalizedFriendUserId,
      ),
    );
  }

  Future<FriendProfile?> resolveFriendProfileLink(String shareCode) async {
    final normalizedCode = shareCode.trim();
    if (normalizedCode.isEmpty) {
      _flashMessage = const _FlashMessage.raw('The profile link is invalid.');
      notifyListeners();
      return null;
    }
    return _loadFriendProfileFor(
      AppBusyAction.loadFriendProfile,
      () => _repository.resolveFriendProfileLink(normalizedCode),
    );
  }

  Future<PublicFriendProfile?> resolvePublicFriendProfileLink(
    String shareCode,
  ) async {
    final normalizedCode = shareCode.trim();
    if (normalizedCode.isEmpty) {
      _flashMessage = const _FlashMessage.raw('The profile link is invalid.');
      notifyListeners();
      return null;
    }
    return _loadFriendProfileFor(
      AppBusyAction.loadFriendProfile,
      () => _repository.resolvePublicFriendProfileLink(normalizedCode),
    );
  }

  Future<bool> sendFriendRequestToProfile(String shareCode) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.sendFriendRequest, () async {
      _friendConnections = await _repository.sendFriendRequestToProfile(
        userId: user.id,
        shareCode: shareCode,
      );
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.friendRequestSent,
      );
    });
  }

  Future<bool> acceptFriendRequest(FriendConnection connection) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.acceptFriendRequest, () async {
      _friendConnections = await _repository.acceptFriendRequest(
        userId: user.id,
        relationshipId: connection.id,
      );
      await _reloadInitialFeedPosts(user.id);
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.friendRequestAccepted,
      );
    });
  }

  Future<bool> rejectFriendRequest(FriendConnection connection) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.rejectFriendRequest, () async {
      _friendConnections = await _repository.rejectFriendRequest(
        userId: user.id,
        relationshipId: connection.id,
      );
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.friendRequestRejected,
      );
    });
  }

  Future<bool> cancelFriendRequest(FriendConnection connection) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.cancelFriendRequest, () async {
      _friendConnections = await _repository.cancelFriendRequest(
        userId: user.id,
        relationshipId: connection.id,
      );
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.friendRequestCanceled,
      );
    });
  }

  Future<bool> removeFriend(FriendConnection connection) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }
    return _guardFor(AppBusyAction.removeFriend, () async {
      _friendConnections = await _repository.removeFriend(
        userId: user.id,
        friendUserId: connection.profile.id,
      );
      await _reloadInitialFeedPosts(user.id);
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.friendRemoved,
      );
    });
  }

  Future<bool> markNotificationsRead(List<String> notificationIds) async {
    final user = _currentUser;
    final ids = notificationIds.toSet();
    if (user == null || ids.isEmpty) {
      return false;
    }

    final readAt = DateTime.now();
    final optimisticReadAtById = <String, DateTime>{};
    var changed = false;
    _notifications = _notifications
        .map((notification) {
          if (!ids.contains(notification.id) || notification.isRead) {
            return notification;
          }
          changed = true;
          optimisticReadAtById[notification.id] = readAt;
          _notificationReadOverrides[notification.id] = readAt;
          return notification.copyWith(readAt: readAt);
        })
        .toList(growable: false);
    if (changed) {
      notifyListeners();
    }

    try {
      _notifications = _mergeNotificationReadOverrides(
        await _repository.markNotificationsRead(
          userId: user.id,
          notificationIds: ids.toList(growable: false),
        ),
      );
      notifyListeners();
      return true;
    } catch (_) {
      if (optimisticReadAtById.isNotEmpty) {
        for (final id in optimisticReadAtById.keys) {
          _notificationReadOverrides.remove(id);
        }
        _notifications = _notifications
            .map((notification) {
              final optimisticReadAt = optimisticReadAtById[notification.id];
              if (optimisticReadAt == null ||
                  notification.readAt != optimisticReadAt) {
                return notification;
              }
              return notification.copyWith(clearReadAt: true);
            })
            .toList(growable: false);
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> markAllNotificationsRead() async {
    return markNotificationsRead(
      _notifications
          .where((notification) => notification.isUnread)
          .map((notification) => notification.id)
          .toList(growable: false),
    );
  }

  Future<bool> refreshData() async {
    return _guard(() async {
      await _reloadAppData();
      _subscribeToNotifications();
    });
  }

  Future<bool> refreshForNotification(AppNotification notification) {
    return _refreshForNotificationType(
      type: notification.type,
      routeName: notification.metadata['route'] as String?,
    );
  }

  Future<bool> refreshForNotificationOpen({
    required String routeName,
    String? notificationId,
  }) {
    final notification = _notificationById(notificationId);
    if (notification != null) {
      return refreshForNotification(notification);
    }
    return _refreshForNotificationRoute(routeName);
  }

  Future<bool> loadMoreFeedPosts() async {
    final user = _currentUser;
    if (user == null || !_hasMoreFeedPosts || _isLoadingMoreFeedPosts) {
      return false;
    }

    _isLoadingMoreFeedPosts = true;
    notifyListeners();
    try {
      final page = await _repository.loadFeedDrinkPosts(
        userId: user.id,
        cursor: _feedCursor,
        limit: _feedPageSize,
      );
      if (_currentUser?.id != user.id) {
        return true;
      }
      _feedPosts = _mergeFeedPosts(_feedPosts, page.posts);
      _feedCursor = page.cursor;
      _hasMoreFeedPosts = page.hasMore;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoadingMoreFeedPosts = false;
      notifyListeners();
    }
  }

  Future<bool> refreshFriendConnections() async {
    final user = _currentUser;
    if (user == null) {
      return true;
    }

    try {
      final friendConnections = await _repository.loadFriendConnections(
        user.id,
      );
      if (_currentUser?.id != user.id) {
        return true;
      }
      _friendConnections = friendConnections;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refreshFriendConnectionsAndFeed() async {
    final user = _currentUser;
    if (user == null) {
      return true;
    }

    try {
      late List<FriendConnection> friendConnections;
      late FeedDrinkPostPage feedPostsPage;
      final friendConnectionsFuture = _repository.loadFriendConnections(
        user.id,
      );
      final feedPostsFuture = _repository.loadFeedDrinkPosts(
        userId: user.id,
        limit: _feedPageSize,
      );
      await Future.wait<void>(<Future<void>>[
        friendConnectionsFuture.then((value) => friendConnections = value),
        feedPostsFuture.then((value) => feedPostsPage = value),
      ]);
      if (_currentUser?.id != user.id) {
        return true;
      }
      _friendConnections = friendConnections;
      _applyFeedPostPage(feedPostsPage);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  AppNotification? _notificationById(String? notificationId) {
    if (notificationId == null || notificationId.isEmpty) {
      return null;
    }
    for (final notification in _notifications) {
      if (notification.id == notificationId) {
        return notification;
      }
    }
    return null;
  }

  Future<bool> _refreshForNotificationType({
    required String type,
    String? routeName,
  }) {
    return switch (type) {
      AppNotificationTypes.friendDrinkLogged => refreshData(),
      AppNotificationTypes.friendRequestSent ||
      AppNotificationTypes.friendRequestAccepted ||
      AppNotificationTypes.friendRequestRejected ||
      AppNotificationTypes.friendRemoved => _refreshFriendConnectionsAndFeed(),
      _ => _refreshForNotificationRoute(routeName),
    };
  }

  Future<bool> _refreshForNotificationRoute(String? routeName) {
    final route = AppRoutes.normalize(routeName);
    if (route == AppRoutes.feed) {
      return refreshData();
    }
    if (route == AppRoutes.profile || AppRoutes.isFriendProfileRoute(route)) {
      return _refreshFriendConnectionsAndFeed();
    }
    return SynchronousFuture<bool>(true);
  }

  Future<void> _initialize() async {
    final defaultCatalogFuture = _repository.loadDefaultCatalog();
    final currentUserFuture = _repository.restoreSession();

    _defaultCatalog = await defaultCatalogFuture;
    _currentUser = await currentUserFuture;
    if (_currentUser != null) {
      await _reloadUserScope();
      _subscribeToNotifications();
      await _registerPushTokenBestEffort();
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
    final feedPostsFuture = user == null
        ? null
        : _repository.loadFeedDrinkPosts(userId: user.id, limit: _feedPageSize);
    final settingsFuture = user == null
        ? null
        : _repository.loadSettings(user.id);
    final friendsFuture = user == null
        ? null
        : _repository.loadFriendConnections(user.id);
    final notificationsFuture = user == null
        ? null
        : _repository.loadNotifications(user.id);

    _defaultCatalog = await defaultCatalogFuture;
    if (user == null) {
      _notifications = const <AppNotification>[];
      _feedPosts = const <FeedDrinkPost>[];
      _feedCursor = null;
      _hasMoreFeedPosts = false;
      _notificationReadOverrides.clear();
      return;
    }

    _customDrinks = await customDrinksFuture!;
    _entries = await entriesFuture!;
    _applyFeedPostPage(await feedPostsFuture!);
    _settings = await settingsFuture!;
    _friendConnections = await friendsFuture!;
    _notifications = _mergeNotificationReadOverrides(
      await notificationsFuture!,
    );
  }

  Future<void> _reloadUserScope() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    final customDrinksFuture = _repository.loadCustomDrinks(user.id);
    final entriesFuture = _repository.loadEntries(user.id);
    final feedPostsFuture = _repository.loadFeedDrinkPosts(
      userId: user.id,
      limit: _feedPageSize,
    );
    final settingsFuture = _repository.loadSettings(user.id);
    final friendsFuture = _repository.loadFriendConnections(user.id);
    final notificationsFuture = _repository.loadNotifications(user.id);

    _customDrinks = await customDrinksFuture;
    _entries = await entriesFuture;
    _applyFeedPostPage(await feedPostsFuture);
    _settings = await settingsFuture;
    _friendConnections = await friendsFuture;
    _notifications = _mergeNotificationReadOverrides(await notificationsFuture);
  }

  void _subscribeToNotifications() {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    unawaited(_notificationSubscription?.cancel());
    _notificationSubscription = _repository.watchNotifications(user.id).listen((
      notifications,
    ) {
      if (_currentUser?.id != user.id) {
        return;
      }
      _notifications = _mergeNotificationReadOverrides(notifications);
      notifyListeners();
    }, onError: (_) {});
  }

  List<AppNotification> _mergeNotificationReadOverrides(
    List<AppNotification> notifications,
  ) {
    return notifications
        .map((notification) {
          final overrideReadAt = _notificationReadOverrides[notification.id];
          if (overrideReadAt == null || notification.isRead) {
            return notification;
          }
          return notification.copyWith(readAt: overrideReadAt);
        })
        .toList(growable: false);
  }

  Future<void> _reloadInitialFeedPosts(String userId) async {
    _applyFeedPostPage(
      await _repository.loadFeedDrinkPosts(
        userId: userId,
        limit: _feedPageSize,
      ),
    );
  }

  void _applyFeedPostPage(FeedDrinkPostPage page) {
    _feedPosts = page.posts;
    _feedCursor = page.cursor;
    _hasMoreFeedPosts = page.hasMore;
  }

  void _upsertFeedPost(FeedDrinkPost post) {
    _feedPosts = <FeedDrinkPost>[
      post,
      ..._feedPosts.where((candidate) => candidate.entry.id != post.entry.id),
    ]..sort(_compareFeedPosts);
  }

  List<FeedDrinkPost> _mergeFeedPosts(
    List<FeedDrinkPost> currentPosts,
    List<FeedDrinkPost> nextPosts,
  ) {
    final postsById = <String, FeedDrinkPost>{
      for (final post in currentPosts) post.entry.id: post,
      for (final post in nextPosts) post.entry.id: post,
    };
    return postsById.values.toList(growable: false)..sort(_compareFeedPosts);
  }

  int _compareFeedPosts(FeedDrinkPost left, FeedDrinkPost right) {
    final consumedAtComparison = right.entry.consumedAt.compareTo(
      left.entry.consumedAt,
    );
    if (consumedAtComparison != 0) {
      return consumedAtComparison;
    }
    return right.entry.id.compareTo(left.entry.id);
  }

  Future<void> _registerPushTokenBestEffort() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _pushTokenSubscription?.cancel();
    _pushTokenSubscription = _pushNotificationService.tokenRefreshes.listen(
      (token) => unawaited(_registerPushTokenForCurrentUser(token)),
      onError: (_) {},
    );

    try {
      final token = await _pushNotificationService.getDeviceToken();
      if (token != null) {
        await _registerPushTokenForCurrentUser(token);
      }
    } catch (_) {}
  }

  Future<void> _registerPushTokenForCurrentUser(PushDeviceToken token) async {
    final user = _currentUser;
    if (user == null || token.token.trim().isEmpty) {
      return;
    }

    final previousToken = _registeredPushToken;
    final previousUserId = _registeredPushTokenUserId;
    try {
      await _repository.registerNotificationDeviceToken(
        userId: user.id,
        token: token.token,
        platform: token.platform,
      );
      if (_currentUser?.id != user.id) {
        await _unregisterPushToken(token: token, userId: user.id);
        return;
      }
      _registeredPushToken = token;
      _registeredPushTokenUserId = user.id;
      if (previousToken != null &&
          previousUserId != null &&
          (previousToken.token != token.token || previousUserId != user.id)) {
        await _unregisterPushToken(
          token: previousToken,
          userId: previousUserId,
        );
      }
    } catch (_) {}
  }

  Future<void> _unregisterPushTokenBestEffort() async {
    final pushTokenSubscription = _pushTokenSubscription;
    _pushTokenSubscription = null;

    final token = _registeredPushToken;
    final userId = _registeredPushTokenUserId ?? _currentUser?.id;
    if (token == null || userId == null) {
      unawaited(pushTokenSubscription?.cancel());
      return;
    }

    await pushTokenSubscription?.cancel();

    try {
      await _unregisterPushToken(token: token, userId: userId);
      _registeredPushToken = null;
      _registeredPushTokenUserId = null;
    } catch (_) {}
  }

  Future<void> _unregisterPushToken({
    required PushDeviceToken token,
    required String userId,
  }) {
    return _repository.unregisterNotificationDeviceToken(
      userId: userId,
      token: token.token,
    );
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

  Future<T?> _loadFriendProfileFor<T>(
    AppBusyAction action,
    Future<T> Function() load,
  ) async {
    _isBusy = true;
    _busyAction = action;
    notifyListeners();
    try {
      return await load();
    } on AppException catch (error) {
      _flashMessage = _FlashMessage.raw(error.message);
      return null;
    } catch (_) {
      _flashMessage = const _FlashMessage.simple(
        _FlashMessageKind.genericError,
      );
      return null;
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
      'The custom drink could not be deleted.' => l10n.customDrinkDeleteFailed,
      'Sign-up did not return a user.' => l10n.signUpMissingUser,
      'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.' =>
        l10n.signUpConfirmationRequired,
      'This BeerWithMe entry was already imported.' =>
        l10n.beerWithMeImportAlreadyImported,
      'The drink entry could not be updated.' => l10n.entryUpdateFailed,
      'The drink entry could not be deleted.' => l10n.entryDeleteFailed,
      'The profile link is invalid.' => l10n.friendProfileLinkInvalid,
      'This friend profile is unavailable.' => l10n.friendStatsUnavailableBody,
      'You cannot add yourself as a friend.' => l10n.friendSelfRequestBlocked,
      'The friend request could not be accepted.' =>
        l10n.friendRequestAcceptFailed,
      'The friend request could not be rejected.' =>
        l10n.friendRequestRejectFailed,
      'The friend request could not be withdrawn.' =>
        l10n.friendRequestCancelFailed,
      'The friend could not be removed.' => l10n.friendRemoveFailed,
      'Something went wrong. Please try again.' => l10n.somethingWentWrong,
      _ => message,
    };
  }

  String _beerWithMeRowErrorMessage(
    AppLocalizations l10n,
    BeerWithMeImportRowException error,
  ) {
    return switch (error.code) {
      BeerWithMeImportRowErrorCode.invalidEntry =>
        l10n.beerWithMeImportInvalidEntry,
      BeerWithMeImportRowErrorCode.missingId => l10n.beerWithMeImportMissingId,
      BeerWithMeImportRowErrorCode.missingGlassType =>
        l10n.beerWithMeImportMissingGlassType,
      BeerWithMeImportRowErrorCode.missingTimestamp =>
        l10n.beerWithMeImportMissingTimestamp,
      BeerWithMeImportRowErrorCode.invalidTimestamp =>
        l10n.beerWithMeImportInvalidTimestamp,
    };
  }
}
