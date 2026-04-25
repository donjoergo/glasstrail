import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_routes.dart';

class PushDeviceToken {
  const PushDeviceToken({required this.token, required this.platform});

  final String token;
  final String platform;
}

abstract class PushNotificationService {
  const PushNotificationService();

  Future<PushDeviceToken?> getDeviceToken();

  Stream<PushDeviceToken> get tokenRefreshes;

  Future<String?> consumeInitialRoute();

  Stream<String> get openedRoutes;
}

class DisabledPushNotificationService extends PushNotificationService {
  const DisabledPushNotificationService();

  @override
  Future<PushDeviceToken?> getDeviceToken() async => null;

  @override
  Stream<PushDeviceToken> get tokenRefreshes =>
      const Stream<PushDeviceToken>.empty();

  @override
  Future<String?> consumeInitialRoute() async => null;

  @override
  Stream<String> get openedRoutes => const Stream<String>.empty();
}

Future<PushNotificationService> createPlatformPushNotificationService() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const DisabledPushNotificationService();
  }

  final options = _FirebaseAndroidOptions.fromEnvironment();
  if (options == null) {
    return const DisabledPushNotificationService();
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
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
  Future<String?> consumeInitialRoute() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      return null;
    }
    return _routeFromMessage(message);
  }

  @override
  Stream<String> get openedRoutes {
    return FirebaseMessaging.onMessageOpenedApp
        .map(_routeFromMessage)
        .where((route) => route != null)
        .map((route) => route!);
  }

  String? _routeFromMessage(RemoteMessage message) {
    final route = message.data['route']?.trim();
    if (route == null || route.isEmpty) {
      return null;
    }
    return AppRoutes.normalize(route);
  }
}

class _FirebaseAndroidOptions {
  static FirebaseOptions? fromEnvironment() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );
  }
}
