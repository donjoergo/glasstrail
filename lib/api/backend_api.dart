import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:glasstrail/models/app_models.dart';

class ApiAuthSession {
  const ApiAuthSession({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final AppUser user;
}

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

class BackendApi {
  BackendApi({
    required this.baseUrl,
    required this.enabled,
    String? inviteToken,
    http.Client? client,
  })  : _inviteToken = inviteToken,
        _client = client ?? http.Client(),
        _baseUri = _normalizeBaseUri(baseUrl);

  factory BackendApi.fromEnvironment({http.Client? client}) {
    const enabledRaw = String.fromEnvironment(
      'USE_REMOTE_API',
      defaultValue: 'false',
    );
    final enabled =
        enabledRaw.toLowerCase() == 'true' || enabledRaw.toLowerCase() == '1';

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );

    const invite = String.fromEnvironment('INVITE_TOKEN', defaultValue: '');

    return BackendApi(
      baseUrl: baseUrl,
      enabled: enabled,
      inviteToken: invite.isEmpty ? null : invite,
      client: client,
    );
  }

  final String baseUrl;
  final bool enabled;
  final http.Client _client;
  final Uri _baseUri;
  String? _authToken;
  final String? _inviteToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<ApiAuthSession?> register({
    required String email,
    required String password,
    required String nickname,
    required String displayName,
  }) async {
    if (!enabled) {
      return null;
    }

    final payload = await _requestJson(
      method: 'POST',
      path: '/v1/auth/register',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'nickname': nickname,
        'displayName': displayName,
        if (_inviteToken != null) 'inviteToken': _inviteToken,
      },
    );

    final token = _readString(payload, const ['accessToken', 'token', 'jwt']) ??
        _readString(
          _asMap(payload['data']),
          const ['accessToken', 'token', 'jwt'],
        );

    final userMap =
        _asMap(payload['user']) ?? _asMap(_asMap(payload['data'])?['user']);
    if (token == null || userMap == null) {
      return null;
    }

    final user = _parseUser(userMap);
    return ApiAuthSession(accessToken: token, user: user);
  }

  Future<ApiAuthSession?> login({
    required String email,
    required String password,
  }) async {
    if (!enabled) {
      return null;
    }

    final payload = await _requestJson(
      method: 'POST',
      path: '/v1/auth/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    final token = _readString(payload, const ['accessToken', 'token', 'jwt']) ??
        _readString(
          _asMap(payload['data']),
          const ['accessToken', 'token', 'jwt'],
        );

    final userMap =
        _asMap(payload['user']) ?? _asMap(_asMap(payload['data'])?['user']);
    if (token == null || userMap == null) {
      return null;
    }

    final user = _parseUser(userMap);
    return ApiAuthSession(accessToken: token, user: user);
  }

  Future<List<FeedItem>> fetchFeed() async {
    if (!enabled) {
      return const <FeedItem>[];
    }

    final payload = await _requestJson(method: 'GET', path: '/v1/feed');
    final items = _readList(payload, const ['items', 'feed', 'data']);

    return items
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(_parseFeedItem)
        .toList();
  }

  Future<DrinkLog?> logDrink({
    required DrinkType drink,
    String? comment,
    String? imagePath,
    required List<String> taggedFriendIds,
  }) async {
    if (!enabled) {
      return null;
    }

    final payload = await _requestJson(
      method: 'POST',
      path: '/v1/drinks/log',
      body: <String, dynamic>{
        'name': drink.name,
        'category': drink.category.key,
        'volumeMl': drink.volumeMl,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
        if (imagePath != null && imagePath.trim().isNotEmpty)
          'image': imagePath,
        if (taggedFriendIds.isNotEmpty) 'taggedFriendIds': taggedFriendIds,
      },
    );

    final logMap = _asMap(payload['log']) ??
        _asMap(payload['post']) ??
        _asMap(_asMap(payload['data'])?['log']) ??
        _asMap(_asMap(payload['data'])?['post']) ??
        _asMap(payload['data']);

    if (logMap == null) {
      return null;
    }

    return _parseDrinkLog(logMap);
  }

  Future<void> cheerPost(
      {required String postId, String source = 'app'}) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'POST',
      path: '/v1/posts/$postId/cheers',
      body: <String, dynamic>{'source': source},
    );
  }

  Future<void> commentPost({
    required String postId,
    required String comment,
  }) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'POST',
      path: '/v1/posts/$postId/comments',
      body: <String, dynamic>{'comment': comment},
    );
  }

  Future<List<Friend>> fetchFriends() async {
    if (!enabled) {
      return const <Friend>[];
    }

    final payload = await _requestJson(method: 'GET', path: '/v1/friends');
    final items = _readList(payload, const ['friends', 'items', 'data']);

    return items
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(_parseFriend)
        .toList();
  }

  Future<void> sendFriendRequest({required String userId}) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'POST',
      path: '/v1/friends/requests',
      body: <String, dynamic>{'userId': userId},
    );
  }

  Future<void> acceptFriendRequest({required String requestId}) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'POST',
      path: '/v1/friends/requests/$requestId/accept',
    );
  }

  Future<void> rejectFriendRequest({required String requestId}) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'POST',
      path: '/v1/friends/requests/$requestId/reject',
    );
  }

  Future<void> removeFriend({required String friendId}) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'DELETE',
      path: '/v1/friends/$friendId',
    );
  }

  Future<void> patchNotificationPreferences({
    required bool friendDrinkNotifications,
    required TimeOfDay quietHoursStart,
    required TimeOfDay quietHoursEnd,
    required String language,
  }) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'PATCH',
      path: '/v1/notifications/preferences',
      body: <String, dynamic>{
        'friendDrinkNotifications': friendDrinkNotifications,
        'quietHours': <String, String>{
          'start': _formatTime(quietHoursStart),
          'end': _formatTime(quietHoursEnd),
        },
        'language': language,
      },
    );
  }

  Future<void> registerDeviceToken({
    required String platform,
    required String token,
  }) async {
    if (!enabled) {
      return;
    }

    await _requestJson(
      method: 'POST',
      path: '/v1/devices/register',
      body: <String, String>{
        'platform': platform,
        'token': token,
      },
    );
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };

    http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'PATCH':
        response = await _client.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      default:
        throw BackendApiException('Unsupported HTTP method: $method');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        'Request failed: $method $path',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is List<dynamic>) {
      return <String, dynamic>{'data': decoded};
    }
    return <String, dynamic>{'data': decoded};
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final fullPath = '${basePath.isEmpty ? '' : basePath}/$normalizedPath';
    return _baseUri.replace(path: fullPath);
  }

  static Uri _normalizeBaseUri(String raw) {
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final parsed = Uri.parse(withScheme);
    return parsed.path.isEmpty ? parsed.replace(path: '') : parsed;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<dynamic> _readList(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final raw = payload[key];
      if (raw is List<dynamic>) {
        return raw;
      }
      final map = _asMap(raw);
      if (map != null) {
        final nested = _readList(map, const ['items', 'results', 'data']);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return const <dynamic>[];
  }

  String? _readString(Map<String, dynamic>? payload, List<String> keys) {
    if (payload == null) {
      return null;
    }

    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      final mapped = <String, dynamic>{};
      for (final entry in raw.entries) {
        mapped['${entry.key}'] = entry.value;
      }
      return mapped;
    }
    return null;
  }

  FeedItem _parseFeedItem(Map<String, dynamic> json) {
    final createdAt = _parseDate(
          json['createdAt'] ?? json['timestamp'] ?? json['date'],
        ) ??
        DateTime.now();

    final typeRaw =
        _readString(json, const ['type', 'eventType', 'kind'])?.toLowerCase() ??
            'drink_logged';

    if (typeRaw.contains('badge')) {
      final badgesRaw = _readList(json, const ['badges', 'items', 'data']);
      final badges = badgesRaw
          .map(_asMap)
          .whereType<Map<String, dynamic>>()
          .map(_parseBadge)
          .toList();

      return FeedItem(
        id: _readString(json, const ['id', 'eventId']) ??
            'feed_badge_${createdAt.microsecondsSinceEpoch}',
        type: FeedEventType.badgesUnlocked,
        createdAt: createdAt,
        badges: badges,
      );
    }

    final logMap = _asMap(json['log']) ??
        _asMap(json['post']) ??
        _asMap(json['drink']) ??
        _asMap(json['data']) ??
        json;

    final log = _parseDrinkLog(logMap);

    return FeedItem(
      id: _readString(json, const ['id', 'eventId']) ?? 'feed_${log.id}',
      type: FeedEventType.drinkLogged,
      createdAt: createdAt,
      log: log,
    );
  }

  DrinkLog _parseDrinkLog(Map<String, dynamic> json) {
    final userMap = _asMap(json['user']) ??
        _asMap(json['actor']) ??
        _asMap(json['owner']) ??
        const <String, dynamic>{};
    final drinkMap = _asMap(json['drink']) ?? const <String, dynamic>{};
    final location = _asMap(json['location']) ??
        _asMap(json['geo']) ??
        const <String, dynamic>{};

    final id = _readString(json, const ['id', 'postId', 'logId']) ??
        'log_${DateTime.now().microsecondsSinceEpoch}';

    final userId = _readString(userMap, const ['id', 'userId']) ??
        _readString(json, const ['userId', 'actorUserId']) ??
        'unknown_user';

    final userName =
        _readString(userMap, const ['displayName', 'name', 'nickname']) ??
            _readString(json, const ['userName', 'actorName']) ??
            'Unknown';

    final avatarUrl =
        _readString(userMap, const ['avatarUrl', 'avatar', 'image']) ??
            _readString(json, const ['userAvatarUrl']) ??
            'https://i.pravatar.cc/150';

    final drinkName = _readString(drinkMap, const ['name', 'title']) ??
        _readString(json, const ['drinkName', 'name']) ??
        'Drink';

    final category = _parseCategory(
      _readString(drinkMap, const ['category', 'type']) ??
          _readString(json, const ['category', 'drinkCategory']),
    );

    final createdAt = _parseDate(
          json['loggedAt'] ??
              json['createdAt'] ??
              json['timestamp'] ??
              json['date'],
        ) ??
        DateTime.now();

    final latitude = _readDouble(location['lat']) ??
        _readDouble(location['latitude']) ??
        _readDouble(json['lat']) ??
        _readDouble(json['latitude']) ??
        52.52;

    final longitude = _readDouble(location['lng']) ??
        _readDouble(location['lon']) ??
        _readDouble(location['longitude']) ??
        _readDouble(json['lng']) ??
        _readDouble(json['lon']) ??
        _readDouble(json['longitude']) ??
        13.40;

    final taggedRaw =
        json['taggedFriendIds'] ?? json['friends'] ?? const <dynamic>[];
    final taggedFriends = taggedRaw is List
        ? taggedRaw
            .map((entry) => '$entry')
            .where((entry) => entry.isNotEmpty)
            .toList()
        : const <String>[];

    return DrinkLog(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: avatarUrl,
      drinkName: drinkName,
      category: category,
      loggedAt: createdAt,
      latitude: latitude,
      longitude: longitude,
      comment: _readString(json, const ['comment', 'body', 'text']),
      imageUrl: _readString(json, const ['imageUrl', 'image', 'photoUrl']),
      taggedFriends: taggedFriends,
      cheersCount: _readInt(json['cheersCount']) ??
          _readInt(json['likesCount']) ??
          _readInt(json['cheerCount']) ??
          0,
      commentCount: _readInt(json['commentCount']) ??
          _readInt(json['commentsCount']) ??
          0,
    );
  }

  BadgeAward _parseBadge(Map<String, dynamic> json) {
    final unlockedAt =
        _parseDate(json['unlockedAt'] ?? json['createdAt']) ?? DateTime.now();
    return BadgeAward(
      id: _readString(json, const ['id', 'badgeId']) ??
          'badge_${unlockedAt.microsecondsSinceEpoch}',
      name: _readString(json, const ['name', 'title']) ?? 'Badge',
      description: _readString(json, const ['description', 'subtitle']) ?? '',
      unlockedAt: unlockedAt,
    );
  }

  Friend _parseFriend(Map<String, dynamic> json) {
    final statusRaw =
        _readString(json, const ['status', 'friendshipStatus'])?.toLowerCase();

    final status = switch (statusRaw) {
      'incoming' ||
      'incoming_request' ||
      'pending_incoming' =>
        FriendshipStatus.incomingRequest,
      'outgoing' ||
      'outgoing_request' ||
      'pending_outgoing' =>
        FriendshipStatus.outgoingRequest,
      _ => FriendshipStatus.accepted,
    };

    return Friend(
      id: _readString(json, const ['id', 'userId', 'friendId']) ??
          'friend_${DateTime.now().microsecondsSinceEpoch}',
      name: _readString(json, const ['name', 'displayName', 'nickname']) ??
          'Friend',
      avatarUrl: _readString(json, const ['avatarUrl', 'avatar', 'image']) ??
          'https://i.pravatar.cc/150',
      status: status,
    );
  }

  AppUser _parseUser(Map<String, dynamic> json) {
    return AppUser(
      id: _readString(json, const ['id', 'userId']) ?? 'user_me',
      nickname: _readString(json, const ['nickname', 'name']) ?? 'user',
      displayName:
          _readString(json, const ['displayName', 'name', 'nickname']) ??
              'User',
      avatarUrl: _readString(json, const ['avatarUrl', 'avatar', 'image']) ??
          'https://i.pravatar.cc/150',
    );
  }

  DrinkCategory _parseCategory(String? raw) {
    final value = raw?.toLowerCase() ?? '';
    if (value.contains('beer') ||
        value.contains('pils') ||
        value.contains('ipa')) {
      return DrinkCategory.beer;
    }
    if (value.contains('wine') || value.contains('spritz')) {
      return DrinkCategory.wine;
    }
    if (value.contains('spirit') ||
        value.contains('vodka') ||
        value.contains('gin') ||
        value.contains('rum') ||
        value.contains('whiskey') ||
        value.contains('tequila')) {
      return DrinkCategory.spirits;
    }
    if (value.contains('cocktail') ||
        value.contains('mojito') ||
        value.contains('martini') ||
        value.contains('margarita')) {
      return DrinkCategory.cocktails;
    }
    return DrinkCategory.nonAlcoholic;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    if (raw is int) {
      final asSeconds = raw > 1000000000000 ? raw ~/ 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(asSeconds * 1000);
    }
    return null;
  }

  int? _readInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  double? _readDouble(dynamic raw) {
    if (raw is double) {
      return raw;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
    }
    return null;
  }
}
