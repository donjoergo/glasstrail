import 'package:flutter/material.dart';

import '../drink_icon_assets.dart';
import '../models.dart';
import 'app_media.dart';

const double _appDrinkIconFallbackGlyphScale = 0.76;
const double _appDrinkIconBuiltInAssetScale = 0.94;

class AppDrinkIcon extends StatefulWidget {
  const AppDrinkIcon({
    super.key,
    required this.drinkId,
    required this.category,
    this.accentColorHex,
    this.imagePath,
    this.preferPhoto = true,
    this.size = 24,
    this.iconSize,
    this.assetScale = _appDrinkIconBuiltInAssetScale,
  });

  final String drinkId;
  final DrinkCategory category;
  final String? accentColorHex;
  final String? imagePath;
  final bool preferPhoto;
  final double size;
  final double? iconSize;
  final double assetScale;

  @override
  State<AppDrinkIcon> createState() => _AppDrinkIconState();
}

class _AppDrinkIconState extends State<AppDrinkIcon> {
  late Future<_ResolvedDrinkIcon?> _iconFuture;

  @override
  void initState() {
    super.initState();
    _updateIconFuture();
  }

  @override
  void didUpdateWidget(covariant AppDrinkIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drinkId != widget.drinkId ||
        oldWidget.category != widget.category ||
        oldWidget.imagePath != widget.imagePath ||
        oldWidget.preferPhoto != widget.preferPhoto) {
      _updateIconFuture();
    }
  }

  void _updateIconFuture() {
    _iconFuture = _resolveIcon();
  }

  Future<_ResolvedDrinkIcon?> _resolveIcon() async {
    if (widget.preferPhoto) {
      final photoProvider = await AppMediaResolver.resolveImageProvider(
        widget.imagePath,
      );
      if (photoProvider != null) {
        return _ResolvedDrinkIcon(
          provider: photoProvider,
          fit: BoxFit.cover,
          fillsCircle: true,
        );
      }
    }

    final assetPath = builtInDrinkIconAssetPath(widget.drinkId);
    if (assetPath != null) {
      return _ResolvedDrinkIcon(
        provider: AssetImage(assetPath),
        fit: BoxFit.contain,
        fillsCircle: false,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visual = resolveDrinkIconVisual(
      theme: Theme.of(context),
      drinkId: widget.drinkId,
      category: widget.category,
      accentColorHex: widget.accentColorHex,
    );
    final fallbackIcon = Icon(
      widget.category.icon,
      size: widget.iconSize ?? (widget.size * _appDrinkIconFallbackGlyphScale),
      color: visual.foregroundColor,
    );

    return SizedBox.square(
      dimension: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: FutureBuilder<_ResolvedDrinkIcon?>(
            future: _iconFuture,
            builder: (context, snapshot) {
              final resolved = snapshot.data;
              if (resolved == null) {
                return Center(child: fallbackIcon);
              }

              final contentSize = resolved.fillsCircle
                  ? widget.size
                  : widget.size * widget.assetScale;

              return Center(
                child: SizedBox.square(
                  dimension: contentSize,
                  child: Image(
                    image: resolved.provider,
                    fit: resolved.fit,
                    errorBuilder: (_, _, _) => Center(child: fallbackIcon),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResolvedDrinkIcon {
  const _ResolvedDrinkIcon({
    required this.provider,
    required this.fit,
    required this.fillsCircle,
  });

  final ImageProvider<Object> provider;
  final BoxFit fit;
  final bool fillsCircle;
}
