import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
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

  testWidgets(
    'opens gallery viewer with edge buttons, keyboard, and swipe navigation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () {
                      showAppGalleryViewerDialog(
                        context,
                        items: const <AppGalleryViewerItem>[
                          AppGalleryViewerItem(
                            imagePath: transparentPngDataUrl,
                            drinkName: 'First drink',
                            metadata: <String>['Beer', 'Mar 21, 2026 20:15'],
                            comment: 'First comment',
                          ),
                          AppGalleryViewerItem(
                            imagePath: transparentPngDataUrl,
                            drinkName: 'Second drink',
                            metadata: <String>['Wine', 'Mar 21, 2026 19:10'],
                            comment: 'Second comment',
                          ),
                          AppGalleryViewerItem(
                            imagePath: transparentPngDataUrl,
                            drinkName: 'Third drink',
                            metadata: <String>['Water', 'Mar 21, 2026 18:00'],
                            comment: 'Third comment',
                          ),
                        ],
                        initialIndex: 1,
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('app-gallery-viewer-fullscreen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('app-gallery-viewer-page-indicator')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('app-gallery-viewer-previous-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('app-gallery-viewer-next-button')),
        findsOneWidget,
      );
      expect(find.text('Second drink'), findsOneWidget);
      expect(find.text('Second comment'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('app-gallery-viewer-previous-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('First drink'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.text('Second drink'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.fling(
        find.byKey(const Key('app-gallery-viewer-page-view')),
        const Offset(-600, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Third drink'), findsOneWidget);
      expect(find.text('Third comment'), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('app-gallery-viewer-close')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('app-gallery-viewer-fullscreen')),
        findsNothing,
      );
    },
  );
}
