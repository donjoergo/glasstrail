import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/cache/bootstrap_cache_store.dart';
import 'package:glasstrail/src/cache/media_cache_store.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/cached_app_repository.dart';

import 'support/cache_test_support.dart';

void main() {
  test('serves fresh cached startup domains without backend reads', () async {
    final delegate = await buildProbeLocalRepository();
    final user = await delegate.signUp(
      email: 'cache-startup@example.com',
      password: 'password123',
      displayName: 'Cache Startup',
    );
    final defaultCatalog = await delegate.loadDefaultCatalog(
      forceRefresh: true,
    );
    final customDrink = await delegate.saveCustomDrink(
      userId: user.id,
      name: 'Cached Spritz',
      category: DrinkCategory.cocktails,
    );
    final entry = await delegate.addDrinkEntry(
      user: user,
      drink: defaultCatalog.first,
      comment: 'Cached entry',
    );
    final feedPage = await delegate.loadFeedDrinkPosts(
      userId: user.id,
      limit: 20,
      forceRefresh: true,
    );
    final settings = await delegate.saveSettings(
      user.id,
      UserSettings.defaults().copyWith(localeCode: 'de'),
    );

    final cacheBackend = TestCacheStoreBackend();
    final cacheStore = await BootstrapCacheStore.create(backend: cacheBackend);
    await seedBootstrapCache(
      store: cacheStore,
      currentUser: user,
      defaultCatalog: defaultCatalog,
      customDrinks: <DrinkDefinition>[customDrink],
      entries: <DrinkEntry>[entry],
      firstFeedPage: feedPage,
      settings: settings,
    );
    final mediaStore = await MediaCacheStore.create(
      backend: TestCacheStoreBackend(),
    );
    delegate
      ..restoreSessionCalls = 0
      ..loadDefaultCatalogCalls = 0
      ..loadCustomDrinksCalls = 0
      ..loadEntriesCalls = 0
      ..loadFeedDrinkPostsCalls = 0
      ..loadSettingsCalls = 0
      ..loadFriendConnectionsCalls = 0
      ..loadNotificationsCalls = 0;

    final repository = CachedAppRepository(
      delegate: delegate,
      cacheStore: cacheStore,
      mediaCacheStore: mediaStore,
      loadLocalAuthSession: () =>
          LocalAuthSession(id: user.id, email: user.email),
    );

    final restoredUser = await repository.restoreSession();
    final restoredCatalog = await repository.loadDefaultCatalog();
    final restoredCustomDrinks = await repository.loadCustomDrinks(user.id);
    final restoredEntries = await repository.loadEntries(user.id);
    final restoredFeed = await repository.loadFeedDrinkPosts(userId: user.id);
    final restoredSettings = await repository.loadSettings(user.id);
    final restoredConnections = await repository.loadFriendConnections(user.id);
    final restoredNotifications = await repository.loadNotifications(user.id);

    expect(restoredUser?.id, user.id);
    expect(restoredCatalog, isNotEmpty);
    expect(restoredCustomDrinks.single.id, customDrink.id);
    expect(restoredEntries.single.id, entry.id);
    expect(restoredFeed.posts.single.entry.id, entry.id);
    expect(restoredSettings.localeCode, 'de');
    expect(restoredConnections, isEmpty);
    expect(restoredNotifications, isEmpty);
    expect(delegate.restoreSessionCalls, 0);
    expect(delegate.loadDefaultCatalogCalls, 0);
    expect(delegate.loadCustomDrinksCalls, 0);
    expect(delegate.loadEntriesCalls, 0);
    expect(delegate.loadFeedDrinkPostsCalls, 0);
    expect(delegate.loadSettingsCalls, 0);
    expect(delegate.loadFriendConnectionsCalls, 0);
    expect(delegate.loadNotificationsCalls, 0);
  });

  test('force refresh updates stale cached domains from the backend', () async {
    final delegate = await buildProbeLocalRepository();
    final user = await delegate.signUp(
      email: 'cache-refresh@example.com',
      password: 'password123',
      displayName: 'Cache Refresh',
    );
    final defaultCatalog = await delegate.loadDefaultCatalog(
      forceRefresh: true,
    );
    final firstEntry = await delegate.addDrinkEntry(
      user: user,
      drink: defaultCatalog.first,
      comment: 'Older cached entry',
    );

    final cacheStore = await BootstrapCacheStore.create(
      backend: TestCacheStoreBackend(),
    );
    await seedBootstrapCache(
      store: cacheStore,
      currentUser: user,
      defaultCatalog: defaultCatalog,
      entries: <DrinkEntry>[firstEntry],
      updatedAt: DateTime(2025, 1, 1),
    );
    final repository = CachedAppRepository(
      delegate: delegate,
      cacheStore: cacheStore,
      mediaCacheStore: await MediaCacheStore.create(
        backend: TestCacheStoreBackend(),
      ),
      loadLocalAuthSession: () =>
          LocalAuthSession(id: user.id, email: user.email),
    );

    final secondEntry = await delegate.addDrinkEntry(
      user: user,
      drink: defaultCatalog.last,
      comment: 'New remote entry',
    );
    delegate.loadEntriesCalls = 0;

    final refreshedEntries = await repository.loadEntries(
      user.id,
      forceRefresh: true,
    );
    delegate.loadEntriesCalls = 0;
    final cachedEntries = await repository.loadEntries(user.id);

    expect(
      refreshedEntries.map((entry) => entry.id),
      containsAll(<String>[firstEntry.id, secondEntry.id]),
    );
    expect(
      cachedEntries.map((entry) => entry.id),
      containsAll(<String>[firstEntry.id, secondEntry.id]),
    );
    expect(delegate.loadEntriesCalls, 0);
  });

  test(
    'writes through added drink entries into cached entries and feed',
    () async {
      final delegate = await buildProbeLocalRepository();
      final user = await delegate.signUp(
        email: 'cache-write-through@example.com',
        password: 'password123',
        displayName: 'Cache Write Through',
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
      final repository = CachedAppRepository(
        delegate: delegate,
        cacheStore: cacheStore,
        mediaCacheStore: await MediaCacheStore.create(
          backend: TestCacheStoreBackend(),
        ),
        loadLocalAuthSession: () =>
            LocalAuthSession(id: user.id, email: user.email),
      );

      final entry = await repository.addDrinkEntry(
        user: user,
        drink: defaultCatalog.first,
        comment: 'Cached without re-read',
      );
      delegate
        ..loadEntriesCalls = 0
        ..loadFeedDrinkPostsCalls = 0;

      final cachedEntries = await repository.loadEntries(user.id);
      final cachedFeed = await repository.loadFeedDrinkPosts(userId: user.id);

      expect(cachedEntries.first.id, entry.id);
      expect(cachedFeed.posts.first.entry.id, entry.id);
      expect(delegate.loadEntriesCalls, 0);
      expect(delegate.loadFeedDrinkPostsCalls, 0);
    },
  );

  test('sign out purges user-scoped bootstrap and media caches', () async {
    final delegate = await buildProbeLocalRepository();
    final user = await delegate.signUp(
      email: 'cache-sign-out@example.com',
      password: 'password123',
      displayName: 'Cache Sign Out',
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
    );
    final mediaBackend = TestCacheStoreBackend();
    final mediaStore = await MediaCacheStore.create(backend: mediaBackend);
    await mediaStore.write(
      'friend-1/profiles/avatar.jpg',
      Uint8List.fromList(<int>[1, 2, 3]),
      scopeUserId: user.id,
    );
    final repository = CachedAppRepository(
      delegate: delegate,
      cacheStore: cacheStore,
      mediaCacheStore: mediaStore,
      loadLocalAuthSession: () =>
          LocalAuthSession(id: user.id, email: user.email),
    );

    await repository.signOut();

    final clearedState = await cacheStore.readState();
    expect(clearedState.snapshot.currentUser, isNull);
    expect(clearedState.snapshot.defaultCatalog, isNotEmpty);
    expect(clearedState.snapshot.entries, isEmpty);
    expect(await mediaStore.read('friend-1/profiles/avatar.jpg'), isNull);
  });
}
