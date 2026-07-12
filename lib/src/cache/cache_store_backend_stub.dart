import 'dart:convert';
import 'dart:typed_data';

abstract class CacheStoreBackend {
  Future<String?> readText(String relativePath);
  Future<void> writeTextAtomically(String relativePath, String contents);
  Future<Uint8List?> readBytes(String relativePath);
  Future<void> writeBytesAtomically(String relativePath, Uint8List contents);
  Future<void> deleteFile(String relativePath);
  Future<void> deleteDirectory(String relativeDirectory);
  Future<int?> fileLength(String relativePath);
  String absolutePathFor(String relativePath);
}

// Web build target (no dart:io filesystem access): backs the same
// CacheStoreBackend contract with an in-memory map instead. This means the
// cache does not survive a page reload on web — acceptable since the app
// re-fetches from the backend on cold start anyway, and this only needs to
// avoid crashing/no-op-ing where the IO backend would otherwise be used.
Future<CacheStoreBackend> createDefaultCacheStoreBackend({
  String namespace = 'cache',
}) async {
  return _MemoryCacheStoreBackend(namespace: namespace);
}

class _MemoryCacheStoreBackend implements CacheStoreBackend {
  _MemoryCacheStoreBackend({required this.namespace});

  final String namespace;
  final Map<String, Uint8List> _files = <String, Uint8List>{};

  String _key(String relativePath) => '$namespace/$relativePath';

  // There's no real directory structure in a flat map, so "delete a
  // directory" is emulated by removing every key that starts with its
  // path prefix — mirrors the IO backend's recursive directory delete.
  @override
  Future<void> deleteDirectory(String relativeDirectory) async {
    final prefix = _key(relativeDirectory);
    _files.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    _files.remove(_key(relativePath));
  }

  @override
  Future<int?> fileLength(String relativePath) async {
    return _files[_key(relativePath)]?.length;
  }

  // Returns a defensive copy: the caller may mutate the returned bytes, and
  // since this backend stores the actual bytes by reference (unlike the IO
  // backend, which re-reads from disk each time), handing out the original
  // array would let a caller's mutation silently corrupt the cached value.
  @override
  Future<Uint8List?> readBytes(String relativePath) async {
    final bytes = _files[_key(relativePath)];
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
    _files[_key(relativePath)] = Uint8List.fromList(contents);
  }

  @override
  Future<void> writeTextAtomically(String relativePath, String contents) {
    return writeBytesAtomically(
      relativePath,
      Uint8List.fromList(utf8.encode(contents)),
    );
  }

  @override
  String absolutePathFor(String relativePath) => _key(relativePath);
}
