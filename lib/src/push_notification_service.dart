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

/// Wraps a [PushNotificationService] that is still initializing so callers
/// (and `runApp`) never have to wait for platform setup such as
/// `Firebase.initializeApp`. If initialization fails, behaves like
/// [DisabledPushNotificationService].
class DeferredPushNotificationService extends PushNotificationService {
  DeferredPushNotificationService(Future<PushNotificationService> inner)
    : _inner = inner.catchError(
        (Object _) => const DisabledPushNotificationService(),
      );

  final Future<PushNotificationService> _inner;

  @override
  Future<PushDeviceToken?> getDeviceToken() async {
    final service = await _inner;
    return service.getDeviceToken();
  }

  @override
  Stream<PushDeviceToken> get tokenRefreshes async* {
    final service = await _inner;
    yield* service.tokenRefreshes;
  }

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async {
    final service = await _inner;
    return service.consumeInitialOpen();
  }

  @override
  Stream<PushNotificationOpen> get openedNotifications async* {
    final service = await _inner;
    yield* service.openedNotifications;
  }
}

Future<PushNotificationService> createPlatformPushNotificationService() async {
  // Push notifications are only wired up for Android in this app (no APNs
  // entitlement/web push setup), so other platforms get the no-op service
  // rather than attempting Firebase Messaging calls that would fail there.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const DisabledPushNotificationService();
  }

  try {
    // Guard against double-initialization: Firebase.initializeApp throws
    // if called more than once for the default app, which can happen if
    // another part of app startup already initialized it.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebasePushNotificationService(FirebaseMessaging.instance);
  } catch (_) {
    // Missing/misconfigured google-services.json, no Play Services on the
    // device/emulator, etc. — push notifications are a non-critical
    // enhancement, so failure here shouldn't block app startup.
    return const DisabledPushNotificationService();
  }
}

class FirebasePushNotificationService extends PushNotificationService {
  const FirebasePushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  static const _platform = 'android';

  @override
  Future<PushDeviceToken?> getDeviceToken() async {
    // Android 13+ requires runtime notification permission; requestPermission
    // shows the OS prompt (a no-op if already granted/denied) before a
    // token is fetched, since a token is useless without permission to
    // actually display notifications.
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
    // Data payload keys come from the Supabase edge function that sends
    // notifications (snake_case) — camelCase is also accepted defensively
    // in case a payload is ever sent from elsewhere (e.g. manual testing
    // via the Firebase console).
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
