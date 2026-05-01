import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:glasstrail/firebase_options.dart';

import 'app_routes.dart';

class PushDeviceToken {
  const PushDeviceToken({required this.token, required this.platform});

  final String token;
  final String platform;
}

class PushNotificationOpen {
  const PushNotificationOpen({required this.routeName, this.notificationId});

  final String routeName;
  final String? notificationId;
}

abstract class PushNotificationService {
  const PushNotificationService();

  Future<PushDeviceToken?> getDeviceToken();

  Stream<PushDeviceToken> get tokenRefreshes;

  Future<PushNotificationOpen?> consumeInitialOpen();

  Stream<PushNotificationOpen> get openedNotifications;
}

class DisabledPushNotificationService extends PushNotificationService {
  const DisabledPushNotificationService();

  @override
  Future<PushDeviceToken?> getDeviceToken() async => null;

  @override
  Stream<PushDeviceToken> get tokenRefreshes =>
      const Stream<PushDeviceToken>.empty();

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async => null;

  @override
  Stream<PushNotificationOpen> get openedNotifications =>
      const Stream<PushNotificationOpen>.empty();
}

Future<PushNotificationService> createPlatformPushNotificationService() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const DisabledPushNotificationService();
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebasePushNotificationService(FirebaseMessaging.instance);
  } catch (_) {
    return const DisabledPushNotificationService();
  }
}

class FirebasePushNotificationService extends PushNotificationService {
  const FirebasePushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  static const _platform = 'android';

  @override
  Future<PushDeviceToken?> getDeviceToken() async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    final token = await _messaging.getToken();
    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      return null;
    }
    return PushDeviceToken(token: normalizedToken, platform: _platform);
  }

  @override
  Stream<PushDeviceToken> get tokenRefreshes {
    return _messaging.onTokenRefresh
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map((token) => PushDeviceToken(token: token, platform: _platform));
  }

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      return null;
    }
    return _openFromMessage(message);
  }

  @override
  Stream<PushNotificationOpen> get openedNotifications {
    return FirebaseMessaging.onMessageOpenedApp
        .map(_openFromMessage)
        .where((open) => open != null)
        .map((open) => open!);
  }

  PushNotificationOpen? _openFromMessage(RemoteMessage message) {
    final route = _stringData(message, 'route');
    if (route == null) {
      return null;
    }
    final notificationId =
        _stringData(message, 'notification_id') ??
        _stringData(message, 'notificationId');
    return PushNotificationOpen(
      routeName: AppRoutes.normalize(route),
      notificationId: notificationId,
    );
  }

  String? _stringData(RemoteMessage message, String key) {
    final value = message.data[key];
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
