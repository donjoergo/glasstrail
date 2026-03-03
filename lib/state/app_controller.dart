import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:glasstrail/api/backend_api.dart';
import 'package:glasstrail/data/mock_data.dart';
import 'package:glasstrail/models/app_models.dart';

class StreakMetrics {
  const StreakMetrics({required this.current, required this.best});

  final int current;
  final int best;
}

class AppController extends ChangeNotifier {
  AppController({BackendApi? api})
      : _api = api ?? BackendApi.fromEnvironment() {
    _drinkCatalog = [...MockData.globalCatalog()];
    _friends = MockData.friends();
    _logs = MockData.initialLogs()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _badges = MockData.initialBadges()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    _feed = MockData.initialFeed(_logs, _badges)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  final BackendApi _api;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _onboardingComplete = false;

  AppUser _currentUser = MockData.me;
  late List<DrinkType> _drinkCatalog;
  List<Friend> _friends = [];
  List<DrinkLog> _logs = [];
  List<BadgeAward> _badges = [];
  List<FeedItem> _feed = [];

  bool _friendDrinkNotifications = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  String? _lastSyncError;
  bool _isRemoteSyncing = false;

  final Set<String> _cheeredLogIds = <String>{};
  LegacyImportResult? _lastImportResult;
  List<_PendingImportEntry> _pendingImportEntries = [];

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get onboardingComplete => _onboardingComplete;
  bool get usingRemoteApi => _api.enabled;
  String get apiBaseUrl => _api.baseUrl;
  String? get lastSyncError => _lastSyncError;
  bool get isRemoteSyncing => _isRemoteSyncing;

  AppUser get currentUser => _currentUser;
  List<Friend> get friends => List<Friend>.unmodifiable(_friends);
  List<Friend> get acceptedFriends =>
      _friends.where((f) => f.status == FriendshipStatus.accepted).toList();
  List<DrinkType> get drinkCatalog =>
      List<DrinkType>.unmodifiable(_drinkCatalog);
  List<DrinkLog> get logs => List<DrinkLog>.unmodifiable(_logs);
  List<BadgeAward> get badges => List<BadgeAward>.unmodifiable(_badges);
  List<FeedItem> get feed => List<FeedItem>.unmodifiable(_feed);

  bool get friendDrinkNotifications => _friendDrinkNotifications;
  TimeOfDay get quietHoursStart => _quietHoursStart;
  TimeOfDay get quietHoursEnd => _quietHoursEnd;

  LegacyImportResult? get lastImportResult => _lastImportResult;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    unawaited(_pushNotificationPrefs());
    notifyListeners();
  }

  void setFriendDrinkNotifications(bool enabled) {
    _friendDrinkNotifications = enabled;
    unawaited(_pushNotificationPrefs());
    notifyListeners();
  }

  void setQuietHours(TimeOfDay start, TimeOfDay end) {
    _quietHoursStart = start;
    _quietHoursEnd = end;
    unawaited(_pushNotificationPrefs());
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String email,
    required String password,
    required String nickname,
    required String displayName,
    String? avatarUrl,
  }) async {
    _currentUser = _currentUser.copyWith(
      nickname: nickname,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    if (_api.enabled) {
      try {
        var session = await _api.register(
          email: email,
          password: password,
          nickname: nickname,
          displayName: displayName,
        );
        session ??= await _api.login(email: email, password: password);
        if (session != null) {
          _api.setAuthToken(session.accessToken);
          _currentUser = session.user;
          _lastSyncError = null;
        }
      } catch (error) {
        _lastSyncError = 'Registration sync failed: $error';
      }
    }

    _onboardingComplete = true;
    notifyListeners();

    if (_api.enabled) {
      unawaited(_bootstrapFromApi());
    }
  }

  void logOut() {
    _api.setAuthToken(null);
    _onboardingComplete = false;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    if (_api.enabled) {
      try {
        final remoteFeed = await _api.fetchFeed();
        if (remoteFeed.isNotEmpty) {
          _feed = remoteFeed
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final remoteLogs = _feed
              .where((item) => item.log != null)
              .map((item) => item.log!)
              .toList();
          if (remoteLogs.isNotEmpty) {
            _logs = remoteLogs
              ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
          }
        }
        _lastSyncError = null;
      } catch (error) {
        _lastSyncError = 'Feed sync failed: $error';
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    _feed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addDrink({
    required DrinkType drink,
    String? comment,
    String? imagePath,
    List<String> taggedFriendIds = const <String>[],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final random = Random();
    final now = DateTime.now();
    final id = 'log_${now.microsecondsSinceEpoch}';
    final normalizedComment =
        (comment == null || comment.trim().isEmpty) ? null : comment.trim();
    final log = DrinkLog(
      id: id,
      userId: _currentUser.id,
      userName: _currentUser.displayName,
      userAvatarUrl: _currentUser.avatarUrl,
      drinkName: drink.name,
      category: drink.category,
      loggedAt: now,
      latitude: 52.52 + (random.nextDouble() - 0.5) * 0.03,
      longitude: 13.40 + (random.nextDouble() - 0.5) * 0.03,
      comment: normalizedComment,
      imageUrl: imagePath ?? drink.imageUrl,
      taggedFriends: taggedFriendIds,
    );

    _logs.insert(0, log);
    _feed.insert(
      0,
      FeedItem(
        id: 'feed_$id',
        type: FeedEventType.drinkLogged,
        createdAt: now,
        log: log,
      ),
    );

    final unlocked = _evaluateBadges();
    if (unlocked.isNotEmpty) {
      _badges.insertAll(0, unlocked);
      _feed.insert(
        0,
        FeedItem(
          id: 'feed_badges_${now.microsecondsSinceEpoch}',
          type: FeedEventType.badgesUnlocked,
          createdAt: now.add(const Duration(milliseconds: 1)),
          badges: unlocked,
        ),
      );
    }

    if (_api.enabled) {
      try {
        final remoteLog = await _api.logDrink(
          drink: drink,
          comment: comment,
          imagePath: imagePath,
          taggedFriendIds: taggedFriendIds,
        );
        if (remoteLog != null) {
          _replaceLog(tempId: id, remoteLog: remoteLog);
        }
        _lastSyncError = null;
      } catch (error) {
        _lastSyncError = 'Drink upload failed: $error';
      }
    }

    notifyListeners();
  }

  void toggleCheer(String logId) {
    final logIndex = _logs.indexWhere((log) => log.id == logId);
    if (logIndex < 0) {
      return;
    }

    final alreadyCheered = _cheeredLogIds.contains(logId);
    final updatedCount = alreadyCheered
        ? max(0, _logs[logIndex].cheersCount - 1)
        : _logs[logIndex].cheersCount + 1;

    if (alreadyCheered) {
      _cheeredLogIds.remove(logId);
    } else {
      _cheeredLogIds.add(logId);
      if (_api.enabled) {
        unawaited(
          _api.cheerPost(postId: logId).then((_) {
            _lastSyncError = null;
          }).catchError((error) {
            _lastSyncError = 'Cheer sync failed: $error';
            notifyListeners();
          }),
        );
      }
    }

    final updated = _logs[logIndex].copyWith(cheersCount: updatedCount);
    _logs[logIndex] = updated;
    _syncFeedLog(updated);
    notifyListeners();
  }

  bool hasCheered(String logId) => _cheeredLogIds.contains(logId);

  void addComment(String logId, String comment) {
    if (comment.trim().isEmpty) {
      return;
    }

    final logIndex = _logs.indexWhere((log) => log.id == logId);
    if (logIndex < 0) {
      return;
    }

    final updated = _logs[logIndex]
        .copyWith(commentCount: _logs[logIndex].commentCount + 1);
    _logs[logIndex] = updated;
    _syncFeedLog(updated);

    if (_api.enabled) {
      unawaited(
        _api.commentPost(postId: logId, comment: comment.trim()).then((_) {
          _lastSyncError = null;
        }).catchError((error) {
          _lastSyncError = 'Comment sync failed: $error';
          notifyListeners();
        }),
      );
    }

    notifyListeners();
  }

  void acceptFriendRequest(String friendId) {
    _friends = _friends
        .map(
          (friend) => friend.id == friendId
              ? friend.copyWith(status: FriendshipStatus.accepted)
              : friend,
        )
        .toList();

    if (_api.enabled) {
      unawaited(
        _api.acceptFriendRequest(requestId: friendId).then((_) {
          _lastSyncError = null;
        }).catchError((error) {
          _lastSyncError = 'Accept friend request failed: $error';
          notifyListeners();
        }),
      );
    }

    notifyListeners();
  }

  void rejectFriendRequest(String friendId) {
    _friends.removeWhere((friend) => friend.id == friendId);

    if (_api.enabled) {
      unawaited(
        _api.rejectFriendRequest(requestId: friendId).then((_) {
          _lastSyncError = null;
        }).catchError((error) {
          _lastSyncError = 'Reject friend request failed: $error';
          notifyListeners();
        }),
      );
    }

    notifyListeners();
  }

  void removeFriend(String friendId) {
    _friends.removeWhere((friend) => friend.id == friendId);

    if (_api.enabled) {
      unawaited(
        _api.removeFriend(friendId: friendId).then((_) {
          _lastSyncError = null;
        }).catchError((error) {
          _lastSyncError = 'Remove friend failed: $error';
          notifyListeners();
        }),
      );
    }

    notifyListeners();
  }

  void addPersonalDrink(DrinkType drink) {
    _drinkCatalog = [drink, ..._drinkCatalog];
    notifyListeners();
  }

  int totalForDays(int days) {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days - 1));
    return _logs.where((log) {
      if (log.userId != _currentUser.id) {
        return false;
      }
      return !_dateOnly(log.loggedAt).isBefore(_dateOnly(from));
    }).length;
  }

  Map<DrinkCategory, int> categoryCounts() {
    final counts = <DrinkCategory, int>{
      for (final category in DrinkCategory.values) category: 0,
    };

    for (final log in _logs.where((log) => log.userId == _currentUser.id)) {
      counts.update(log.category, (value) => value + 1);
    }
    return counts;
  }

  List<int> last7DaySeries() {
    final now = DateTime.now();
    return List<int>.generate(7, (index) {
      final day = _dateOnly(now.subtract(Duration(days: 6 - index)));
      return _logs.where((log) {
        return log.userId == _currentUser.id && _dateOnly(log.loggedAt) == day;
      }).length;
    });
  }

  StreakMetrics streakMetrics() {
    final days = _logs
        .where((log) => log.userId == _currentUser.id)
        .map((log) => _dateOnly(log.loggedAt))
        .toSet()
        .toList()
      ..sort();

    if (days.isEmpty) {
      return const StreakMetrics(current: 0, best: 0);
    }

    final today = _dateOnly(DateTime.now());
    var current = 0;
    var cursor = today;
    while (days.contains(cursor)) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i += 1) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        run += 1;
      } else {
        run = 1;
      }
      if (run > best) {
        best = run;
      }
    }

    return StreakMetrics(current: current, best: best);
  }

  List<DrinkLog> mapLogs({
    required bool showMine,
    required bool showFriends,
    DrinkCategory? category,
    DateFilter dateFilter = DateFilter.all,
  }) {
    final now = DateTime.now();
    return _logs.where((log) {
      final isMine = log.userId == _currentUser.id;
      final visibleByOwner = (isMine && showMine) || (!isMine && showFriends);
      if (!visibleByOwner) {
        return false;
      }

      if (category != null && log.category != category) {
        return false;
      }

      final date = _dateOnly(log.loggedAt);
      switch (dateFilter) {
        case DateFilter.today:
          return date == _dateOnly(now);
        case DateFilter.sevenDays:
          return !date
              .isBefore(_dateOnly(now.subtract(const Duration(days: 6))));
        case DateFilter.thirtyDays:
          return !date
              .isBefore(_dateOnly(now.subtract(const Duration(days: 29))));
        case DateFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _bootstrapFromApi() async {
    if (!_api.enabled) {
      return;
    }

    _isRemoteSyncing = true;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _api.fetchFeed(),
        _api.fetchFriends(),
      ]);

      final remoteFeed = results[0] as List<FeedItem>;
      final remoteFriends = results[1] as List<Friend>;

      if (remoteFeed.isNotEmpty) {
        _feed = remoteFeed..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _logs = _feed
            .where((item) => item.log != null)
            .map((item) => item.log!)
            .toList()
          ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      }

      if (remoteFriends.isNotEmpty) {
        _friends = remoteFriends;
      }

      _lastSyncError = null;
    } catch (error) {
      _lastSyncError = 'Initial API sync failed: $error';
    } finally {
      _isRemoteSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushNotificationPrefs() async {
    if (!_api.enabled) {
      return;
    }

    try {
      await _api.patchNotificationPreferences(
        friendDrinkNotifications: _friendDrinkNotifications,
        quietHoursStart: _quietHoursStart,
        quietHoursEnd: _quietHoursEnd,
        language: _locale.languageCode,
      );
      _lastSyncError = null;
    } catch (error) {
      _lastSyncError = 'Notification preferences sync failed: $error';
      notifyListeners();
    }
  }

  void _replaceLog({required String tempId, required DrinkLog remoteLog}) {
    final logIndex = _logs.indexWhere((log) => log.id == tempId);
    if (logIndex >= 0) {
      _logs[logIndex] = remoteLog;
    } else {
      _logs.insert(0, remoteLog);
    }

    final feedIndex = _feed.indexWhere(
      (item) =>
          item.type == FeedEventType.drinkLogged && item.log?.id == tempId,
    );

    if (feedIndex >= 0) {
      final existing = _feed[feedIndex];
      _feed[feedIndex] = FeedItem(
        id: existing.id,
        type: existing.type,
        createdAt: existing.createdAt,
        log: remoteLog,
      );
    }
  }

  LegacyImportResult validateLegacyImport(String content) {
    final errors = <String>[];
    final mappingCounter = <String, int>{};
    final pending = <_PendingImportEntry>[];

    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (error) {
      return LegacyImportResult(
        totalEntries: 0,
        validEntries: 0,
        errors: ['Invalid JSON: ${error.message}'],
        rows: const <LegacyImportRow>[],
      );
    }

    final entries = _resolveLegacyEntries(decoded);
    if (entries == null) {
      return const LegacyImportResult(
        totalEntries: 0,
        validEntries: 0,
        errors: <String>[
          'Expected a JSON array or an object containing history/entries/list.',
        ],
        rows: <LegacyImportRow>[],
      );
    }

    var validEntries = 0;
    for (var i = 0; i < entries.length; i += 1) {
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        errors.add('Entry ${i + 1}: not an object.');
        continue;
      }

      final name = _pickString(entry, ['drink', 'name', 'beverage', 'title']);
      final rawDate = _pickString(entry, ['date', 'loggedAt', 'createdAt']);
      final legacyGlass =
          _pickString(entry, ['glassType', 'glass', 'glass_type', 'type']) ??
              'unknown';

      if (name == null || name.isEmpty) {
        errors.add('Entry ${i + 1}: missing drink name.');
        continue;
      }
      if (rawDate == null || rawDate.isEmpty) {
        errors.add('Entry ${i + 1}: missing date field.');
        continue;
      }

      final parsedDate = DateTime.tryParse(rawDate);
      if (parsedDate == null) {
        errors.add('Entry ${i + 1}: invalid date "$rawDate".');
        continue;
      }

      final mappedGlass = _mapLegacyGlassType(legacyGlass);
      mappingCounter.update('$legacyGlass|$mappedGlass', (value) => value + 1,
          ifAbsent: () => 1);

      pending.add(
        _PendingImportEntry(
          name: name,
          date: parsedDate,
          category: _guessCategory(name),
          mappedGlassType: mappedGlass,
        ),
      );
      validEntries += 1;
    }

    final rows = mappingCounter.entries.map((entry) {
      final split = entry.key.split('|');
      return LegacyImportRow(
        legacyType: split[0],
        mappedType: split[1],
        count: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final result = LegacyImportResult(
      totalEntries: entries.length,
      validEntries: validEntries,
      errors: errors,
      rows: rows,
    );

    _lastImportResult = result;
    _pendingImportEntries = pending;
    notifyListeners();
    return result;
  }

  void applyLastImport() {
    if (_lastImportResult == null || _pendingImportEntries.isEmpty) {
      return;
    }

    final importedLogs = _pendingImportEntries
        .take(250)
        .map(
          (entry) => DrinkLog(
            id: 'import_${entry.date.microsecondsSinceEpoch}_${entry.name.hashCode}',
            userId: _currentUser.id,
            userName: _currentUser.displayName,
            userAvatarUrl: _currentUser.avatarUrl,
            drinkName: entry.name,
            category: entry.category,
            loggedAt: entry.date,
            latitude: 52.52,
            longitude: 13.40,
            comment: 'Imported (${entry.mappedGlassType})',
          ),
        )
        .toList();

    _logs.addAll(importedLogs);
    _logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    _feed.insert(
      0,
      FeedItem(
        id: 'feed_import_${DateTime.now().microsecondsSinceEpoch}',
        type: FeedEventType.badgesUnlocked,
        createdAt: DateTime.now(),
        badges: <BadgeAward>[
          BadgeAward(
            id: 'import_complete',
            name: 'Data Restored',
            description: 'Legacy BeeerWithMe history imported',
            unlockedAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );

    _pendingImportEntries = [];
    notifyListeners();
  }

  void _syncFeedLog(DrinkLog updatedLog) {
    _feed = _feed.map((feedItem) {
      if (feedItem.type == FeedEventType.drinkLogged &&
          feedItem.log?.id == updatedLog.id) {
        return FeedItem(
          id: feedItem.id,
          type: feedItem.type,
          createdAt: feedItem.createdAt,
          log: updatedLog,
          badges: feedItem.badges,
        );
      }
      return feedItem;
    }).toList();
  }

  List<BadgeAward> _evaluateBadges() {
    final newBadges = <BadgeAward>[];

    final myDrinkCount =
        _logs.where((log) => log.userId == _currentUser.id).length;
    const drinkMilestones = <int, String>{
      1: 'First Sip',
      10: 'Social Sipper',
      50: 'Steady Tracker',
      100: 'Hydration Hero',
      200: 'Barrel Counter',
      500: 'Legend of the Tap',
      1000: 'Mythic Pour',
    };

    for (final entry in drinkMilestones.entries) {
      final id = 'drink_total_${entry.key}';
      final alreadyUnlocked = _badges.any((badge) => badge.id == id);
      if (!alreadyUnlocked && myDrinkCount >= entry.key) {
        newBadges.add(
          BadgeAward(
            id: id,
            name: entry.value,
            description: 'Logged ${entry.key} drinks',
            unlockedAt: DateTime.now(),
          ),
        );
      }
    }

    final withFriendsCount = _logs
        .where((log) =>
            log.userId == _currentUser.id && log.taggedFriends.isNotEmpty)
        .length;
    const friendMilestones = <int, String>{
      1: 'Cheers Buddy',
      10: 'Table Starter',
      20: 'Crew Classic',
      50: 'Party Anchor',
      100: 'Social Legend',
    };

    for (final entry in friendMilestones.entries) {
      final id = 'drink_with_friends_${entry.key}';
      final alreadyUnlocked = _badges.any((badge) => badge.id == id);
      if (!alreadyUnlocked && withFriendsCount >= entry.key) {
        newBadges.add(
          BadgeAward(
            id: id,
            name: entry.value,
            description: 'Logged ${entry.key} drinks with friends',
            unlockedAt: DateTime.now(),
          ),
        );
      }
    }

    final categoryCounts = this.categoryCounts();
    const masteryNames = <DrinkCategory, String>{
      DrinkCategory.beer: 'Hop Scholar',
      DrinkCategory.wine: 'Cellar Sensei',
      DrinkCategory.spirits: 'Barrel Sage',
      DrinkCategory.cocktails: 'Mixmaster',
      DrinkCategory.nonAlcoholic: 'Clear Mind Captain',
    };

    for (final entry in categoryCounts.entries) {
      final id = 'category_mastery_${entry.key.key}';
      final alreadyUnlocked = _badges.any((badge) => badge.id == id);
      if (!alreadyUnlocked && entry.value >= 10) {
        newBadges.add(
          BadgeAward(
            id: id,
            name: masteryNames[entry.key]!,
            description: 'Logged 10 ${entry.key.defaultLabel} drinks',
            unlockedAt: DateTime.now(),
          ),
        );
      }
    }

    final streak = streakMetrics().current;
    const streakMilestones = <int>[3, 7, 14, 30, 60, 90, 180, 365];
    for (final days in streakMilestones) {
      final id = 'streak_$days';
      final alreadyUnlocked = _badges.any((badge) => badge.id == id);
      if (!alreadyUnlocked && streak >= days) {
        newBadges.add(
          BadgeAward(
            id: id,
            name: '$days-Day Streak',
            description: 'Logged drinks for $days consecutive days',
            unlockedAt: DateTime.now(),
          ),
        );
      }
    }

    return newBadges;
  }

  List<dynamic>? _resolveLegacyEntries(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final candidates = <String>['history', 'entries', 'list', 'drinks'];
      for (final key in candidates) {
        final value = decoded[key];
        if (value is List<dynamic>) {
          return value;
        }
      }
    }
    return null;
  }

  String? _pickString(Map<String, dynamic> entry, List<String> keys) {
    for (final key in keys) {
      final value = entry[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _mapLegacyGlassType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    const map = <String, String>{
      'pint': 'Beer Glass',
      'weizen': 'Weizen Glass',
      'tulip': 'Beer Glass',
      'wine': 'Wine Glass',
      'red wine': 'Wine Glass',
      'white wine': 'Wine Glass',
      'shot': 'Shot Glass',
      'snifter': 'Spirit Glass',
      'can': 'Can',
      'bottle': 'Bottle',
      'mug': 'Beer Mug',
      'cup': 'Cup',
      'glass': 'Standard Glass',
      'unknown': 'Standard Glass',
    };

    for (final entry in map.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Standard Glass';
  }

  DrinkCategory _guessCategory(String drinkName) {
    final normalized = drinkName.toLowerCase();
    if (normalized.contains('beer') ||
        normalized.contains('pils') ||
        normalized.contains('ipa')) {
      return DrinkCategory.beer;
    }
    if (normalized.contains('wine') || normalized.contains('spritz')) {
      return DrinkCategory.wine;
    }
    if (normalized.contains('vodka') ||
        normalized.contains('gin') ||
        normalized.contains('rum') ||
        normalized.contains('whiskey') ||
        normalized.contains('tequila')) {
      return DrinkCategory.spirits;
    }
    if (normalized.contains('mojito') ||
        normalized.contains('martini') ||
        normalized.contains('margarita')) {
      return DrinkCategory.cocktails;
    }
    return DrinkCategory.nonAlcoholic;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _PendingImportEntry {
  const _PendingImportEntry({
    required this.name,
    required this.date,
    required this.category,
    required this.mappedGlassType,
  });

  final String name;
  final DateTime date;
  final DrinkCategory category;
  final String mappedGlassType;
}
