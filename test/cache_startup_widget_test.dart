import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/cache/bootstrap_cache_store.dart';
import 'package:glasstrail/src/cache/media_cache_store.dart';
import 'package:glasstrail/src/models.dart';
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
}
