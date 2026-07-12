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
  // Serializes update() calls: without this, two concurrent read-modify-
  // write cycles (e.g. an entry added while settings are also being saved)
  // could interleave and one write would clobber the other's changes.
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
      // A schema mismatch means the cached snapshot's JSON shape may not
      // match what BootstrapSnapshot.fromJson expects on this app version;
      // wipe rather than attempt a partial/corrupt read.
      if (manifest.schemaVersion != cacheSchemaVersion) {
        await purgeAll();
        return BootstrapCacheState.empty();
      }

      final snapshot = BootstrapSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(snapshotJson) as Map),
      );
      return BootstrapCacheState(snapshot: snapshot, manifest: manifest);
    } catch (_) {
      // Any parse failure (corrupt file, unexpected JSON shape, partial
      // write from a crash mid-flush) is treated as "no cache" rather than
      // propagated — the app can always refill from the network, but a
      // thrown exception here would break bootstrap entirely.
      return BootstrapCacheState.empty();
    }
  }

  // Snapshot is written before the manifest on purpose: each file is
  // written atomically on its own, but the pair isn't transactional, so if
  // the process dies between the two writes we want the manifest (which
  // records "as of when" each domain was cached) to never claim freshness
  // for data that didn't actually make it to disk.
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

  // Chained onto the tail of _writeQueue so this read-modify-write only
  // starts once every prior queued update has finished, and re-reads state
  // fresh (rather than reusing a caller-held copy) so it always transforms
  // the latest persisted state, not one that a concurrent update may have
  // already superseded. catchError keeps the queue alive after a failed
  // update instead of leaving all future updates permanently blocked on a
  // failed future.
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

  // Clears everything tied to a specific account (sign-out/account
  // deletion) but deliberately leaves defaultCatalog cached: the drink
  // catalog isn't user-scoped, changes rarely, and re-fetching it on every
  // sign-out/sign-in would be wasted work.
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
