import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract class PhotoService {
  const PhotoService();

  Future<String?> pickImage();
}

class FileSelectorPhotoService extends PhotoService {
  const FileSelectorPhotoService();

  @override
  Future<String?> pickImage() async {
    final image = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'images',
          extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
        ),
      ],
    );
    if (image == null) {
      return null;
    }
    if (kIsWeb) {
      return _serializeWebImage(image);
    }
    return _materializeImagePath(image);
  }

  Future<String> _serializeWebImage(XFile image) async {
    final bytes = await image.readAsBytes();
    return UriData.fromBytes(
      bytes,
      mimeType: image.mimeType ?? _guessMimeType(image),
    ).toString();
  }

  Future<String> _materializeImagePath(XFile image) async {
    final normalizedPath = _normalizedStablePath(image.path);
    if (normalizedPath != null) {
      return normalizedPath;
    }

    final temporaryDirectory = await getTemporaryDirectory();
    final extension = _imageExtension(image);
    final targetPath =
        '${temporaryDirectory.path}/'
        'glasstrail-${DateTime.now().microsecondsSinceEpoch}$extension';
    await image.saveTo(targetPath);
    return targetPath;
  }

  String? _normalizedStablePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed.startsWith('content://')) {
      return null;
    }
    if (trimmed.startsWith('file://')) {
      return Uri.parse(trimmed).toFilePath();
    }
    if (trimmed.startsWith('/')) {
      return trimmed;
    }
    if (trimmed.contains(':\\')) {
      return trimmed;
    }
    return null;
  }

  String _imageExtension(XFile image) {
    final candidates = <String>[image.name, image.path];
    for (final candidate in candidates) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final dotIndex = trimmed.lastIndexOf('.');
      if (dotIndex == -1 || dotIndex == trimmed.length - 1) {
        continue;
      }
      final extension = trimmed.substring(dotIndex).toLowerCase();
      if (<String>{'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)) {
        return extension;
      }
    }
    return '.jpg';
  }

  String _guessMimeType(XFile image) {
    final extension = _imageExtension(image);
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
