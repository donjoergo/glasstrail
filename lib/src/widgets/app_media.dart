import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppAvatar extends StatefulWidget {
  const AppAvatar({
    super.key,
    required this.imagePath,
    required this.radius,
    required this.fallback,
    this.backgroundColor,
  });

  final String? imagePath;
  final double radius;
  final Widget fallback;
  final Color? backgroundColor;

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar> {
  late Future<ImageProvider<Object>?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateImageFuture();
  }

  @override
  void didUpdateWidget(covariant AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _updateImageFuture();
    }
  }

  void _updateImageFuture() {
    _imageFuture = AppMediaResolver.resolveImageProvider(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    final backgroundColor =
        widget.backgroundColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.14);

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: backgroundColor,
          child: FutureBuilder<ImageProvider<Object>?>(
            future: _imageFuture,
            builder: (context, snapshot) {
              final imageProvider = snapshot.data;
              if (imageProvider == null) {
                return Center(child: widget.fallback);
              }
              return Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: widget.fallback),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AppPhotoPreview extends StatefulWidget {
  const AppPhotoPreview({
    super.key,
    required this.imagePath,
    this.cropPortraitToSquare = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.placeholderIcon = Icons.image_outlined,
    this.backgroundColor,
    this.enableFullscreenOnTap = false,
  });

  final String? imagePath;
  final bool cropPortraitToSquare;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final Color? backgroundColor;
  final bool enableFullscreenOnTap;

  @override
  State<AppPhotoPreview> createState() => _AppPhotoPreviewState();
}

class AppGalleryViewerItem {
  const AppGalleryViewerItem({
    required this.imagePath,
    required this.drinkName,
    this.metadata = const <String>[],
    this.comment,
  });

  final String imagePath;
  final String drinkName;
  final List<String> metadata;
  final String? comment;
}

Future<void> showAppGalleryViewerDialog(
  BuildContext context, {
  required List<AppGalleryViewerItem> items,
  required int initialIndex,
}) {
  if (items.isEmpty) {
    return Future<void>.value();
  }

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    useSafeArea: false,
    builder: (context) =>
        _AppGalleryViewerDialog(items: items, initialIndex: initialIndex),
  );
}

class _AppPhotoPreviewState extends State<AppPhotoPreview> {
  late Future<ImageProvider<Object>?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateImageFuture();
  }

  @override
  void didUpdateWidget(covariant AppPhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _updateImageFuture();
    }
  }

  void _updateImageFuture() {
    _imageFuture = AppMediaResolver.resolveImageProvider(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider<Object>?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        final imageProvider = snapshot.data;
        if (imageProvider == null) {
          return _PhotoPlaceholder(
            cropPortraitToSquare: widget.cropPortraitToSquare,
            borderRadius: widget.borderRadius,
            placeholderIcon: widget.placeholderIcon,
            backgroundColor: widget.backgroundColor,
          );
        }
        return _ResolvedPhotoPreview(
          imageProvider: imageProvider,
          cropPortraitToSquare: widget.cropPortraitToSquare,
          borderRadius: widget.borderRadius,
          placeholderIcon: widget.placeholderIcon,
          backgroundColor: widget.backgroundColor,
          enableFullscreenOnTap: widget.enableFullscreenOnTap,
        );
      },
    );
  }
}

class _ResolvedPhotoPreview extends StatefulWidget {
  const _ResolvedPhotoPreview({
    required this.imageProvider,
    required this.cropPortraitToSquare,
    required this.borderRadius,
    required this.placeholderIcon,
    this.backgroundColor,
    required this.enableFullscreenOnTap,
  });

  final ImageProvider<Object> imageProvider;
  final bool cropPortraitToSquare;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final Color? backgroundColor;
  final bool enableFullscreenOnTap;

  @override
  State<_ResolvedPhotoPreview> createState() => _ResolvedPhotoPreviewState();
}

class _ResolvedPhotoPreviewState extends State<_ResolvedPhotoPreview> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  double? _aspectRatio;

  @override
  void didUpdateWidget(covariant _ResolvedPhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider) {
      _aspectRatio = null;
      _resolveImage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveImage() {
    final newStream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    if (_imageStream?.key == newStream.key) {
      return;
    }

    _removeImageListener();
    _imageStream = newStream;
    _imageListener = ImageStreamListener(
      (image, _) {
        final nextAspectRatio = image.image.width / image.image.height;
        if (!mounted || _aspectRatio == nextAspectRatio) {
          return;
        }
        setState(() {
          _aspectRatio = nextAspectRatio;
        });
      },
      onError: (_, _) {
        if (!mounted || _aspectRatio == 1) {
          return;
        }
        setState(() {
          _aspectRatio = 1;
        });
      },
    );
    _imageStream!.addListener(_imageListener!);
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final rawAspectRatio = _aspectRatio;
    final effectiveAspectRatio = rawAspectRatio == null
        ? (widget.cropPortraitToSquare ? 1.0 : 4 / 3)
        : (widget.cropPortraitToSquare && rawAspectRatio < 1
              ? 1.0
              : rawAspectRatio);
    final preview = AspectRatio(
      aspectRatio: effectiveAspectRatio,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: ColoredBox(
          color:
              widget.backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Image(
            image: widget.imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _PhotoPlaceholderBody(placeholderIcon: widget.placeholderIcon),
          ),
        ),
      ),
    );

    if (!widget.enableFullscreenOnTap) {
      return preview;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onTap: () {
          showDialog<void>(
            context: context,
            barrierColor: Colors.black87,
            useSafeArea: false,
            builder: (context) =>
                _FullscreenPhotoDialog(imageProvider: widget.imageProvider),
          );
        },
        child: preview,
      ),
    );
  }
}

class _FullscreenPhotoDialog extends StatefulWidget {
  const _FullscreenPhotoDialog({required this.imageProvider});

  final ImageProvider<Object> imageProvider;

  @override
  State<_FullscreenPhotoDialog> createState() => _FullscreenPhotoDialogState();
}

class _FullscreenPhotoDialogState extends State<_FullscreenPhotoDialog> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      key: const Key('app-photo-preview-fullscreen'),
      backgroundColor: Colors.black,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              key: const Key('app-photo-preview-interactive-viewer'),
              transformationController: _transformationController,
              minScale: 1,
              maxScale: 4,
              child: SizedBox.expand(
                child: Center(
                  child: Image(
                    image: widget.imageProvider,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    key: const Key('app-photo-preview-fullscreen-close'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppGalleryViewerDialog extends StatefulWidget {
  const _AppGalleryViewerDialog({
    required this.items,
    required this.initialIndex,
  });

  final List<AppGalleryViewerItem> items;
  final int initialIndex;

  @override
  State<_AppGalleryViewerDialog> createState() =>
      _AppGalleryViewerDialogState();
}

class _AppGalleryViewerDialogState extends State<_AppGalleryViewerDialog> {
  late final PageController _pageController;
  late final FocusNode _focusNode;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizedInitialIndex();
    _pageController = PageController(initialPage: _currentIndex);
    _focusNode = FocusNode(debugLabel: 'gallery-viewer-focus');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _normalizedInitialIndex() {
    if (widget.initialIndex < 0) {
      return 0;
    }
    final lastIndex = widget.items.length - 1;
    if (widget.initialIndex > lastIndex) {
      return lastIndex;
    }
    return widget.initialIndex;
  }

  bool get _hasPreviousPage => _currentIndex > 0;

  bool get _hasNextPage => _currentIndex < widget.items.length - 1;

  Future<void> _showPreviousPage() async {
    if (!_hasPreviousPage) {
      return;
    }
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showNextPage() async {
    if (!_hasNextPage) {
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _showPreviousPage();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _showNextPage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_currentIndex];

    return Dialog.fullscreen(
      key: const Key('app-gallery-viewer-fullscreen'),
      backgroundColor: Colors.black,
      child: Focus(
        key: const Key('app-gallery-viewer-focus'),
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: PageView.builder(
                key: const Key('app-gallery-viewer-page-view'),
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  if (_currentIndex == index) {
                    return;
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _GalleryViewerPageImage(
                    key: Key('app-gallery-viewer-image-$index'),
                    imagePath: widget.items[index].imagePath,
                  );
                },
              ),
            ),
            if (widget.items.length > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _GalleryViewerNavButton(
                      icon: Icons.chevron_left_rounded,
                      buttonKey: const Key(
                        'app-gallery-viewer-previous-button',
                      ),
                      enabled: _hasPreviousPage,
                      onPressed: _showPreviousPage,
                    ),
                  ),
                ),
              ),
            if (widget.items.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _GalleryViewerNavButton(
                      icon: Icons.chevron_right_rounded,
                      buttonKey: const Key('app-gallery-viewer-next-button'),
                      enabled: _hasNextPage,
                      onPressed: _showNextPage,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.items.length}',
                          key: const Key('app-gallery-viewer-page-indicator'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        key: const Key('app-gallery-viewer-close'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _GalleryViewerInfoSheet(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryViewerNavButton extends StatelessWidget {
  const _GalleryViewerNavButton({
    required this.icon,
    required this.buttonKey,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final Key buttonKey;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          key: buttonKey,
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          iconSize: 34,
          color: Colors.white,
          splashRadius: 28,
        ),
      ),
    );
  }
}

class _GalleryViewerPageImage extends StatefulWidget {
  const _GalleryViewerPageImage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<_GalleryViewerPageImage> createState() =>
      _GalleryViewerPageImageState();
}

class _GalleryViewerPageImageState extends State<_GalleryViewerPageImage> {
  late Future<ImageProvider<Object>?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateImageFuture();
  }

  @override
  void didUpdateWidget(covariant _GalleryViewerPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _updateImageFuture();
    }
  }

  void _updateImageFuture() {
    _imageFuture = AppMediaResolver.resolveImageProvider(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider<Object>?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final imageProvider = snapshot.data;
        if (imageProvider == null) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          );
        }

        return InteractiveViewer(
          key: const Key('app-gallery-viewer-interactive-viewer'),
          minScale: 1,
          maxScale: 4,
          panEnabled: false,
          child: SizedBox.expand(
            child: Center(
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GalleryViewerInfoSheet extends StatelessWidget {
  const _GalleryViewerInfoSheet({required this.item});

  final AppGalleryViewerItem item;

  @override
  Widget build(BuildContext context) {
    final metadata = item.metadata.where((value) => value.trim().isNotEmpty);
    final comment = item.comment?.trim();

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 260),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              key: const Key('app-gallery-viewer-info-sheet'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.drinkName,
                  key: const Key('app-gallery-viewer-drink-name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (metadata.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metadata
                        .map(
                          (value) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (comment != null && comment.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    comment,
                    key: const Key('app-gallery-viewer-comment'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.cropPortraitToSquare,
    required this.borderRadius,
    required this.placeholderIcon,
    this.backgroundColor,
  });

  final bool cropPortraitToSquare;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: cropPortraitToSquare ? 1 : 4 / 3,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(
          color:
              backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: _PhotoPlaceholderBody(placeholderIcon: placeholderIcon),
        ),
      ),
    );
  }
}

class _PhotoPlaceholderBody extends StatelessWidget {
  const _PhotoPlaceholderBody({required this.placeholderIcon});

  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        placeholderIcon,
        size: 30,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class AppMediaResolver {
  AppMediaResolver._();

  static const _mediaBucket = 'user-media';
  static final Map<String, _SignedUrlCacheEntry> _signedUrlCache =
      <String, _SignedUrlCacheEntry>{};
  static final Map<String, Future<String?>> _signedUrlRequests =
      <String, Future<String?>>{};

  static Future<ImageProvider<Object>?> resolveImageProvider(
    String? imagePath,
  ) async {
    final normalized = imagePath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    if (_looksLikeDataUrl(normalized)) {
      final uriData = Uri.parse(normalized).data;
      final bytes = uriData?.contentAsBytes();
      if (bytes == null) {
        return null;
      }
      return MemoryImage(bytes);
    }

    if (_looksLikeRemoteUrl(normalized)) {
      return NetworkImage(normalized);
    }

    if (_looksLikeLocalFile(normalized)) {
      final bytes = await XFile(_normalizeLocalPath(normalized)).readAsBytes();
      return MemoryImage(bytes);
    }

    final signedUrl = await _resolveSignedStorageUrl(normalized);
    if (signedUrl == null) {
      return null;
    }
    return NetworkImage(signedUrl);
  }

  static Future<String?> _resolveSignedStorageUrl(String path) {
    final cached = _signedUrlCache[path];
    if (cached != null && !cached.isExpired) {
      return Future<String?>.value(cached.url);
    }

    final inFlight = _signedUrlRequests[path];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _createSignedStorageUrl(path);
    _signedUrlRequests[path] = request;
    return request.whenComplete(() {
      _signedUrlRequests.remove(path);
    });
  }

  static Future<String?> _createSignedStorageUrl(String path) async {
    final client = _trySupabaseClient();
    if (client == null) {
      return null;
    }

    final url = await client.storage
        .from(_mediaBucket)
        .createSignedUrl(path, 60 * 60);
    _signedUrlCache[path] = _SignedUrlCacheEntry(
      url: url,
      expiresAt: DateTime.now().add(const Duration(minutes: 50)),
    );
    return url;
  }

  static SupabaseClient? _trySupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeRemoteUrl(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:');
  }

  static bool _looksLikeDataUrl(String path) {
    return path.startsWith('data:');
  }

  static bool _looksLikeLocalFile(String path) {
    if (path.startsWith('file://')) {
      return true;
    }
    if (path.startsWith('/')) {
      return true;
    }
    return path.contains(':\\');
  }

  static String _normalizeLocalPath(String path) {
    if (!path.startsWith('file://')) {
      return path;
    }
    return Uri.parse(path).toFilePath();
  }
}

class _SignedUrlCacheEntry {
  const _SignedUrlCacheEntry({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
