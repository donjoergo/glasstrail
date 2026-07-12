import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/push_notification_service.dart';

class _RecordingPushNotificationService extends PushNotificationService {
  _RecordingPushNotificationService();

  final tokenRefreshController = StreamController<PushDeviceToken>.broadcast();
  int getDeviceTokenCalls = 0;

  @override
  Future<PushDeviceToken?> getDeviceToken() async {
    getDeviceTokenCalls++;
    return const PushDeviceToken(token: 'inner-token', platform: 'android');
  }

  @override
  Stream<PushDeviceToken> get tokenRefreshes => tokenRefreshController.stream;

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async =>
      const PushNotificationOpen(routeName: '/notifications');

  @override
  Stream<PushNotificationOpen> get openedNotifications =>
      const Stream<PushNotificationOpen>.empty();
}

void main() {
  test('deferred service delegates once the inner service resolves', () async {
    final inner = _RecordingPushNotificationService();
    addTearDown(inner.tokenRefreshController.close);
    final completer = Completer<PushNotificationService>();
    final deferred = DeferredPushNotificationService(completer.future);

    final tokenFuture = deferred.getDeviceToken();
    final openFuture = deferred.consumeInitialOpen();
    expect(inner.getDeviceTokenCalls, 0);

    completer.complete(inner);

    expect((await tokenFuture)?.token, 'inner-token');
    expect((await openFuture)?.routeName, '/notifications');
    expect(inner.getDeviceTokenCalls, 1);
  });

  test('deferred service forwards token refreshes from the inner '
      'service', () async {
    final inner = _RecordingPushNotificationService();
    addTearDown(inner.tokenRefreshController.close);
    final completer = Completer<PushNotificationService>();
    final deferred = DeferredPushNotificationService(completer.future);

    final received = <PushDeviceToken>[];
    final subscription = deferred.tokenRefreshes.listen(received.add);
    addTearDown(subscription.cancel);

    completer.complete(inner);
    await Future<void>.delayed(Duration.zero);

    inner.tokenRefreshController.add(
      const PushDeviceToken(token: 'refreshed-token', platform: 'android'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(received.single.token, 'refreshed-token');
  });

  test('deferred service falls back to disabled behavior when the inner '
      'service fails to initialize', () async {
    final deferred = DeferredPushNotificationService(
      Future<PushNotificationService>.error(StateError('init failed')),
    );

    expect(await deferred.getDeviceToken(), isNull);
    expect(await deferred.consumeInitialOpen(), isNull);
    expect(await deferred.tokenRefreshes.isEmpty, isTrue);
    expect(await deferred.openedNotifications.isEmpty, isTrue);
  });
}
