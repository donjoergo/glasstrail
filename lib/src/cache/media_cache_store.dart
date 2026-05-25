import 'dart:convert';
import 'dart:typed_data';

import 'cache_debug_report.dart';
import 'cache_store_backend.dart';
import 'media_cache_entry.dart';
import 'media_cache_manifest.dart';

class MediaCacheStore {
  MediaCacheStore._(this._backend);

  static const _manifestPath = 'media/manifest.json';
  static final Object _defaultSharedStoreKey = Object();
  static final Map<Object, Future<MediaCacheStore>> _sharedStoreFutures =
      <Object, Future<MediaCacheStore>>{};

  final CacheStoreBackend _backend;
  Future<void> _writeQueue = Future<void>.value();

  static Future<MediaCacheStore> create({CacheStoreBackend? backend}) async {
    return MediaCacheStore._(
      backend ?? await createDefaultCacheStoreBackend(namespace: 'glasstrail'),
    );
  }

  static Future<MediaCacheStore> shared({CacheStoreBackend? backend}) {
    final key = backend ?? _defaultSharedStoreKey;
    return _sharedStoreFutures.putIfAbsent(key, () async {
      return MediaCacheStore._(
        backend ??
            await createDefaultCacheStoreBackend(namespace: 'glasstrail'),
      );
    });
  }

  Future<MediaCacheManifest> _readManifest() async {
    try {
      final manifestJson = await _backend.readText(_manifestPath);
      if (manifestJson == null) {
        return MediaCacheManifest.empty();
      }
      final manifest = MediaCacheManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(manifestJson) as Map),
      );
      if (manifest.schemaVersion != mediaCacheSchemaVersion) {
        await purgeAll();
        return MediaCacheManifest.empty(
          sizeLimitBytes: manifest.sizeLimitBytes,
        );
      }
      return manifest;
    } catch (_) {
      return MediaCacheManifest.empty();
    }
  }

  Future<void> _writeManifest(MediaCacheManifest manifest) {
    return _backend.writeTextAtomically(
      _manifestPath,
      jsonEncode(manifest.toJson()),
    );
  }

  Future<void> _updateManifest(
    Future<MediaCacheManifest> Function(MediaCacheManifest manifest) transform,
  ) {
    final nextWrite = _writeQueue.then((_) async {
      final manifest = await _readManifest();
      final nextManifest = await transform(manifest);
      await _writeManifest(nextManifest);
    });
    _writeQueue = nextWrite.catchError((_) {});
    return nextWrite;
  }

  Future<Uint8List?> read(String cacheKey) async {
    final manifest = await _readManifest();
    final entry = manifest.entries[cacheKey];
    if (entry == null) {
      return null;
    }
    final bytes = await _backend.readBytes(entry.relativePath);
    if (bytes == null) {
      await _updateManifest((current) async {
        final nextEntries = Map<String, MediaCacheEntry>.from(current.entries);
        nextEntries.remove(cacheKey);
        return current.copyWith(entries: nextEntries);
      });
      return null;
    }
    await _updateManifest((current) async {
      final nextEntries = Map<String, MediaCacheEntry>.from(current.entries);
      final currentEntry = nextEntries[cacheKey];
      if (currentEntry != null) {
        nextEntries[cacheKey] = currentEntry.copyWith(
          lastAccessedAt: DateTime.now(),
        );
      }
      return current.copyWith(entries: nextEntries);
    });
    return bytes;
  }

  Future<void> write(
    String cacheKey,
    Uint8List bytes, {
    String? scopeUserId,
    String? contentType,
  }) async {
    await _updateManifest((manifest) async {
      final now = DateTime.now();
      final fileName = _fileNameFor(cacheKey, contentType: contentType);
      final relativePath = 'media/files/$fileName';
      await _backend.writeBytesAtomically(relativePath, bytes);

      final nextEntries = Map<String, MediaCacheEntry>.from(manifest.entries);
      final previousEntry = nextEntries[cacheKey];
      if (previousEntry != null && previousEntry.relativePath != relativePath) {
        await _backend.deleteFile(previousEntry.relativePath);
      }
      nextEntries[cacheKey] = MediaCacheEntry(
        cacheKey: cacheKey,
        relativePath: relativePath,
        byteCount: bytes.length,
        cachedAt: now,
        lastAccessedAt: now,
        scopeUserId: scopeUserId,
      );
      var nextManifest = manifest.copyWith(entries: nextEntries);
      nextManifest = await _evictIfNeeded(nextManifest);
      return nextManifest;
    });
  }

  Future<void> purgeScope(String userId) {
    return _updateManifest((manifest) async {
      final nextEntries = <String, MediaCacheEntry>{};
      for (final entry in manifest.entries.entries) {
        if (entry.value.scopeUserId == userId) {
          await _backend.deleteFile(entry.value.relativePath);
          continue;
        }
        nextEntries[entry.key] = entry.value;
      }
      return manifest.copyWith(entries: nextEntries);
    });
  }

  Future<void> purgeAll() async {
    await _backend.deleteDirectory('media');
  }

  Future<MediaCacheDebugState> loadDebugState() async {
    final manifest = await _readManifest();
    return MediaCacheDebugState(
      totalBytes: manifest.totalBytes,
      itemCount: manifest.entries.length,
      evictionCount: manifest.evictionCount,
      sizeLimitBytes: manifest.sizeLimitBytes,
    );
  }

  Future<MediaCacheManifest> _evictIfNeeded(MediaCacheManifest manifest) async {
    var nextManifest = manifest;
    while (nextManifest.totalBytes > nextManifest.sizeLimitBytes &&
        nextManifest.entries.isNotEmpty) {
      final oldest = nextManifest.entries.values.reduce((left, right) {
        return left.lastAccessedAt.isBefore(right.lastAccessedAt)
            ? left
            : right;
      });
      await _backend.deleteFile(oldest.relativePath);
      final nextEntries = Map<String, MediaCacheEntry>.from(
        nextManifest.entries,
      );
      nextEntries.remove(oldest.cacheKey);
      nextManifest = nextManifest.copyWith(
        entries: nextEntries,
        evictionCount: nextManifest.evictionCount + 1,
      );
    }
    return nextManifest;
  }

  String _fileNameFor(String cacheKey, {String? contentType}) {
    final encoded = base64Url.encode(utf8.encode(cacheKey)).replaceAll('=', '');
    final extension = switch (contentType?.toLowerCase()) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
    return '$encoded$extension';
  }
}
