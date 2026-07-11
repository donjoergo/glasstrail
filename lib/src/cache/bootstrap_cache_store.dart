import 'dart:convert';

import '../models.dart';
import 'bootstrap_snapshot.dart';
import 'cache_manifest.dart';
import 'cache_policy.dart';
import 'cache_store_backend.dart';

class BootstrapCacheState {
  const BootstrapCacheState({required this.snapshot, required this.manifest});

  factory BootstrapCacheState.empty() {
    return BootstrapCacheState(
      snapshot: const BootstrapSnapshot(),
      manifest: CacheManifest.empty(),
    );
  }

  final BootstrapSnapshot snapshot;
  final CacheManifest manifest;

  BootstrapCacheState copyWith({
    BootstrapSnapshot? snapshot,
    CacheManifest? manifest,
  }) {
    return BootstrapCacheState(
      snapshot: snapshot ?? this.snapshot,
      manifest: manifest ?? this.manifest,
    );
  }
}

class BootstrapCacheStore {
  BootstrapCacheStore._(this._backend);

  static const _manifestPath = 'bootstrap/manifest.json';
  static const _snapshotPath = 'bootstrap/snapshot.json';

  final CacheStoreBackend _backend;
  Future<void> _writeQueue = Future<void>.value();
  BootstrapCacheState? _memoizedState;

  static Future<BootstrapCacheStore> create({
    CacheStoreBackend? backend,
  }) async {
    return BootstrapCacheStore._(
      backend ?? await createDefaultCacheStoreBackend(namespace: 'glasstrail'),
    );
  }

  Future<BootstrapCacheState> readState() async {
    final memoized = _memoizedState;
    if (memoized != null) {
      return memoized;
    }
    final state = await _readStateFromDisk();
    _memoizedState = state;
    return state;
  }

  Future<BootstrapCacheState> _readStateFromDisk() async {
    try {
      final manifestJson = await _backend.readText(_manifestPath);
      final snapshotJson = await _backend.readText(_snapshotPath);
      if (manifestJson == null || snapshotJson == null) {
        return BootstrapCacheState.empty();
      }

      final manifest = CacheManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(manifestJson) as Map),
      );
      if (manifest.schemaVersion != cacheSchemaVersion) {
        await purgeAll();
        return BootstrapCacheState.empty();
      }

      final snapshot = BootstrapSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(snapshotJson) as Map),
      );
      return BootstrapCacheState(snapshot: snapshot, manifest: manifest);
    } catch (_) {
      return BootstrapCacheState.empty();
    }
  }

  Future<void> writeState(BootstrapCacheState state) async {
    try {
      await _backend.writeTextAtomically(
        _snapshotPath,
        jsonEncode(state.snapshot.toJson()),
      );
      await _backend.writeTextAtomically(
        _manifestPath,
        jsonEncode(state.manifest.toJson()),
      );
      _memoizedState = state;
    } catch (_) {
      // Disk may now disagree with memory; drop the memo so the next read
      // reflects what was actually persisted.
      _memoizedState = null;
      rethrow;
    }
  }

  Future<void> update(
    BootstrapCacheState Function(BootstrapCacheState state) transform,
  ) {
    final nextWrite = _writeQueue.then((_) async {
      final state = await readState();
      await writeState(transform(state));
    });
    _writeQueue = nextWrite.catchError((_) {});
    return nextWrite;
  }

  Future<void> purgeAll() async {
    _memoizedState = null;
    await _backend.deleteDirectory('bootstrap');
  }

  Future<void> purgeUserScope({String? userId}) {
    return update((state) {
      final snapshot = state.snapshot.copyWith(
        clearCurrentUser: true,
        customDrinks: const <DrinkDefinition>[],
        entries: const <DrinkEntry>[],
        clearFirstFeedPage: true,
        clearSettings: true,
        friendConnections: const <FriendConnection>[],
        notifications: const <AppNotification>[],
      );
      final manifest = state.manifest
          .copyWith(clearUserId: true)
          .removeDomains(const <CacheDomain>{
            CacheDomain.currentUser,
            CacheDomain.customDrinks,
            CacheDomain.entries,
            CacheDomain.firstFeedPage,
            CacheDomain.settings,
            CacheDomain.friendConnections,
            CacheDomain.notifications,
          });
      return BootstrapCacheState(snapshot: snapshot, manifest: manifest);
    });
  }
}
