part of '../statistics_screen.dart';

String? _normalizedStatisticsText(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

Color _statisticsMapMarkerForegroundColor(Color backgroundColor) {
  final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

Future<void> _showStatisticsMapEntrySheet(
  BuildContext context,
  _StatisticsMapMarkerData marker,
  Color accentColor,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) =>
        _StatisticsMapEntrySheet(entry: marker.entry, accentColor: accentColor),
  );
}

List<Widget> _statisticsMapMarkerWidgets({
  required List<_StatisticsMapMarkerData> markers,
  required List<int> markerIndexes,
  required List<Offset> offsets,
  required Map<DrinkCategory, Color> colors,
  required Future<void> Function(int index, _StatisticsMapMarkerData marker)
  onMarkerTap,
}) {
  return markers.indexed
      .map((markerEntry) {
        final index = markerIndexes[markerEntry.$1];
        final marker = markerEntry.$2;
        final backgroundColor = colors[marker.entry.category]!;
        final offset = offsets[markerEntry.$1];

        return Positioned(
          key: Key('statistics-map-slot-${marker.entry.id}'),
          left: offset.dx - (_statisticsMapMarkerHitSize / 2),
          top: offset.dy - (_statisticsMapMarkerHitSize / 2),
          child: SizedBox(
            width: _statisticsMapMarkerHitSize,
            height: _statisticsMapMarkerHitSize,
            child: Center(
              child: _StatisticsMapMarker(
                entry: marker.entry,
                backgroundColor: backgroundColor,
                foregroundColor: _statisticsMapMarkerForegroundColor(
                  backgroundColor,
                ),
                onTap: () => onMarkerTap(index, marker),
              ),
            ),
          ),
        );
      })
      .toList(growable: false);
}

List<Widget> _statisticsMapClusterOverlayWidgets({
  required List<_StatisticsMapMarkerData> markers,
  required List<Offset> offsets,
  required Map<DrinkCategory, Color> colors,
  required Future<void> Function(int index, _StatisticsMapMarkerData marker)
  onMarkerTap,
  required Future<void> Function(List<int> markerIndexes) onClusterTap,
}) {
  return _statisticsMapScreenClusters(offsets: offsets)
      .map((cluster) {
        final offset = cluster.center;

        if (cluster.markerIndexes.length == 1) {
          final markerIndex = cluster.markerIndexes.single;
          final marker = markers[markerIndex];
          final backgroundColor = colors[marker.entry.category]!;

          return Positioned(
            key: Key('statistics-map-slot-${marker.entry.id}'),
            left: offset.dx - (_statisticsMapMarkerHitSize / 2),
            top: offset.dy - (_statisticsMapMarkerHitSize / 2),
            child: SizedBox(
              width: _statisticsMapMarkerHitSize,
              height: _statisticsMapMarkerHitSize,
              child: Center(
                child: _StatisticsMapMarker(
                  entry: marker.entry,
                  backgroundColor: backgroundColor,
                  foregroundColor: _statisticsMapMarkerForegroundColor(
                    backgroundColor,
                  ),
                  onTap: () => onMarkerTap(markerIndex, marker),
                ),
              ),
            ),
          );
        }

        final clusterKey = cluster.markerIndexes
            .map((index) => markers[index].entry.id)
            .join('-');
        final backgroundColor =
            colors[markers[cluster.markerIndexes.first].entry.category]!;

        return Positioned(
          key: Key('statistics-map-cluster-slot-$clusterKey'),
          left: offset.dx - (_statisticsMapMarkerHitSize / 2),
          top: offset.dy - (_statisticsMapMarkerHitSize / 2),
          child: SizedBox(
            width: _statisticsMapMarkerHitSize,
            height: _statisticsMapMarkerHitSize,
            child: Center(
              child: _StatisticsMapClusterMarker(
                markerIds: clusterKey,
                count: cluster.markerIndexes.length,
                backgroundColor: backgroundColor,
                foregroundColor: _statisticsMapMarkerForegroundColor(
                  backgroundColor,
                ),
                onTap: () => onClusterTap(cluster.markerIndexes),
              ),
            ),
          ),
        );
      })
      .toList(growable: false);
}

List<Widget> _statisticsMapAttributionChildren(ThemeData theme) {
  Widget buildButton({
    required String keyValue,
    required String label,
    required String url,
  }) {
    return TextButton(
      key: Key(keyValue),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: () {
        launchUrl(Uri.parse(url));
      },
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  return <Widget>[
    buildButton(
      keyValue: 'statistics-map-attribution-protomaps',
      label: _statisticsMapAttributionProtomapsLabel,
      url: _statisticsMapAttributionProtomapsUrl,
    ),
    buildButton(
      keyValue: 'statistics-map-attribution-openstreetmap',
      label: _statisticsMapAttributionOpenStreetMapLabel,
      url: _statisticsMapAttributionOpenStreetMapUrl,
    ),
  ];
}

class _StatisticsMapFallbackSurface extends StatelessWidget {
  const _StatisticsMapFallbackSurface({
    required this.markers,
    required this.colors,
  });

  final List<_StatisticsMapMarkerData> markers;
  final Map<DrinkCategory, Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final offsets = markers
            .map(
              (marker) => _statisticsMapFallbackOffsetForMarker(
                marker: marker,
                markers: markers,
                size: size,
              ),
            )
            .toList(growable: false);

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                theme.colorScheme.surfaceContainerHigh,
                theme.colorScheme.surface,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _StatisticsMapFallbackPainter(theme: theme),
                ),
              ),
              ..._statisticsMapMarkerWidgets(
                markers: markers,
                markerIndexes: List<int>.generate(
                  markers.length,
                  (index) => index,
                ),
                offsets: offsets,
                colors: colors,
                onMarkerTap: (index, marker) async {
                  final backgroundColor = colors[marker.entry.category]!;
                  await _showStatisticsMapEntrySheet(
                    context,
                    marker,
                    backgroundColor,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatisticsMapFallbackPainter extends CustomPainter {
  const _StatisticsMapFallbackPainter({required this.theme});

  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = theme.colorScheme.outlineVariant.withValues(alpha: 0.32)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final accentPaint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final verticalStep = math.max(size.width / 4, 90);
    for (
      var x = -verticalStep;
      x <= size.width + verticalStep;
      x += verticalStep
    ) {
      final path = Path()
        ..moveTo(x.toDouble(), 0)
        ..quadraticBezierTo(
          (x + 24).toDouble(),
          size.height * 0.45,
          (x - 12).toDouble(),
          size.height,
        );
      canvas.drawPath(path, roadPaint);
    }

    final horizontalStep = math.max(size.height / 5, 84);
    for (var y = horizontalStep; y <= size.height; y += horizontalStep) {
      final path = Path()
        ..moveTo(0, y.toDouble())
        ..quadraticBezierTo(
          size.width * 0.45,
          (y - 20).toDouble(),
          size.width,
          (y + 12).toDouble(),
        );
      canvas.drawPath(path, roadPaint);
    }

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.24),
      math.min(size.width, size.height) * 0.1,
      accentPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.68),
      math.min(size.width, size.height) * 0.13,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StatisticsMapFallbackPainter oldDelegate) {
    return oldDelegate.theme.colorScheme != theme.colorScheme;
  }
}

class _StatisticsMapAttributionCard extends StatelessWidget {
  const _StatisticsMapAttributionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      key: const Key('statistics-map-attribution'),
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: Wrap(children: children),
    );
  }
}

class _StatisticsMapClusterMarker extends StatelessWidget {
  const _StatisticsMapClusterMarker({
    required this.markerIds,
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String markerIds;
  final int count;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('statistics-map-cluster-$markerIds'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _statisticsMapMarkerVisualSize,
          height: _statisticsMapMarkerVisualSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                '$count',
                key: Key('statistics-map-cluster-count-$markerIds'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsMapMarker extends StatelessWidget {
  const _StatisticsMapMarker({
    required this.entry,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final DrinkEntry entry;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('statistics-map-marker-${entry.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: _statisticsMapMarkerVisualSize + 10,
          height: _statisticsMapMarkerVisualSize + 16,
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Icon(
                Icons.location_on_rounded,
                size: _statisticsMapMarkerVisualSize + 8,
                color: backgroundColor,
              ),
              Positioned(
                top: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 18, height: 18),
                ),
              ),
              Positioned(
                top: 12,
                child: Icon(
                  entry.category.icon,
                  key: Key('statistics-map-marker-icon-${entry.id}'),
                  color: foregroundColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsMapEntrySheet extends StatelessWidget {
  const _StatisticsMapEntrySheet({
    required this.entry,
    required this.accentColor,
  });

  final DrinkEntry entry;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final drinkName = controller.localizedEntryDrinkName(
      entry,
      localeCode: localeCode,
    );
    final categoryLabel = <String>[
      l10n.categoryLabel(entry.category),
      if (entry.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
    ].join(' • ');
    final timeLabel = DateFormat.yMMMd(
      localeCode,
    ).add_Hm().format(entry.consumedAt);
    final volumeLabel = entry.volumeMl == null
        ? null
        : unit.formatVolume(entry.volumeMl);
    final locationAddress = _normalizedStatisticsText(entry.locationAddress);
    final comment = _normalizedStatisticsText(entry.comment);
    final imagePath = _normalizedStatisticsText(entry.imagePath);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          key: Key('statistics-map-sheet-${entry.id}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accentColor.withValues(alpha: 0.16),
                  foregroundColor: accentColor,
                  child: Icon(entry.category.icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        drinkName,
                        key: Key('statistics-map-sheet-name-${entry.id}'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryLabel,
                        key: Key('statistics-map-sheet-category-${entry.id}'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeLabel,
                        key: Key('statistics-map-sheet-time-${entry.id}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (volumeLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      volumeLabel,
                      key: Key('statistics-map-sheet-volume-${entry.id}'),
                    ),
                  ),
              ],
            ),
            if (locationAddress != null) ...<Widget>[
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationAddress,
                      key: Key('statistics-map-sheet-location-${entry.id}'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            if (comment != null) ...<Widget>[
              const SizedBox(height: 18),
              Text(
                l10n.comment,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                comment,
                key: Key('statistics-map-sheet-comment-${entry.id}'),
              ),
            ],
            if (imagePath != null) ...<Widget>[
              const SizedBox(height: 18),
              AppPhotoPreview(
                key: Key('statistics-map-sheet-image-${entry.id}'),
                imagePath: imagePath,
                cropPortraitToSquare: true,
                enableFullscreenOnTap: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
