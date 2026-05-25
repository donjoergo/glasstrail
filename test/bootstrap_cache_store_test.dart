import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/cache/bootstrap_cache_store.dart';
import 'package:glasstrail/src/cache/bootstrap_snapshot.dart';
import 'package:glasstrail/src/cache/cache_manifest.dart';
import 'package:glasstrail/src/cache/cache_policy.dart';
import 'package:glasstrail/src/models.dart';

import 'support/cache_test_support.dart';

void main() {
  test('reads and writes bootstrap snapshot state', () async {
    final backend = TestCacheStoreBackend();
    final store = await BootstrapCacheStore.create(backend: backend);
    final now = DateTime(2026, 5, 12, 12);
    final state = BootstrapCacheState(
      snapshot: BootstrapSnapshot(
        currentUser: const AppUser(
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'User Example',
        ),
        defaultCatalog: const <DrinkDefinition>[
          DrinkDefinition(
            id: 'beer',
            name: 'Beer',
            category: DrinkCategory.beer,
          ),
        ],
      ),
      manifest: CacheManifest(
        schemaVersion: cacheSchemaVersion,
        userId: 'user-1',
        domains: <CacheDomain, CacheManifestEntry>{
          CacheDomain.currentUser: CacheManifestEntry(
            updatedAt: now,
            itemCount: 1,
          ),
          CacheDomain.defaultCatalog: CacheManifestEntry(
            updatedAt: now,
            itemCount: 1,
          ),
        },
      ),
    );

    await store.writeState(state);
    final restored = await store.readState();

    expect(restored.snapshot.currentUser?.id, 'user-1');
    expect(restored.snapshot.defaultCatalog.single.name, 'Beer');
    expect(restored.manifest.userId, 'user-1');
    expect(
      restored.manifest.entryFor(CacheDomain.defaultCatalog)?.itemCount,
      1,
    );
  });

  test('drops corrupt cache payloads safely', () async {
    final backend = TestCacheStoreBackend();
    await backend.writeTextAtomically('bootstrap/manifest.json', '{not-json');
    await backend.writeTextAtomically('bootstrap/snapshot.json', '{not-json');
    final store = await BootstrapCacheStore.create(backend: backend);

    final restored = await store.readState();

    expect(restored.snapshot.currentUser, isNull);
    expect(restored.snapshot.defaultCatalog, isEmpty);
    expect(restored.manifest.domains, isEmpty);
  });

  test('drops incompatible schema versions automatically', () async {
    final backend = TestCacheStoreBackend();
    await backend.writeTextAtomically(
      'bootstrap/manifest.json',
      '{"schemaVersion":999,"userId":"user-1","domains":{}}',
    );
    await backend.writeTextAtomically(
      'bootstrap/snapshot.json',
      '{"currentUser":{"id":"user-1","email":"u@example.com","displayName":"User"}}',
    );
    final store = await BootstrapCacheStore.create(backend: backend);

    final restored = await store.readState();

    expect(restored.manifest.domains, isEmpty);
    expect(await backend.readText('bootstrap/manifest.json'), isNull);
    expect(await backend.readText('bootstrap/snapshot.json'), isNull);
  });

  test('keeps the previous snapshot when an atomic write fails', () async {
    final backend = TestCacheStoreBackend();
    final store = await BootstrapCacheStore.create(backend: backend);
    final baselineState = BootstrapCacheState(
      snapshot: const BootstrapSnapshot(
        currentUser: AppUser(
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'Baseline User',
        ),
      ),
      manifest: CacheManifest(
        schemaVersion: cacheSchemaVersion,
        userId: 'user-1',
        domains: <CacheDomain, CacheManifestEntry>{
          CacheDomain.currentUser: CacheManifestEntry(
            updatedAt: DateTime(2026, 5, 12),
            itemCount: 1,
          ),
        },
      ),
    );
    await store.writeState(baselineState);

    backend.failWritePath = 'bootstrap/snapshot.json';

    await expectLater(
      () => store.writeState(
        BootstrapCacheState(
          snapshot: const BootstrapSnapshot(
            currentUser: AppUser(
              id: 'user-2',
              email: 'changed@example.com',
              displayName: 'Changed User',
            ),
          ),
          manifest: CacheManifest(
            schemaVersion: cacheSchemaVersion,
            userId: 'user-2',
            domains: <CacheDomain, CacheManifestEntry>{
              CacheDomain.currentUser: CacheManifestEntry(
                updatedAt: DateTime(2026, 5, 13),
                itemCount: 1,
              ),
            },
          ),
        ),
      ),
      throwsException,
    );

    final restored = await store.readState();
    expect(restored.snapshot.currentUser?.id, 'user-1');
    expect(restored.manifest.userId, 'user-1');
  });
}
