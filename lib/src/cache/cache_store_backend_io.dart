import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

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

Future<CacheStoreBackend> createDefaultCacheStoreBackend({
  String namespace = 'cache',
}) async {
  // Application-support (not temp, not documents): unlike temp it isn't
  // liable to be purged by the OS under storage pressure at any moment,
  // and unlike documents it's not user-visible/exported in file pickers or
  // iCloud/Files app — appropriate for cache data that should persist
  // across launches but is entirely internal to the app.
  final baseDirectory = await getApplicationSupportDirectory();
  final rootDirectory = Directory('${baseDirectory.path}/$namespace');
  if (!await rootDirectory.exists()) {
    await rootDirectory.create(recursive: true);
  }
  return _IoCacheStoreBackend(rootDirectory);
}

class _IoCacheStoreBackend implements CacheStoreBackend {
  _IoCacheStoreBackend(this._rootDirectory);

  final Directory _rootDirectory;

  File _fileFor(String relativePath) {
    return File('${_rootDirectory.path}/$relativePath');
  }

  Directory _directoryFor(String relativePath) {
    return Directory('${_rootDirectory.path}/$relativePath');
  }

  Future<void> _ensureParentDirectory(File file) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
  }

  @override
  Future<void> deleteDirectory(String relativeDirectory) async {
    final directory = _directoryFor(relativeDirectory);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    final file = _fileFor(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<int?> fileLength(String relativePath) async {
    final file = _fileFor(relativePath);
    if (!await file.exists()) {
      return null;
    }
    return file.length();
  }

  @override
  Future<Uint8List?> readBytes(String relativePath) async {
    final file = _fileFor(relativePath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<String?> readText(String relativePath) async {
    final file = _fileFor(relativePath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  // Write-to-temp-then-rename so a crash or power loss mid-write can never
  // leave the real cache file truncated/corrupted — the rename is a single
  // filesystem operation, so readers always see either the old complete
  // file or the new complete file, never a partial one. `flush: true`
  // ensures the temp file's bytes are actually durable before the rename.
  @override
  Future<void> writeBytesAtomically(
    String relativePath,
    Uint8List contents,
  ) async {
    final file = _fileFor(relativePath);
    await _ensureParentDirectory(file);
    final temporaryFile = File('${file.path}.tmp');
    await temporaryFile.writeAsBytes(contents, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temporaryFile.rename(file.path);
  }

  @override
  Future<void> writeTextAtomically(String relativePath, String contents) {
    return writeBytesAtomically(
      relativePath,
      Uint8List.fromList(utf8.encode(contents)),
    );
  }

  @override
  String absolutePathFor(String relativePath) => _fileFor(relativePath).path;
}
