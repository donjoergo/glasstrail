import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/cache/media_cache_store.dart';

import 'support/cache_test_support.dart';

void main() {
  test('reuses a shared store for the same backend instance', () async {
    final backend = TestCacheStoreBackend();

    final firstStore = await MediaCacheStore.shared(backend: backend);
    final secondStore = await MediaCacheStore.shared(backend: backend);

    expect(identical(firstStore, secondStore), isTrue);
  });

  test('persists canonical storage bytes across store restarts', () async {
    final backend = TestCacheStoreBackend();
    final firstStore = await MediaCacheStore.create(backend: backend);

    await firstStore.write(
      'viewer-1/entries/photo.jpg',
      Uint8List.fromList(<int>[1, 2, 3, 4]),
      scopeUserId: 'viewer-1',
      contentType: 'image/jpeg',
    );

    final restartedStore = await MediaCacheStore.create(backend: backend);
    final bytes = await restartedStore.read('viewer-1/entries/photo.jpg');

    expect(bytes, isNotNull);
    expect(bytes, orderedEquals(<int>[1, 2, 3, 4]));
  });

  test('evicts least recently used items when over the size budget', () async {
    final backend = TestCacheStoreBackend();
    await backend.writeTextAtomically(
      'media/manifest.json',
      '{"schemaVersion":1,"sizeLimitBytes":5,"evictionCount":0,"entries":{}}',
    );
    final store = await MediaCacheStore.create(backend: backend);

    await store.write(
      'viewer-1/entries/old.jpg',
      Uint8List.fromList(<int>[1, 2, 3]),
      scopeUserId: 'viewer-1',
    );
    await store.write(
      'viewer-1/entries/new.jpg',
      Uint8List.fromList(<int>[4, 5, 6]),
      scopeUserId: 'viewer-1',
    );

    expect(await store.read('viewer-1/entries/old.jpg'), isNull);
    expect(await store.read('viewer-1/entries/new.jpg'), isNotNull);
    final debug = await store.loadDebugState();
    expect(debug.evictionCount, 1);
    expect(debug.totalBytes, lessThanOrEqualTo(5));
  });

  test('purges all viewer-scoped media on sign out', () async {
    final backend = TestCacheStoreBackend();
    final store = await MediaCacheStore.create(backend: backend);

    await store.write(
      'friend-1/profiles/avatar.jpg',
      Uint8List.fromList(<int>[1]),
      scopeUserId: 'viewer-1',
    );
    await store.write(
      'viewer-2/profiles/avatar.jpg',
      Uint8List.fromList(<int>[2]),
      scopeUserId: 'viewer-2',
    );

    await store.purgeScope('viewer-1');

    expect(await store.read('friend-1/profiles/avatar.jpg'), isNull);
    expect(await store.read('viewer-2/profiles/avatar.jpg'), isNotNull);
  });

  test('drops incompatible media manifests automatically', () async {
    final backend = TestCacheStoreBackend();
    await backend.writeTextAtomically(
      'media/manifest.json',
      '{"schemaVersion":999,"sizeLimitBytes":10,"evictionCount":0,"entries":{}}',
    );
    final store = await MediaCacheStore.create(backend: backend);

    final debug = await store.loadDebugState();

    expect(debug.itemCount, 0);
    expect(await backend.readText('media/manifest.json'), isNull);
  });
}
