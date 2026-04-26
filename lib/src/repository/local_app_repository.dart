import 'dart:async';
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
  static const _friendRelationshipsKey = 'glasstrail.friend_relationships';
  static const _notificationsKey = 'glasstrail.notifications';

  final SharedPreferences _preferences;
  final Uuid _uuid;
  final Map<String, StreamController<List<AppNotification>>>
  _notificationControllers =
      <String, StreamController<List<AppNotification>>>{};

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
      profileShareCode: _generateProfileShareCode(users),
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
  Future<List<FriendConnection>> loadFriendConnections(String userId) async {
    return _friendConnectionsForUser(userId);
  }

  @override
  Future<FriendProfile> getOwnFriendProfile(String userId) async {
    final user = await _ensureProfileShareCode(userId);
    return FriendProfile.fromUser(user);
  }

  @override
  Future<PublicFriendProfile> resolvePublicFriendProfileLink(
    String shareCode,
  ) async {
    final normalizedCode = shareCode.trim();
    final user = _loadUsers().where(
      (candidate) => candidate.profileShareCode == normalizedCode,
    );
    if (user.isEmpty) {
      throw const AppException('The profile link is invalid.');
    }
    return PublicFriendProfile.fromUser(user.single);
  }

  @override
  Future<FriendProfile> resolveFriendProfileLink(String shareCode) async {
    final normalizedCode = shareCode.trim();
    final user = _loadUsers().where(
      (candidate) => candidate.profileShareCode == normalizedCode,
    );
    if (user.isEmpty) {
      throw const AppException('The profile link is invalid.');
    }
    return FriendProfile.fromUser(user.single);
  }

  @override
  Future<List<FriendConnection>> sendFriendRequestToProfile({
    required String userId,
    required String shareCode,
  }) async {
    final requester = await _ensureProfileShareCode(userId);
    final target = await resolveFriendProfileLink(shareCode);
    if (target.id == requester.id) {
      throw const AppException('You cannot add yourself as a friend.');
    }

    final relationships = _loadFriendRelationships();
    final existingIndex = relationships.indexWhere(
      (relationship) =>
          _isRelationshipBetween(relationship, requester.id, target.id),
    );

    if (existingIndex == -1) {
      final relationshipId = _uuid.v4();
      relationships.add(<String, dynamic>{
        'id': relationshipId,
        'requesterId': requester.id,
        'addresseeId': target.id,
        'status': FriendRequestStatus.pending.storageValue,
      });
      await _addNotification(
        recipientUserId: target.id,
        sender: requester,
        type: AppNotificationTypes.friendRequestSent,
        metadata: <String, dynamic>{'relationshipId': relationshipId},
      );
    } else {
      final existing = relationships[existingIndex];
      final status = FriendRequestStatusX.fromStorage(
        existing['status'] as String,
      );
      if (status == FriendRequestStatus.rejected) {
        relationships[existingIndex] = <String, dynamic>{
          ...existing,
          'requesterId': requester.id,
          'addresseeId': target.id,
          'status': FriendRequestStatus.pending.storageValue,
        };
        await _addNotification(
          recipientUserId: target.id,
          sender: requester,
          type: AppNotificationTypes.friendRequestSent,
          metadata: <String, dynamic>{
            'relationshipId': existing['id'] as String,
          },
        );
      }
    }

    await _saveFriendRelationships(relationships);
    return _friendConnectionsForUser(userId);
  }

  @override
  Future<List<FriendConnection>> acceptFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    final relationships = _loadFriendRelationships();
    final index = relationships.indexWhere(
      (relationship) =>
          relationship['id'] == relationshipId &&
          relationship['addresseeId'] == userId &&
          relationship['status'] == FriendRequestStatus.pending.storageValue,
    );
    if (index == -1) {
      throw const AppException('The friend request could not be accepted.');
    }

    relationships[index] = <String, dynamic>{
      ...relationships[index],
      'status': FriendRequestStatus.accepted.storageValue,
    };
    final sender = _userById(userId);
    if (sender != null) {
      await _addNotification(
        recipientUserId: relationships[index]['requesterId'] as String,
        sender: sender,
        type: AppNotificationTypes.friendRequestAccepted,
        metadata: <String, dynamic>{'relationshipId': relationshipId},
      );
    }
    await _saveFriendRelationships(relationships);
    return _friendConnectionsForUser(userId);
  }

  @override
  Future<List<FriendConnection>> rejectFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    final relationships = _loadFriendRelationships();
    final index = relationships.indexWhere(
      (relationship) =>
          relationship['id'] == relationshipId &&
          relationship['addresseeId'] == userId &&
          relationship['status'] == FriendRequestStatus.pending.storageValue,
    );
    if (index == -1) {
      throw const AppException('The friend request could not be rejected.');
    }

    relationships[index] = <String, dynamic>{
      ...relationships[index],
      'status': FriendRequestStatus.rejected.storageValue,
    };
    final sender = _userById(userId);
    if (sender != null) {
      await _addNotification(
        recipientUserId: relationships[index]['requesterId'] as String,
        sender: sender,
        type: AppNotificationTypes.friendRequestRejected,
        metadata: <String, dynamic>{'relationshipId': relationshipId},
      );
    }
    await _saveFriendRelationships(relationships);
    return _friendConnectionsForUser(userId);
  }

  @override
  Future<List<FriendConnection>> cancelFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    final relationships = _loadFriendRelationships();
    final initialLength = relationships.length;
    relationships.removeWhere((relationship) {
      return relationship['id'] == relationshipId &&
          relationship['requesterId'] == userId &&
          relationship['status'] == FriendRequestStatus.pending.storageValue;
    });
    if (relationships.length == initialLength) {
      throw const AppException('The friend request could not be withdrawn.');
    }
    await _saveFriendRelationships(relationships);
    return _friendConnectionsForUser(userId);
  }

  @override
  Future<List<FriendConnection>> removeFriend({
    required String userId,
    required String friendUserId,
  }) async {
    final relationships = _loadFriendRelationships();
    final index = relationships.indexWhere((relationship) {
      return relationship['status'] ==
              FriendRequestStatus.accepted.storageValue &&
          _isRelationshipBetween(relationship, userId, friendUserId);
    });
    if (index == -1) {
      throw const AppException('The friend could not be removed.');
    }
    final relationship = relationships.removeAt(index);
    final sender = _userById(userId);
    if (sender != null) {
      await _addNotification(
        recipientUserId: friendUserId,
        sender: sender,
        type: AppNotificationTypes.friendRemoved,
        metadata: <String, dynamic>{
          'relationshipId': relationship['id'] as String,
        },
      );
    }
    await _saveFriendRelationships(relationships);
    return _friendConnectionsForUser(userId);
  }

  @override
  Future<List<AppNotification>> loadNotifications(String userId) async {
    return _notificationsForUser(userId);
  }

  @override
  Future<List<AppNotification>> markNotificationsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    final ids = notificationIds.toSet();
    if (ids.isEmpty) {
      return _notificationsForUser(userId);
    }

    final notifications = _loadNotifications();
    final readAt = DateTime.now();
    var changed = false;
    for (var index = 0; index < notifications.length; index++) {
      final notification = AppNotification.fromJson(notifications[index]);
      if (notification.recipientUserId != userId ||
          !ids.contains(notification.id) ||
          notification.isRead) {
        continue;
      }
      notifications[index] = notification.copyWith(readAt: readAt).toJson();
      changed = true;
    }
    if (changed) {
      await _saveNotifications(notifications);
      _publishNotifications(userId);
    }
    return _notificationsForUser(userId);
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    late final StreamController<List<AppNotification>> controller;
    controller = _notificationControllers.putIfAbsent(
      userId,
      () => StreamController<List<AppNotification>>.broadcast(
        onListen: () {
          controller.add(_notificationsForUser(userId));
        },
      ),
    );
    return controller.stream;
  }

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) async {}

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
  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  }) async {
    final map = _readJsonMap(_customDrinksKey);
    final raw = List<dynamic>.from((map[userId] as List?) ?? const <dynamic>[]);
    final initialLength = raw.length;
    raw.removeWhere((item) => (item as Map)['id'] == drink.id);
    if (raw.length == initialLength) {
      throw const AppException('The custom drink could not be deleted.');
    }
    map[userId] = raw;
    await _writeJsonMap(_customDrinksKey, map);
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
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    DateTime? consumedAt,
    String? importSource,
    String? importSourceId,
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
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      locationAddress: _normalizeLocationAddress(locationAddress),
      importSource: importSource?.trim(),
      importSourceId: importSourceId?.trim(),
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

  AppUser? _userById(String userId) {
    for (final user in _loadUsers()) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  Future<AppUser> _ensureProfileShareCode(String userId) async {
    final users = _loadUsers();
    final index = users.indexWhere((candidate) => candidate.id == userId);
    if (index == -1) {
      throw const AppException('The profile link is invalid.');
    }
    final user = users[index];
    final existingCode = user.profileShareCode?.trim();
    if (existingCode != null && existingCode.isNotEmpty) {
      return user;
    }

    final updated = user.copyWith(
      profileShareCode: _generateProfileShareCode(users),
    );
    users[index] = updated;
    await _saveUsers(users);
    return updated;
  }

  String _generateProfileShareCode(List<AppUser> users) {
    final existingCodes = users
        .map((user) => user.profileShareCode)
        .whereType<String>()
        .toSet();
    while (true) {
      final code = _uuid.v4().replaceAll('-', '');
      if (!existingCodes.contains(code)) {
        return code;
      }
    }
  }

  List<Map<String, dynamic>> _loadFriendRelationships() {
    final raw = _preferences.getString(_friendRelationshipsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    return List<dynamic>.from(
      jsonDecode(raw) as List,
    ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _saveFriendRelationships(
    List<Map<String, dynamic>> relationships,
  ) async {
    await _preferences.setString(
      _friendRelationshipsKey,
      jsonEncode(relationships),
    );
  }

  List<Map<String, dynamic>> _loadNotifications() {
    final raw = _preferences.getString(_notificationsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    return List<dynamic>.from(
      jsonDecode(raw) as List,
    ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _saveNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    await _preferences.setString(_notificationsKey, jsonEncode(notifications));
  }

  Future<void> _addNotification({
    required String recipientUserId,
    required AppUser sender,
    required String type,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final notifications = _loadNotifications();
    notifications.add(
      AppNotification(
        id: _uuid.v4(),
        recipientUserId: recipientUserId,
        senderUserId: sender.id,
        senderDisplayName: sender.displayName,
        imagePath: AppNotificationImageUrls.imagePathForType(
          type: type,
          fallbackImagePath: sender.profileImagePath,
        ),
        type: type,
        templateArgs: <String, dynamic>{
          'senderDisplayName': sender.displayName,
        },
        createdAt: DateTime.now(),
        metadata: metadata,
      ).toJson(),
    );
    await _saveNotifications(notifications);
    _publishNotifications(recipientUserId);
  }

  List<AppNotification> _notificationsForUser(String userId) {
    final notifications = _loadNotifications()
        .map(AppNotification.fromJson)
        .where((notification) => notification.recipientUserId == userId)
        .toList(growable: false);
    return notifications.toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  void _publishNotifications(String userId) {
    final controller = _notificationControllers[userId];
    if (controller == null || controller.isClosed || !controller.hasListener) {
      return;
    }
    controller.add(_notificationsForUser(userId));
  }

  List<FriendConnection> _friendConnectionsForUser(String userId) {
    final usersById = <String, AppUser>{
      for (final user in _loadUsers()) user.id: user,
    };
    final connections = <FriendConnection>[];
    for (final relationship in _loadFriendRelationships()) {
      final requesterId = relationship['requesterId'] as String;
      final addresseeId = relationship['addresseeId'] as String;
      if (requesterId != userId && addresseeId != userId) {
        continue;
      }

      final status = FriendRequestStatusX.fromStorage(
        relationship['status'] as String,
      );
      if (status == FriendRequestStatus.rejected) {
        continue;
      }

      final otherUserId = requesterId == userId ? addresseeId : requesterId;
      final otherUser = usersById[otherUserId];
      if (otherUser == null) {
        continue;
      }

      connections.add(
        FriendConnection(
          id: relationship['id'] as String,
          profile: FriendProfile.fromUser(otherUser),
          status: status,
          direction: status == FriendRequestStatus.accepted
              ? FriendRequestDirection.none
              : addresseeId == userId
              ? FriendRequestDirection.incoming
              : FriendRequestDirection.outgoing,
        ),
      );
    }
    connections.sort(_compareFriendConnections);
    return connections;
  }

  int _compareFriendConnections(FriendConnection left, FriendConnection right) {
    final statusComparison = _friendConnectionSortRank(
      left,
    ).compareTo(_friendConnectionSortRank(right));
    if (statusComparison != 0) {
      return statusComparison;
    }
    return left.profile.displayName.compareTo(right.profile.displayName);
  }

  int _friendConnectionSortRank(FriendConnection connection) {
    if (connection.isAccepted) {
      return 0;
    }
    if (connection.isIncoming) {
      return 1;
    }
    return 2;
  }

  bool _isRelationshipBetween(
    Map<String, dynamic> relationship,
    String leftUserId,
    String rightUserId,
  ) {
    final requesterId = relationship['requesterId'] as String;
    final addresseeId = relationship['addresseeId'] as String;
    return (requesterId == leftUserId && addresseeId == rightUserId) ||
        (requesterId == rightUserId && addresseeId == leftUserId);
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

  String? _normalizeLocationAddress(String? value) {
    return normalizeLocationAddress(value);
  }
}
