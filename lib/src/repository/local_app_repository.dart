import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import 'app_repository.dart';

class LocalAppRepository implements AppRepository {
  LocalAppRepository(this._preferences, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  static const _usersKey = 'glasstrail.users';
  static const _sessionUserIdKey = 'glasstrail.session_user_id';
  static const _customDrinksKey = 'glasstrail.custom_drinks';
  static const _entriesKey = 'glasstrail.entries';
  static const _settingsKey = 'glasstrail.settings';

  final SharedPreferences _preferences;
  final Uuid _uuid;

  @override
  String get backendLabel => 'Local fallback';

  @override
  bool get usesRemoteBackend => false;

  static Future<LocalAppRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalAppRepository(preferences);
  }

  @override
  Future<AppUser?> restoreSession() async {
    final currentUserId = _preferences.getString(_sessionUserIdKey);
    if (currentUserId == null) {
      return null;
    }
    for (final user in _loadUsers()) {
      if (user.id == currentUserId) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = _loadUsers();
    if (users.any((user) => user.email.toLowerCase() == normalizedEmail)) {
      throw const AppException('An account with that email already exists.');
    }

    final user = AppUser(
      id: _uuid.v4(),
      email: normalizedEmail,
      password: password,
      displayName: displayName.trim(),
      birthday: birthday,
      profileImagePath: profileImagePath,
    );

    users.add(user);
    await _saveUsers(users);
    await _preferences.setString(_sessionUserIdKey, user.id);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    for (final user in _loadUsers()) {
      if (user.email.toLowerCase() == normalizedEmail &&
          user.password == password) {
        await _preferences.setString(_sessionUserIdKey, user.id);
        return user;
      }
    }
    throw const AppException('The email or password is incorrect.');
  }

  @override
  Future<void> signOut() async {
    await _preferences.remove(_sessionUserIdKey);
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final users = _loadUsers();
    final index = users.indexWhere((candidate) => candidate.id == user.id);
    if (index == -1) {
      throw const AppException('The profile could not be updated.');
    }
    users[index] = user;
    await _saveUsers(users);
    return user;
  }

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog() async =>
      buildDefaultDrinkCatalog();

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(String userId) async {
    final map = _readJsonMap(_customDrinksKey);
    final raw = (map[userId] as List?) ?? const <dynamic>[];
    final list = raw
        .map(
          (item) =>
              DrinkDefinition.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    list.sort((left, right) => left.name.compareTo(right.name));
    return list;
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    String? imagePath,
  }) async {
    final map = _readJsonMap(_customDrinksKey);
    final raw = List<dynamic>.from((map[userId] as List?) ?? const <dynamic>[]);
    final normalizedName = name.trim();

    final hasDuplicate = raw.any((item) {
      final candidate = Map<String, dynamic>.from(item as Map);
      return (candidate['name'] as String).toLowerCase() ==
              normalizedName.toLowerCase() &&
          candidate['id'] != drinkId;
    });
    if (hasDuplicate) {
      throw const AppException(
        'You already have a custom drink with that name.',
      );
    }

    final drink = DrinkDefinition(
      id: drinkId ?? _uuid.v4(),
      name: normalizedName,
      category: category,
      volumeMl: volumeMl,
      imagePath: imagePath,
      ownerUserId: userId,
    );

    final index = raw.indexWhere((item) => (item as Map)['id'] == drink.id);
    if (index == -1) {
      raw.add(drink.toJson());
    } else {
      raw[index] = drink.toJson();
    }

    map[userId] = raw;
    await _writeJsonMap(_customDrinksKey, map);
    return drink;
  }

  @override
  Future<List<DrinkEntry>> loadEntries(String userId) async {
    final map = _readJsonMap(_entriesKey);
    final raw = (map[userId] as List?) ?? const <dynamic>[];
    final entries = raw
        .map(
          (item) => DrinkEntry.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    entries.sort((left, right) => right.consumedAt.compareTo(left.consumedAt));
    return entries;
  }

  @override
  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    DateTime? consumedAt,
  }) async {
    final map = _readJsonMap(_entriesKey);
    final raw = List<dynamic>.from(
      (map[user.id] as List?) ?? const <dynamic>[],
    );
    final trimmedComment = comment?.trim();

    final entry = DrinkEntry(
      id: _uuid.v4(),
      userId: user.id,
      drinkId: drink.id,
      drinkName: drink.name,
      category: drink.category,
      consumedAt: consumedAt ?? DateTime.now(),
      volumeMl: volumeMl,
      comment: trimmedComment == null || trimmedComment.isEmpty
          ? null
          : trimmedComment,
      imagePath: imagePath,
    );

    raw.add(entry.toJson());
    map[user.id] = raw;
    await _writeJsonMap(_entriesKey, map);
    return entry;
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  }) async {
    final map = _readJsonMap(_entriesKey);
    final raw = List<dynamic>.from(
      (map[user.id] as List?) ?? const <dynamic>[],
    );
    final index = raw.indexWhere((item) => (item as Map)['id'] == entry.id);
    if (index == -1) {
      throw const AppException('The drink entry could not be updated.');
    }

    final trimmedComment = comment?.trim();
    final trimmedImagePath = imagePath?.trim();
    final updated = entry.copyWith(
      comment: trimmedComment,
      clearComment: trimmedComment == null || trimmedComment.isEmpty,
      imagePath: trimmedImagePath,
      clearImagePath: trimmedImagePath == null || trimmedImagePath.isEmpty,
    );

    raw[index] = updated.toJson();
    map[user.id] = raw;
    await _writeJsonMap(_entriesKey, map);
    return updated;
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) async {
    final map = _readJsonMap(_entriesKey);
    final raw = List<dynamic>.from((map[userId] as List?) ?? const <dynamic>[]);
    final initialLength = raw.length;
    raw.removeWhere((item) => (item as Map)['id'] == entry.id);
    if (raw.length == initialLength) {
      throw const AppException('The drink entry could not be deleted.');
    }
    map[userId] = raw;
    await _writeJsonMap(_entriesKey, map);
  }

  @override
  Future<UserSettings> loadSettings(String userId) async {
    final map = _readJsonMap(_settingsKey);
    final raw = map[userId];
    if (raw == null) {
      return UserSettings.defaults();
    }
    return UserSettings.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<UserSettings> saveSettings(
    String userId,
    UserSettings settings,
  ) async {
    final map = _readJsonMap(_settingsKey);
    map[userId] = settings.toJson();
    await _writeJsonMap(_settingsKey, map);
    return settings;
  }

  List<AppUser> _loadUsers() {
    final raw = _preferences.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return <AppUser>[];
    }
    final decoded = List<dynamic>.from(jsonDecode(raw) as List);
    return decoded
        .map((item) => AppUser.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    await _preferences.setString(
      _usersKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );
  }

  Map<String, dynamic> _readJsonMap(String key) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeJsonMap(String key, Map<String, dynamic> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }
}
