import 'dart:async';
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

  Future<T> _serializeWrite<T>(Future<T> Function() operation) {
    final nextWrite = _writeQueue.then((_) async {
      return operation();
    });
    _writeQueue = nextWrite.then<void>((_) {}, onError: (_, _) {});
    return nextWrite;
  }

  Future<void> _updateManifest(
    FutureOr<MediaCacheManifest> Function(MediaCacheManifest manifest)
    transform,
  ) {
    return _serializeWrite(() async {
      final manifest = await _readManifest();
      final nextManifest = await transform(manifest);
      await _writeManifest(nextManifest);
    });
  }

  Future<void> _updateManifestBestEffort(
    FutureOr<MediaCacheManifest> Function(MediaCacheManifest manifest)
    transform,
  ) async {
    try {
      await _updateManifest(transform);
    } catch (_) {}
  }

  Future<Uint8List?> read(String cacheKey) async {
    final manifest = await _readManifest();
    final entry = manifest.entries[cacheKey];
    if (entry == null) {
      return null;
    }
    final bytes = await _backend.readBytes(entry.relativePath);
    if (bytes == null) {
      await _updateManifestBestEffort((current) {
        final nextEntries = Map<String, MediaCacheEntry>.from(current.entries);
        nextEntries.remove(cacheKey);
        return current.copyWith(entries: nextEntries);
      });
      return null;
    }
    await _updateManifestBestEffort((current) {
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
    await _serializeWrite(() async {
      final manifest = await _readManifest();
      final now = DateTime.now();
      final fileName = _fileNameFor(cacheKey, contentType: contentType);
      final relativePath = 'media/files/$fileName';
      await _backend.writeBytesAtomically(relativePath, bytes);

      final nextEntries = Map<String, MediaCacheEntry>.from(manifest.entries);
      final previousEntry = nextEntries[cacheKey];
      nextEntries[cacheKey] = MediaCacheEntry(
        cacheKey: cacheKey,
        relativePath: relativePath,
        byteCount: bytes.length,
        cachedAt: now,
        lastAccessedAt: now,
        scopeUserId: scopeUserId,
      );
      final evictionPlan = _planEvictions(
        manifest.copyWith(entries: nextEntries),
      );
      final filesToDelete = <String>{
        ...evictionPlan.filesToDelete,
        if (previousEntry != null && previousEntry.relativePath != relativePath)
          previousEntry.relativePath,
      };

      try {
        await _writeManifest(evictionPlan.manifest);
      } catch (_) {
        if (previousEntry == null ||
            previousEntry.relativePath != relativePath) {
          await _deleteFileBestEffort(relativePath);
        }
        rethrow;
      }

      await _deleteFilesBestEffort(filesToDelete);
    });
  }

  Future<void> purgeScope(String userId) {
    return _serializeWrite(() async {
      final manifest = await _readManifest();
      final nextEntries = <String, MediaCacheEntry>{};
      final filesToDelete = <String>{};
      for (final entry in manifest.entries.entries) {
        if (entry.value.scopeUserId == userId) {
          filesToDelete.add(entry.value.relativePath);
          continue;
        }
        nextEntries[entry.key] = entry.value;
      }
      await _writeManifest(manifest.copyWith(entries: nextEntries));
      await _deleteFilesBestEffort(filesToDelete);
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

  _MediaEvictionPlan _planEvictions(MediaCacheManifest manifest) {
    var nextManifest = manifest;
    final filesToDelete = <String>{};
    while (nextManifest.totalBytes > nextManifest.sizeLimitBytes &&
        nextManifest.entries.isNotEmpty) {
      final oldest = nextManifest.entries.values.reduce((left, right) {
        return left.lastAccessedAt.isBefore(right.lastAccessedAt)
            ? left
            : right;
      });
      filesToDelete.add(oldest.relativePath);
      final nextEntries = Map<String, MediaCacheEntry>.from(
        nextManifest.entries,
      );
      nextEntries.remove(oldest.cacheKey);
      nextManifest = nextManifest.copyWith(
        entries: nextEntries,
        evictionCount: nextManifest.evictionCount + 1,
      );
    }
    return _MediaEvictionPlan(
      manifest: nextManifest,
      filesToDelete: filesToDelete,
    );
  }

  Future<void> _deleteFilesBestEffort(Iterable<String> relativePaths) async {
    for (final relativePath in relativePaths) {
      await _deleteFileBestEffort(relativePath);
    }
  }

  Future<void> _deleteFileBestEffort(String relativePath) async {
    try {
      await _backend.deleteFile(relativePath);
    } catch (_) {}
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

class _MediaEvictionPlan {
  const _MediaEvictionPlan({
    required this.manifest,
    required this.filesToDelete,
  });

  final MediaCacheManifest manifest;
  final Set<String> filesToDelete;
}
