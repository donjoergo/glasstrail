import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart'
    show CameraDevice, ImagePicker, ImageSource;
import 'package:path_provider/path_provider.dart';

// Below this fraction of transparent pixels, PNG's lossless-but-larger
// output isn't worth it — the transparency is likely just anti-aliasing
// noise around edges rather than a meaningful transparent region, so it's
// flattened to JPEG instead for a much smaller upload.
const double _marginalTransparencyRatio = 0.02;

enum ImageUploadPreset {
  // Avatars are shown small everywhere, so they're capped tighter and
  // compressed harder than feed photos, which need to hold up at
  // near-fullscreen viewing sizes.
  profile(maxWidth: 640, maxHeight: 640, jpegQuality: 80),
  feed(maxWidth: 1600, maxHeight: 1600, jpegQuality: 78);

  const ImageUploadPreset({
    required this.maxWidth,
    required this.maxHeight,
    required this.jpegQuality,
  });

  final int maxWidth;
  final int maxHeight;
  final int jpegQuality;
}

enum PhotoPickSource { gallery, camera }

abstract class PhotoService {
  const PhotoService();

  Future<String?> pickImage({
    required ImageUploadPreset preset,
    PhotoPickSource source = PhotoPickSource.gallery,
  });
}

class FileSelectorPhotoService extends PhotoService {
  const FileSelectorPhotoService();

  @override
  Future<String?> pickImage({
    required ImageUploadPreset preset,
    PhotoPickSource source = PhotoPickSource.gallery,
  }) async {
    final image = await _pickSourceImage(source);
    if (image == null) {
      return null;
    }

    final compressed = await compressImageForUpload(image, preset: preset);
    if (kIsWeb) {
      // Web has no writable filesystem to stash a temp file in, so the
      // compressed image is carried around as a data: URL instead; see
      // AppMediaResolver, which knows how to decode this shape.
      return UriData.fromBytes(
        compressed.bytes,
        mimeType: compressed.mimeType,
      ).toString();
    }
    return _materializeImagePath(compressed);
  }

  Future<XFile?> _pickSourceImage(PhotoPickSource source) {
    // Android is the only platform where camera-vs-gallery needs to be
    // requested explicitly via image_picker; elsewhere file_selector's
    // native picker already covers both (see photo_pick_flow.dart).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return ImagePicker().pickImage(
        source: switch (source) {
          PhotoPickSource.gallery => ImageSource.gallery,
          PhotoPickSource.camera => ImageSource.camera,
        },
        preferredCameraDevice: CameraDevice.rear,
      );
    }

    return openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'images',
          extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
        ),
      ],
    );
  }

  Future<String> _materializeImagePath(CompressedUploadImage image) async {
    final temporaryDirectory = await getTemporaryDirectory();
    final targetPath =
        '${temporaryDirectory.path}/'
        'glasstrail-${DateTime.now().microsecondsSinceEpoch}${image.extension}';
    final xFile = XFile.fromData(
      image.bytes,
      mimeType: image.mimeType,
      name: 'glasstrail${image.extension}',
    );
    await xFile.saveTo(targetPath);
    return targetPath;
  }
}

class CompressedUploadImage {
  const CompressedUploadImage({
    required this.bytes,
    required this.mimeType,
    required this.extension,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
}

@visibleForTesting
Future<CompressedUploadImage> compressImageForUpload(
  XFile image, {
  required ImageUploadPreset preset,
}) async {
  final bytes = await image.readAsBytes();
  // Decoding/resizing/re-encoding a full-resolution camera photo is CPU
  // heavy enough to visibly stall the UI thread, so it runs in a
  // background isolate via compute(). Only primitive/serializable data can
  // cross the isolate boundary, hence passing a plain Map instead of the
  // richer XFile/preset objects.
  final payload = await compute<Map<String, Object?>, Map<String, Object?>>(
    _compressImageForUploadInBackground,
    <String, Object?>{
      'bytes': bytes,
      'sourceName': image.name.isNotEmpty ? image.name : image.path,
      'mimeTypeHint': image.mimeType,
      'presetIndex': preset.index,
    },
  );
  return CompressedUploadImage(
    bytes: payload['bytes']! as Uint8List,
    mimeType: payload['mimeType']! as String,
    extension: payload['extension']! as String,
  );
}

@visibleForTesting
CompressedUploadImage compressImageBytesForUpload({
  required Uint8List bytes,
  String? sourceName,
  String? mimeTypeHint,
  required ImageUploadPreset preset,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    // Format the `image` package can't decode (e.g. HEIC on some
    // platforms, or an unusual format) — better to upload the original
    // bytes as-is than to block the user from attaching a photo at all.
    return _fallbackCompressedImage(
      bytes: bytes,
      sourceName: sourceName,
      mimeTypeHint: mimeTypeHint,
    );
  }

  // Camera photos often carry an EXIF orientation flag rather than being
  // physically rotated; baking it in up front ensures the pixel data
  // itself is upright before resizing/stripping EXIF (which would
  // otherwise discard the orientation info the photo relied on).
  final oriented = img.bakeOrientation(decoded);
  final resized = _resizeWithinBounds(
    oriented,
    maxWidth: preset.maxWidth,
    maxHeight: preset.maxHeight,
  );
  final transparency = _transparencyStats(resized);
  // Strip metadata (EXIF/ICC/text) after resizing so it doesn't need to be
  // carried through the resize step, and importantly before upload so GPS
  // coordinates and similar embedded metadata never leave the device.
  _stripMetadata(resized);

  final jpegImage = transparency.hasTransparency
      ? _flattenToOpaque(resized)
      : resized;
  final jpeg = CompressedUploadImage(
    bytes: Uint8List.fromList(
      img.encodeJpg(jpegImage, quality: preset.jpegQuality),
    ),
    mimeType: 'image/jpeg',
    extension: '.jpg',
  );

  if (!transparency.hasTransparency) {
    return jpeg;
  }

  // Encoded eagerly even though it may be discarded below (when
  // transparency is only marginal) — the ratio to decide between them
  // isn't known to be "worth it" until compared against the threshold.
  final png = CompressedUploadImage(
    bytes: Uint8List.fromList(img.encodePng(resized)),
    mimeType: 'image/png',
    extension: '.png',
  );
  if (transparency.ratio <= _marginalTransparencyRatio) {
    return jpeg;
  }
  return png;
}

_TransparencyStats _transparencyStats(img.Image image) {
  if (!image.hasAlpha) {
    return const _TransparencyStats(transparentPixels: 0, totalPixels: 1);
  }

  final maxAlpha = image.maxChannelValue;
  var transparentPixels = 0;
  for (final pixel in image) {
    if (pixel.a < maxAlpha) {
      transparentPixels++;
    }
  }
  return _TransparencyStats(
    transparentPixels: transparentPixels,
    totalPixels: image.width * image.height,
  );
}

img.Image _resizeWithinBounds(
  img.Image image, {
  required int maxWidth,
  required int maxHeight,
}) {
  final widthScale = maxWidth / image.width;
  final heightScale = maxHeight / image.height;
  final scale = math.min(1.0, math.min(widthScale, heightScale));
  if (scale >= 1.0) {
    return image;
  }

  final targetWidth = math.max(1, (image.width * scale).round());
  final targetHeight = math.max(1, (image.height * scale).round());
  return img.copyResize(
    image,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.linear,
  );
}

void _stripMetadata(img.Image image) {
  image.exif = img.ExifData();
  image.iccProfile = null;
  image.textData = null;
}

img.Image _flattenToOpaque(img.Image image) {
  // JPEG has no alpha channel, so transparent pixels are composited onto a
  // white background before encoding rather than being silently dropped
  // (which would leave black/undefined pixels where transparency was).
  final flattened = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 3,
  );
  img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(flattened, image);
  _stripMetadata(flattened);
  return flattened;
}

CompressedUploadImage _fallbackCompressedImage({
  required Uint8List bytes,
  String? sourceName,
  String? mimeTypeHint,
}) {
  final mimeType = _guessMimeType(
    sourceName: sourceName,
    mimeTypeHint: mimeTypeHint,
  );
  return CompressedUploadImage(
    bytes: bytes,
    mimeType: mimeType,
    extension: _extensionForMimeType(mimeType),
  );
}

String _guessMimeType({String? sourceName, String? mimeTypeHint}) {
  final normalizedMime = mimeTypeHint?.trim().toLowerCase();
  if (normalizedMime != null && normalizedMime.startsWith('image/')) {
    return normalizedMime;
  }

  final lowerName = sourceName?.trim().toLowerCase() ?? '';
  if (lowerName.endsWith('.png')) {
    return 'image/png';
  }
  if (lowerName.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

String _extensionForMimeType(String mimeType) {
  return switch (mimeType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => '.jpg',
  };
}

Map<String, Object?> _compressImageForUploadInBackground(
  Map<String, Object?> payload,
) {
  final compressed = compressImageBytesForUpload(
    bytes: payload['bytes']! as Uint8List,
    sourceName: payload['sourceName'] as String?,
    mimeTypeHint: payload['mimeTypeHint'] as String?,
    preset: ImageUploadPreset.values[payload['presetIndex']! as int],
  );
  return <String, Object?>{
    'bytes': compressed.bytes,
    'mimeType': compressed.mimeType,
    'extension': compressed.extension,
  };
}

class _TransparencyStats {
  const _TransparencyStats({
    required this.transparentPixels,
    required this.totalPixels,
  });

  final int transparentPixels;
  final int totalPixels;

  bool get hasTransparency => transparentPixels > 0;

  double get ratio => transparentPixels / totalPixels;
}
