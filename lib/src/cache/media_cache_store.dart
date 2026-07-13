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
  // Identity key for the default (no explicit backend) shared instance —
  // a fresh Object() rather than a literal so it can't collide with any
  // caller-supplied backend used as a key.
  static final Object _defaultSharedStoreKey = Object();
  // Caches in-flight/created stores by backend identity so callers that
  // want "the" shared media cache (rather than a private instance, as in
  // tests) always get the same store instead of racing to create duplicate
  // stores over the same files.
  static final Map<Object, Future<MediaCacheStore>> _sharedStoreFutures =
      <Object, Future<MediaCacheStore>>{};

  final CacheStoreBackend _backend;
  // Serializes manifest read-modify-write cycles (writes, reads that bump
  // lastAccessedAt, evictions) so concurrent operations can't race and
  // clobber each other's manifest changes.
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
        // Preserve the previously configured size limit across a schema
        // wipe rather than resetting to the default, since that's a
        // deployment/config concern independent of the manifest's data
        // shape changing.
        await purgeAll();
        return MediaCacheManifest.empty(
          sizeLimitBytes: manifest.sizeLimitBytes,
        );
      }
      return manifest;
    } catch (_) {
      // A corrupt/unreadable manifest is treated as an empty cache instead
      // of propagating — losing the cache index is recoverable (media just
      // gets re-fetched), but crashing here would break every screen that
      // renders an image.
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

  // Used where the manifest update is a side effect of a read (bumping
  // lastAccessedAt, dropping a dangling entry) rather than the operation's
  // actual purpose — failing to persist that bookkeeping shouldn't fail the
  // read itself, so errors are swallowed here but not in _updateManifest.
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
      // The manifest says this entry exists but the underlying file is
      // gone (e.g. deleted by the OS under storage pressure, or a prior
      // eviction/write that didn't fully complete) — drop the dangling
      // manifest entry so future lookups don't keep hitting this same
      // miss-then-cleanup path.
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

  // Ordering here is deliberate for crash-safety: the new file is written
  // before the manifest is updated to reference it (so the manifest never
  // points at a file that doesn't exist yet), and old files (evicted
  // entries, the previous file for this cacheKey if its path changed) are
  // only deleted *after* the manifest write succeeds (so a crash before
  // that point just leaves harmless orphan files instead of a manifest
  // referencing deleted ones). If the manifest write itself fails, the
  // just-written file is rolled back (unless it happens to share the
  // previous entry's path, in which case deleting it would destroy data
  // the manifest still — correctly — points at).
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

  // Simple LRU eviction: repeatedly drops the least-recently-*accessed*
  // entry (not least-recently-written) until the manifest is back under
  // its size limit. A linear scan per eviction is fine here since the
  // media cache holds a bounded, relatively small number of entries — not
  // worth the complexity of a proper priority queue for this cache's scale.
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

  // cacheKey is typically a URL or arbitrary identifier, so it's base64url-
  // encoded into a safe filename (avoids path separators/reserved
  // characters from the original key); padding is stripped since trailing
  // "=" is unnecessary here and not universally filesystem-friendly.
  // Extension is inferred from contentType, defaulting to .jpg since most
  // cached media is photos and an accurate extension isn't load-bearing —
  // the manifest is the source of truth for what's stored where.
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
