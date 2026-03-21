import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:image/image.dart' as img;

void main() {
  test('compresses large opaque profile images to bounded jpeg output', () {
    final source = img.Image(width: 1280, height: 640);
    final bytes = Uint8List.fromList(img.encodePng(source));

    final compressed = compressImageBytesForUpload(
      bytes: bytes,
      sourceName: 'profile.png',
      preset: ImageUploadPreset.profile,
    );

    final decoded = img.decodeImage(compressed.bytes);
    expect(decoded, isNotNull);
    expect(compressed.mimeType, 'image/jpeg');
    expect(compressed.extension, '.jpg');
    expect(decoded!.width, 640);
    expect(decoded.height, 320);
  });

  test(
    'keeps real transparency and feed images within the configured max size',
    () {
      final source = img.Image(width: 2000, height: 1000, numChannels: 4);
      img.fill(source, color: img.ColorRgba8(60, 90, 120, 255));
      for (var x = 0; x < source.width; x++) {
        for (var y = 0; y < source.height ~/ 2; y++) {
          source.setPixelRgba(x, y, 60, 90, 120, 120);
        }
      }
      final bytes = Uint8List.fromList(img.encodePng(source));

      final compressed = compressImageBytesForUpload(
        bytes: bytes,
        sourceName: 'feed.png',
        preset: ImageUploadPreset.feed,
      );

      final decoded = img.decodeImage(compressed.bytes);
      expect(decoded, isNotNull);
      expect(compressed.mimeType, 'image/png');
      expect(compressed.extension, '.png');
      expect(decoded!.width, 1600);
      expect(decoded.height, 800);
    },
  );

  test(
    'converts marginal transparency to jpeg so screenshots do not stay png',
    () {
      final source = img.Image(width: 2000, height: 1000, numChannels: 4);
      img.fill(source, color: img.ColorRgba8(240, 240, 240, 255));
      source.setPixelRgba(0, 0, 240, 240, 240, 0);
      final bytes = Uint8List.fromList(img.encodePng(source));

      final compressed = compressImageBytesForUpload(
        bytes: bytes,
        sourceName: 'window-screenshot.png',
        preset: ImageUploadPreset.feed,
      );

      final decoded = img.decodeImage(compressed.bytes);
      expect(decoded, isNotNull);
      expect(compressed.mimeType, 'image/jpeg');
      expect(compressed.extension, '.jpg');
      expect(decoded!.width, 1600);
      expect(decoded.height, 800);
    },
  );

  test('does not upscale small images', () {
    final source = img.Image(width: 300, height: 200);
    final bytes = Uint8List.fromList(img.encodeJpg(source));

    final compressed = compressImageBytesForUpload(
      bytes: bytes,
      sourceName: 'small.jpg',
      preset: ImageUploadPreset.profile,
    );

    final decoded = img.decodeImage(compressed.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 300);
    expect(decoded.height, 200);
  });

  test('normalizes orientation metadata and strips image metadata', () {
    final source = img.Image(width: 1200, height: 800)
      ..exif.imageIfd.orientation = 6
      ..textData = <String, String>{'comment': 'keep me out'};
    final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 96));

    final compressed = compressImageBytesForUpload(
      bytes: bytes,
      sourceName: 'rotated.jpg',
      preset: ImageUploadPreset.feed,
    );

    final decoded = img.decodeImage(compressed.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 800);
    expect(decoded.height, 1200);
    expect(decoded.exif.imageIfd.hasOrientation, isFalse);
    expect(decoded.textData, isNull);
    expect(decoded.iccProfile, isNull);
  });

  test('falls back to the original bytes for undecodable images', () {
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);

    final compressed = compressImageBytesForUpload(
      bytes: bytes,
      sourceName: 'broken.webp',
      mimeTypeHint: 'image/webp',
      preset: ImageUploadPreset.feed,
    );

    expect(compressed.bytes, bytes);
    expect(compressed.mimeType, 'image/webp');
    expect(compressed.extension, '.webp');
  });
}
