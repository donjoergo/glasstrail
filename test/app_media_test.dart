import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/app_media.dart';

void main() {
  test('resolves data URLs to memory images', () async {
    final bytes = Uint8List.fromList(<int>[137, 80, 78, 71]);
    final imagePath = UriData.fromBytes(
      bytes,
      mimeType: 'image/png',
    ).toString();

    final provider = await AppMediaResolver.resolveImageProvider(imagePath);

    expect(provider, isA<MemoryImage>());
  });
}
