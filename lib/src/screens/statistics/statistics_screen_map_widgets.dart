part of '../statistics_screen.dart';

Color _statisticsMapMarkerForegroundColor(Color backgroundColor) {
  final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

Future<void> _showStatisticsMapEntrySheet(
  BuildContext context,
  _StatisticsMapMarkerData marker,
  Color accentColor,
) async {
  await showAdaptiveSheetOrDialog<void>(
    context: context,
    showDragHandle: true,
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
      keyValue: 'statistics-map-attribution-carto',
      label: _statisticsMapAttributionCartoLabel,
      url: _statisticsMapAttributionCartoUrl,
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
    required this.onMarkerTap,
    this.onBackgroundTap,
  });

  final List<_StatisticsMapMarkerData> markers;
  final Map<DrinkCategory, Color> colors;
  final Future<void> Function(_StatisticsMapMarkerData marker) onMarkerTap;
  final VoidCallback? onBackgroundTap;

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

        return GestureDetector(
          onTap: onBackgroundTap,
          child: DecoratedBox(
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
                  onMarkerTap: (index, marker) => onMarkerTap(marker),
                ),
              ],
            ),
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
    final content = DrinkEntryDetailContent(
      entry: entry,
      accentColor: accentColor,
    );

    if (AppBreakpoints.isExpanded(context)) {
      // Dialog presentation: no drag handle exists here, so provide a
      // close button and breathing room at the top instead.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  key: const Key('statistics-map-dialog-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: content,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SingleChildScrollView(child: content),
    );
  }
}
