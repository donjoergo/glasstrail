import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/app_media.dart';

class _TestPreviewImageSpec {
  const _TestPreviewImageSpec({
    required this.width,
    required this.height,
    this.ready,
  });

  final int width;
  final int height;
  final Future<void>? ready;
}

class _TestPreviewImageProvider
    extends ImageProvider<_TestPreviewImageProvider> {
  const _TestPreviewImageProvider({
    required this.width,
    required this.height,
    this.ready,
  });

  final int width;
  final int height;
  final Future<void>? ready;

  @override
  Future<_TestPreviewImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<_TestPreviewImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _TestPreviewImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_load());
  }

  Future<ImageInfo> _load() async {
    if (ready != null) {
      await ready;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF4A6572);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );
    final image = await recorder.endRecording().toImage(width, height);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) {
    return other is _TestPreviewImageProvider &&
        width == other.width &&
        height == other.height &&
        identical(ready, other.ready);
  }

  @override
  int get hashCode => Object.hash(width, height, ready);
}

double _previewAspectRatio(WidgetTester tester, Key key) {
  final aspectRatio = find.descendant(
    of: find.byKey(key),
    matching: find.byType(AspectRatio),
  );
  return tester.widget<AspectRatio>(aspectRatio.first).aspectRatio;
}

Widget _buildPreviewHarness(List<Widget> children) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpPreviewFrames(WidgetTester tester, {int count = 6}) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  const transparentPngDataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRSEAAAAASUVORK5CYII=';
  const wideImagePath = 'debug-wide-preview';
  const portraitImagePath = 'debug-portrait-preview';
  const widerImagePath = 'debug-wider-preview';
  late Map<String, _TestPreviewImageSpec> imageSpecs;

  setUp(() {
    debugResetAppPhotoPreviewAspectRatioCache();
    PaintingBinding.instance.imageCache.clear();
    imageSpecs = <String, _TestPreviewImageSpec>{};
  });

  tearDown(() {
    AppMediaResolver.debugImageProviderResolverOverride = null;
  });

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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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

  testWidgets('opens fullscreen zoom dialog for tappable avatars', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: Center(
            child: AppAvatar(
              key: const Key('test-avatar'),
              imagePath: transparentPngDataUrl,
              radius: 30,
              enableFullscreenOnTap: true,
              fallback: const Text('AB'),
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

    await tester.tap(
      find.byKey(const Key('app-photo-preview-fullscreen-close')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-photo-preview-fullscreen')), findsNothing);
  });

  testWidgets('avatar fallback initials are not tappable to fullscreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: Center(
            child: AppAvatar(
              key: const Key('test-avatar'),
              imagePath: null,
              radius: 30,
              enableFullscreenOnTap: true,
              fallback: const Text('AB'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('test-avatar')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'opens gallery viewer with edge buttons, keyboard, and swipe navigation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
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

  testWidgets(
    'keeps wide previews wide and portrait previews square after remounting',
    (tester) async {
      imageSpecs = <String, _TestPreviewImageSpec>{
        wideImagePath: const _TestPreviewImageSpec(width: 2, height: 1),
        portraitImagePath: const _TestPreviewImageSpec(width: 1, height: 2),
      };
      AppMediaResolver.debugImageProviderResolverOverride =
          (String? imagePath) async {
            final normalized = imagePath?.trim();
            final spec = normalized == null ? null : imageSpecs[normalized];
            if (spec == null) {
              return null;
            }
            return _TestPreviewImageProvider(
              width: spec.width,
              height: spec.height,
              ready: spec.ready,
            );
          };

      Widget buildHarness() {
        return _buildPreviewHarness(<Widget>[
          AppPhotoPreview(
            key: const Key('wide-preview'),
            imagePath: wideImagePath,
            cropPortraitToSquare: true,
          ),
          const SizedBox(height: 16),
          AppPhotoPreview(
            key: const Key('portrait-preview'),
            imagePath: portraitImagePath,
            cropPortraitToSquare: true,
          ),
        ]);
      }

      await tester.pumpWidget(buildHarness());
      await _pumpPreviewFrames(tester);

      expect(
        _previewAspectRatio(tester, const Key('wide-preview')),
        closeTo(2, 0.01),
      );
      expect(_previewAspectRatio(tester, const Key('portrait-preview')), 1);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      PaintingBinding.instance.imageCache.clear();

      await tester.pumpWidget(buildHarness());
      await _pumpPreviewFrames(tester, count: 2);

      expect(
        _previewAspectRatio(tester, const Key('wide-preview')),
        closeTo(2, 0.01),
      );
      expect(_previewAspectRatio(tester, const Key('portrait-preview')), 1);
    },
  );

  testWidgets(
    'reuses cached preview aspect ratios before the image resolves again',
    (tester) async {
      imageSpecs = <String, _TestPreviewImageSpec>{
        widerImagePath: const _TestPreviewImageSpec(width: 3, height: 1),
      };
      AppMediaResolver.debugImageProviderResolverOverride =
          (String? imagePath) async {
            final normalized = imagePath?.trim();
            final spec = normalized == null ? null : imageSpecs[normalized];
            if (spec == null) {
              return null;
            }
            return _TestPreviewImageProvider(
              width: spec.width,
              height: spec.height,
              ready: spec.ready,
            );
          };

      Widget buildHarness() {
        return _buildPreviewHarness(<Widget>[
          AppPhotoPreview(
            key: const Key('cached-wide-preview'),
            imagePath: widerImagePath,
            cropPortraitToSquare: true,
          ),
        ]);
      }

      await tester.pumpWidget(buildHarness());
      await _pumpPreviewFrames(tester);

      expect(
        _previewAspectRatio(tester, const Key('cached-wide-preview')),
        closeTo(3, 0.01),
      );

      final remountReady = Completer<void>();
      imageSpecs = <String, _TestPreviewImageSpec>{
        widerImagePath: _TestPreviewImageSpec(
          width: 3,
          height: 1,
          ready: remountReady.future,
        ),
      };

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      PaintingBinding.instance.imageCache.clear();

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(
        _previewAspectRatio(tester, const Key('cached-wide-preview')),
        closeTo(3, 0.01),
      );

      remountReady.complete();
      await _pumpPreviewFrames(tester, count: 2);
    },
  );
}
