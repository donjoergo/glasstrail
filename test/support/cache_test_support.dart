import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/cache/bootstrap_cache_store.dart';
import 'package:glasstrail/src/cache/bootstrap_snapshot.dart';
import 'package:glasstrail/src/cache/cache_manifest.dart';
import 'package:glasstrail/src/cache/cache_policy.dart';
import 'package:glasstrail/src/cache/cache_store_backend.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

class TestCacheStoreBackend implements CacheStoreBackend {
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  final List<String> deletedPaths = <String>[];
  String? failWritePath;
  int readCalls = 0;

  @override
  Future<void> deleteDirectory(String relativeDirectory) async {
    _files.removeWhere((key, _) => key.startsWith(relativeDirectory));
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    deletedPaths.add(relativePath);
    _files.remove(relativePath);
  }

  @override
  Future<int?> fileLength(String relativePath) async {
    return _files[relativePath]?.length;
  }

  @override
  Future<Uint8List?> readBytes(String relativePath) async {
    readCalls++;
    final bytes = _files[relativePath];
    if (bytes == null) {
      return null;
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<String?> readText(String relativePath) async {
    final bytes = await readBytes(relativePath);
    if (bytes == null) {
      return null;
    }
    return utf8.decode(bytes);
  }

  @override
  Future<void> writeBytesAtomically(
    String relativePath,
    Uint8List contents,
  ) async {
    if (relativePath == failWritePath) {
      throw Exception('Simulated write failure for $relativePath');
    }
    _files[relativePath] = Uint8List.fromList(contents);
  }

  @override
  Future<void> writeTextAtomically(String relativePath, String contents) {
    return writeBytesAtomically(
      relativePath,
      Uint8List.fromList(utf8.encode(contents)),
    );
  }

  @override
  String absolutePathFor(String relativePath) => relativePath;
}

Future<ProbeLocalAppRepository> buildProbeLocalRepository({
  Map<String, Object> initialValues = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final preferences = await SharedPreferences.getInstance();
  return ProbeLocalAppRepository(preferences);
}

class ProbeLocalAppRepository extends LocalAppRepository {
  ProbeLocalAppRepository(super.preferences);

  @override
  String get backendLabel => 'Probe Remote';

  @override
  bool get usesRemoteBackend => true;

  int restoreSessionCalls = 0;
  int loadDefaultCatalogCalls = 0;
  int loadCustomDrinksCalls = 0;
  int loadEntriesCalls = 0;
  int loadFeedDrinkPostsCalls = 0;
  int loadSettingsCalls = 0;
  int loadFriendConnectionsCalls = 0;
  int loadNotificationsCalls = 0;

  Completer<void>? restoreSessionForceBlocker;
  Completer<void>? loadDefaultCatalogForceBlocker;
  Completer<void>? loadCustomDrinksForceBlocker;
  Completer<void>? loadEntriesForceBlocker;
  Completer<void>? loadFeedPostsForceBlocker;
  Completer<void>? loadSettingsForceBlocker;
  Completer<void>? loadFriendConnectionsForceBlocker;
  Completer<void>? loadNotificationsForceBlocker;

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
    restoreSessionCalls++;
    await _awaitIfForced(forceRefresh, restoreSessionForceBlocker);
    return super.restoreSession(forceRefresh: forceRefresh);
  }

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog({
    bool forceRefresh = false,
  }) async {
    loadDefaultCatalogCalls++;
    await _awaitIfForced(forceRefresh, loadDefaultCatalogForceBlocker);
    return super.loadDefaultCatalog(forceRefresh: forceRefresh);
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(
    String userId, {
    bool forceRefresh = false,
  }) async {
    loadCustomDrinksCalls++;
    await _awaitIfForced(forceRefresh, loadCustomDrinksForceBlocker);
    return super.loadCustomDrinks(userId, forceRefresh: forceRefresh);
  }

  @override
  Future<List<DrinkEntry>> loadEntries(
    String userId, {
    bool forceRefresh = false,
  }) async {
    loadEntriesCalls++;
    await _awaitIfForced(forceRefresh, loadEntriesForceBlocker);
    return super.loadEntries(userId, forceRefresh: forceRefresh);
  }

  @override
  Future<FeedDrinkPostPage> loadFeedDrinkPosts({
    required String userId,
    FeedDrinkPostCursor? cursor,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    loadFeedDrinkPostsCalls++;
    await _awaitIfForced(forceRefresh, loadFeedPostsForceBlocker);
    return super.loadFeedDrinkPosts(
      userId: userId,
      cursor: cursor,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<UserSettings> loadSettings(
    String userId, {
    bool forceRefresh = false,
  }) async {
    loadSettingsCalls++;
    await _awaitIfForced(forceRefresh, loadSettingsForceBlocker);
    return super.loadSettings(userId, forceRefresh: forceRefresh);
  }

  @override
  Future<List<FriendConnection>> loadFriendConnections(
    String userId, {
    bool forceRefresh = false,
  }) async {
    loadFriendConnectionsCalls++;
    await _awaitIfForced(forceRefresh, loadFriendConnectionsForceBlocker);
    return super.loadFriendConnections(userId, forceRefresh: forceRefresh);
  }

  @override
  Future<List<AppNotification>> loadNotifications(
    String userId, {
    bool forceRefresh = false,
  }) async {
    loadNotificationsCalls++;
    await _awaitIfForced(forceRefresh, loadNotificationsForceBlocker);
    return super.loadNotifications(userId, forceRefresh: forceRefresh);
  }
}

Future<void> seedBootstrapCache({
  required BootstrapCacheStore store,
  required AppUser currentUser,
  List<DrinkDefinition> defaultCatalog = const <DrinkDefinition>[],
  List<DrinkDefinition> customDrinks = const <DrinkDefinition>[],
  List<DrinkEntry> entries = const <DrinkEntry>[],
  FeedDrinkPostPage? firstFeedPage,
  UserSettings? settings,
  List<FriendConnection> friendConnections = const <FriendConnection>[],
  List<AppNotification> notifications = const <AppNotification>[],
  DateTime? updatedAt,
}) async {
  final at = updatedAt ?? DateTime.now();
  final manifest = CacheManifest(
    schemaVersion: cacheSchemaVersion,
    userId: currentUser.id,
    domains: <CacheDomain, CacheManifestEntry>{
      CacheDomain.currentUser: CacheManifestEntry(updatedAt: at, itemCount: 1),
      CacheDomain.defaultCatalog: CacheManifestEntry(
        updatedAt: at,
        itemCount: defaultCatalog.length,
      ),
      CacheDomain.customDrinks: CacheManifestEntry(
        updatedAt: at,
        itemCount: customDrinks.length,
      ),
      CacheDomain.entries: CacheManifestEntry(
        updatedAt: at,
        itemCount: entries.length,
      ),
      CacheDomain.firstFeedPage: CacheManifestEntry(
        updatedAt: at,
        itemCount: firstFeedPage?.posts.length ?? 0,
      ),
      CacheDomain.settings: CacheManifestEntry(updatedAt: at, itemCount: 1),
      CacheDomain.friendConnections: CacheManifestEntry(
        updatedAt: at,
        itemCount: friendConnections.length,
      ),
      CacheDomain.notifications: CacheManifestEntry(
        updatedAt: at,
        itemCount: notifications.length,
      ),
    },
  );
  final snapshot = BootstrapSnapshot(
    currentUser: currentUser,
    defaultCatalog: defaultCatalog,
    customDrinks: customDrinks,
    entries: entries,
    firstFeedPage: firstFeedPage,
    settings: settings ?? UserSettings.defaults(),
    friendConnections: friendConnections,
    notifications: notifications,
  );
  await store.writeState(
    BootstrapCacheState(snapshot: snapshot, manifest: manifest),
  );
}
