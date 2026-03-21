import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/app_media.dart';

void main() {
  const transparentPngDataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRSEAAAAASUVORK5CYII=';

  test('resolves data URLs to memory images', () async {
    final bytes = Uint8List.fromList(<int>[137, 80, 78, 71]);
    final imagePath = UriData.fromBytes(
      bytes,
      mimeType: 'image/png',
    ).toString();

    final provider = await AppMediaResolver.resolveImageProvider(imagePath);

    expect(provider, isA<MemoryImage>());
  });

  testWidgets('opens fullscreen zoom dialog for tappable previews', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppPhotoPreview(
              imagePath: transparentPngDataUrl,
              enableFullscreenOnTap: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-photo-preview-fullscreen')), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('app-photo-preview-fullscreen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app-photo-preview-interactive-viewer')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('app-photo-preview-fullscreen-close')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-photo-preview-fullscreen')), findsNothing);
  });
}
