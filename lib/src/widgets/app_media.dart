import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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
  });

  final String? imagePath;
  final bool cropPortraitToSquare;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final Color? backgroundColor;

  @override
  State<AppPhotoPreview> createState() => _AppPhotoPreviewState();
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
  });

  final ImageProvider<Object> imageProvider;
  final bool cropPortraitToSquare;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final Color? backgroundColor;

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

    return AspectRatio(
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
