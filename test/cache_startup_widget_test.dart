import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/cache/bootstrap_cache_store.dart';
import 'package:glasstrail/src/cache/media_cache_store.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/push_notification_service.dart';
import 'package:glasstrail/src/repository/cached_app_repository.dart';
import 'package:glasstrail/src/screens/home_shell.dart';

import 'support/cache_test_support.dart';
import 'support/test_harness.dart';

void main() {
  testWidgets(
    'keeps the signed-in shell visible while background reconciliation runs',
    (tester) async {
      final delegate = await buildProbeLocalRepository();
      final user = await delegate.signUp(
        email: 'cached-shell@example.com',
        password: 'password123',
        displayName: 'Cached Shell',
      );
      final defaultCatalog = await delegate.loadDefaultCatalog(
        forceRefresh: true,
      );
      final cacheStore = await BootstrapCacheStore.create(
        backend: TestCacheStoreBackend(),
      );
      await seedBootstrapCache(
        store: cacheStore,
        currentUser: user,
        defaultCatalog: defaultCatalog,
        firstFeedPage: const FeedDrinkPostPage(
          posts: <FeedDrinkPost>[],
          cursor: null,
          hasMore: false,
        ),
      );

      final restoreSessionBlocker = Completer<void>();
      delegate.restoreSessionForceBlocker = restoreSessionBlocker;
      final repository = CachedAppRepository(
        delegate: delegate,
        cacheStore: cacheStore,
        mediaCacheStore: await MediaCacheStore.create(
          backend: TestCacheStoreBackend(),
        ),
        loadLocalAuthSession: () =>
            LocalAuthSession(id: user.id, email: user.email),
      );

      final controller = await AppController.bootstrapWithRepository(
        repository,
      );
      unawaited(controller.startBootstrapReconciliation());

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeShell), findsOneWidget);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isBusy, isFalse);

      restoreSessionBlocker.complete();
      await tester.pumpAndSettle();

      expect(find.byType(HomeShell), findsOneWidget);
    },
  );

  test(
    'drops cached auth state and unregisters listeners when reconciliation loses the session',
    () async {
      final delegate = await _buildReconciliationProbeRepository();
      addTearDown(delegate.dispose);
      final user = await delegate.signUp(
        email: 'cached-expired-session@example.com',
        password: 'password123',
        displayName: 'Cached Expired Session',
      );
      final defaultCatalog = await delegate.loadDefaultCatalog(
        forceRefresh: true,
      );
      final cacheStore = await BootstrapCacheStore.create(
        backend: TestCacheStoreBackend(),
      );
      await seedBootstrapCache(
        store: cacheStore,
        currentUser: user,
        defaultCatalog: defaultCatalog,
        firstFeedPage: const FeedDrinkPostPage(
          posts: <FeedDrinkPost>[],
          cursor: null,
          hasMore: false,
        ),
      );

      LocalAuthSession? activeSession = LocalAuthSession(
        id: user.id,
        email: user.email,
      );
      delegate.useManualNotificationsStream = true;
      final repository = CachedAppRepository(
        delegate: delegate,
        cacheStore: cacheStore,
        mediaCacheStore: await MediaCacheStore.create(
          backend: TestCacheStoreBackend(),
        ),
        loadLocalAuthSession: () => activeSession,
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
        pushNotificationService: const _StaticPushNotificationService(
          PushDeviceToken(token: 'expired-token', platform: 'android'),
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.isAuthenticated, isTrue);
      expect(delegate.notificationListenCount, 1);
      expect(delegate.registeredTokenCalls.single.userId, user.id);

      activeSession = null;
      delegate.forceRestoreSessionResult = null;
      delegate.useForcedRestoreSessionResult = true;

      await controller.startBootstrapReconciliation();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.notifications, isEmpty);
      expect(delegate.notificationCancelCount, 1);
      expect(delegate.unregisteredTokenCalls, hasLength(1));
      expect(delegate.unregisteredTokenCalls.single.userId, user.id);
      expect(delegate.unregisteredTokenCalls.single.token, 'expired-token');

      delegate.emitNotifications(<AppNotification>[
        AppNotification(
          id: 'expired-notification',
          recipientUserId: user.id,
          senderUserId: 'friend-1',
          senderDisplayName: 'Friend One',
          type: AppNotificationTypes.friendRequestSent,
          createdAt: DateTime(2026, 5, 25),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.notifications, isEmpty);
    },
  );

  test(
    'signing out during reconciliation does not restore stale user-scoped state',
    () async {
      final delegate = await _buildReconciliationProbeRepository();
      addTearDown(delegate.dispose);
      final user = await delegate.signUp(
        email: 'cached-race-signout@example.com',
        password: 'password123',
        displayName: 'Cached Race Sign Out',
      );
      final defaultCatalog = await delegate.loadDefaultCatalog(
        forceRefresh: true,
      );
      final cachedEntry = await delegate.addDrinkEntry(
        user: user,
        drink: defaultCatalog.first,
        comment: 'Cached stale entry',
      );
      final cachedFeed = await delegate.loadFeedDrinkPosts(
        userId: user.id,
        limit: 20,
        forceRefresh: true,
      );
      final cacheStore = await BootstrapCacheStore.create(
        backend: TestCacheStoreBackend(),
      );
      await seedBootstrapCache(
        store: cacheStore,
        currentUser: user,
        defaultCatalog: defaultCatalog,
        entries: <DrinkEntry>[cachedEntry],
        firstFeedPage: cachedFeed,
        updatedAt: DateTime(2025, 1, 1),
      );

      LocalAuthSession? activeSession = LocalAuthSession(
        id: user.id,
        email: user.email,
      );
      final repository = CachedAppRepository(
        delegate: delegate,
        cacheStore: cacheStore,
        mediaCacheStore: await MediaCacheStore.create(
          backend: TestCacheStoreBackend(),
        ),
        loadLocalAuthSession: () => activeSession,
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
      );
      addTearDown(controller.dispose);

      expect(controller.isAuthenticated, isTrue);
      expect(controller.entries.single.id, cachedEntry.id);

      delegate.loadEntriesCalls = 0;
      delegate.loadEntriesForceBlocker = Completer<void>();
      final reconciliationFuture = controller.startBootstrapReconciliation();
      for (
        var attempt = 0;
        attempt < 10 && delegate.loadEntriesCalls == 0;
        attempt++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(delegate.loadEntriesCalls, 1);

      activeSession = null;
      expect(await controller.signOut(), isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.entries, isEmpty);

      delegate.loadEntriesForceBlocker!.complete();
      await reconciliationFuture;
      await Future<void>.delayed(Duration.zero);

      final state = await cacheStore.readState();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.entries, isEmpty);
      expect(controller.feedPosts, isEmpty);
      expect(state.manifest.userId, isNull);
      expect(state.snapshot.currentUser, isNull);
      expect(state.snapshot.entries, isEmpty);
      expect(state.snapshot.firstFeedPage, isNull);
    },
  );
}

Future<_ReconciliationProbeLocalRepository>
_buildReconciliationProbeRepository() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  return _ReconciliationProbeLocalRepository(preferences);
}

class _ReconciliationProbeLocalRepository extends ProbeLocalAppRepository {
  _ReconciliationProbeLocalRepository(super.preferences) {
    _notificationsController =
        StreamController<List<AppNotification>>.broadcast(
          onListen: () {
            notificationListenCount++;
          },
          onCancel: () {
            notificationCancelCount++;
          },
        );
  }

  late final StreamController<List<AppNotification>> _notificationsController;
  bool useForcedRestoreSessionResult = false;
  AppUser? forceRestoreSessionResult;
  bool useManualNotificationsStream = false;
  int notificationListenCount = 0;
  int notificationCancelCount = 0;
  final List<_TokenCall> registeredTokenCalls = <_TokenCall>[];
  final List<_TokenCall> unregisteredTokenCalls = <_TokenCall>[];

  Future<void> _awaitIfForced(
    bool forceRefresh,
    Completer<void>? blocker,
  ) async {
    if (forceRefresh && blocker != null) {
      await blocker.future;
    }
  }

  @override
  Future<AppUser?> restoreSession({bool forceRefresh = false}) async {
    await _awaitIfForced(forceRefresh, restoreSessionForceBlocker);
    if (forceRefresh && useForcedRestoreSessionResult) {
      restoreSessionCalls++;
      return forceRestoreSessionResult;
    }
    return super.restoreSession(forceRefresh: forceRefresh);
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    if (!useManualNotificationsStream) {
      return super.watchNotifications(userId);
    }
    return _notificationsController.stream;
  }

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    registeredTokenCalls.add(
      _TokenCall(userId: userId, token: token, platform: platform),
    );
  }

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) async {
    unregisteredTokenCalls.add(_TokenCall(userId: userId, token: token));
  }

  void emitNotifications(List<AppNotification> notifications) {
    _notificationsController.add(notifications);
  }

  void dispose() {
    unawaited(_notificationsController.close());
  }
}

class _TokenCall {
  const _TokenCall({required this.userId, required this.token, this.platform});

  final String userId;
  final String token;
  final String? platform;
}

class _StaticPushNotificationService extends PushNotificationService {
  const _StaticPushNotificationService(this.token);

  final PushDeviceToken token;

  @override
  Future<PushDeviceToken?> getDeviceToken() async => token;

  @override
  Stream<PushDeviceToken> get tokenRefreshes =>
      const Stream<PushDeviceToken>.empty();

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async => null;

  @override
  Stream<PushNotificationOpen> get openedNotifications =>
      const Stream<PushNotificationOpen>.empty();
}
