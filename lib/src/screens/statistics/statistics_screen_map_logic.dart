part of '../statistics_screen.dart';

const String _statisticsMapCartoLightStyleUrl =
    'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
const String _statisticsMapCartoDarkStyleUrl =
    'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';
const String _statisticsMapAttributionOpenStreetMapLabel = '© OpenStreetMap';
const String _statisticsMapAttributionOpenStreetMapUrl =
    'https://www.openstreetmap.org/copyright';
const String _statisticsMapAttributionCartoLabel = '© CARTO';
const String _statisticsMapAttributionCartoUrl =
    'https://carto.com/attributions';
const String _statisticsMapClusteredSourceId =
    'statistics-map-clustered-source';
const String _statisticsMapDetailSourceId = 'statistics-map-detail-source';
const String _statisticsMapClusterCircleLayerId =
    'statistics-map-cluster-circle-layer';
const String _statisticsMapClusterCountLayerId =
    'statistics-map-cluster-count-layer';
const String _statisticsMapLowZoomMarkerLayerId =
    'statistics-map-low-zoom-marker-layer';
const String _statisticsMapDetailMarkerLayerId =
    'statistics-map-detail-marker-layer';
const String _statisticsMapLowZoomMarkerHoverLayerId =
    'statistics-map-low-zoom-marker-hover-layer';
const String _statisticsMapDetailMarkerHoverLayerId =
    'statistics-map-detail-marker-hover-layer';
const String _statisticsMapLowZoomMarkerHitLayerId =
    'statistics-map-low-zoom-marker-hit-layer';
const String _statisticsMapDetailMarkerHitLayerId =
    'statistics-map-detail-marker-hit-layer';
// Small enough that fanned-out markers still read as "the same place" at
// street level, but large enough that two pins never fully overlap and
// become untappable.
const String _statisticsMapSelfLocationSourceId =
    'statistics-map-self-location-source';
const String _statisticsMapSelfLocationLayerId =
    'statistics-map-self-location-layer';
const double _statisticsMapFanOutDistanceMeters = 9;
const double _statisticsMapClusterRadius = 52;
// Below this zoom MapLibre's built-in clustering takes over; above it we
// switch to the (unclustered) detail source so individual entries at the
// same real-world spot can still be told apart and tapped.
const double _statisticsMapClusterMaxZoom = 12;
const double _statisticsMapDetailMarkerMinZoom = 12;
const double _statisticsMapSingleMarkerZoom = 15.5;
const double _statisticsMapTapResolveZoomStep = 2;
const double _statisticsMapTapResolveMaxZoom = 18.5;
// Screen-space radius (in logical pixels) used to decide whether a tap
// landed on more than one marker at once; smaller than the hit target so
// near-misses still resolve to a single marker.
const double _statisticsMapMarkerOverlapRadius = 28;
const double _statisticsMapLonelyMarkerRadius = 52;
const double _statisticsMapBoundsPadding = 48;
// Hit target is larger than the visible pin so touch input stays reliable
// on small screens without making the marker itself look oversized.
const double _statisticsMapMarkerHitSize = 56;
const double _statisticsMapMarkerVisualSize = 44;
const double _statisticsMapFallbackPadding = 56;
// Nudges the cluster count label up slightly so it sits visually centered
// inside the circle marker instead of the glyph's natural baseline center.
const double _statisticsMapClusterCountTextOffsetY = -0.08;
const double _statisticsMapNativeMarkerSpriteSize =
    _statisticsMapMarkerVisualSize + 8;
const double _statisticsMapNativeMarkerInnerCircleSize = 18;
const double _statisticsMapNativeMarkerInnerIconSize = 18;
const double _statisticsMapMarkerHoverIconScale = 1.1;
const latlong2.Distance _statisticsMapDistance = latlong2.Distance();

final Set<Factory<OneSequenceGestureRecognizer>>
_statisticsMapGestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
  Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
};

@visibleForTesting
String statisticsMapStyleUrl(Brightness brightness) =>
    brightness == Brightness.dark
    ? _statisticsMapCartoDarkStyleUrl
    : _statisticsMapCartoLightStyleUrl;

enum StatisticsMapTapResolution { openSheet, zoomIn }

class _StatisticsMapMarkerData {
  const _StatisticsMapMarkerData({required this.entry, required this.position});

  final DrinkEntry entry;
  final maplibre.LatLng position;

  String get signature =>
      '${entry.id}:${position.latitude.toStringAsFixed(6)},'
      '${position.longitude.toStringAsFixed(6)}';
}

class _StatisticsMapCoordinateGroup {
  const _StatisticsMapCoordinateGroup({
    required this.center,
    required this.entries,
  });

  final maplibre.LatLng center;
  final List<DrinkEntry> entries;
}

// Defends against malformed/legacy stored coordinates (e.g. from a bad
// import or manual DB edit) that would otherwise crash MapLibre or place a
// marker off the map entirely.
bool _statisticsEntryHasCoordinates(DrinkEntry entry) {
  final latitude = entry.locationLatitude;
  final longitude = entry.locationLongitude;
  if (latitude == null || longitude == null) {
    return false;
  }
  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

// Rounding to ~11m precision groups entries that are effectively "the same
// venue" despite tiny GPS jitter between visits, so they get fanned out as
// one cluster instead of showing as separate overlapping pins.
double _roundStatisticsCoordinate(double value) {
  return double.parse(value.toStringAsFixed(4));
}

String _statisticsMapCoordinateGroupKey(double latitude, double longitude) {
  return '${_roundStatisticsCoordinate(latitude).toStringAsFixed(4)}|'
      '${_roundStatisticsCoordinate(longitude).toStringAsFixed(4)}';
}

// Feeds the clustered GeoJSON source: keeps exact (unrounded, un-fanned-out)
// coordinates so MapLibre's own clustering groups markers purely by real
// screen-space proximity at the current zoom.
List<_StatisticsMapMarkerData> _statisticsMapRawMarkersForEntries(
  List<DrinkEntry> entries,
) {
  return entries
      .where(_statisticsEntryHasCoordinates)
      .map(
        (entry) => _StatisticsMapMarkerData(
          entry: entry,
          position: maplibre.LatLng(
            entry.locationLatitude!,
            entry.locationLongitude!,
          ),
        ),
      )
      .toList(growable: false);
}

// Feeds the detail source (used once zoomed past the clustering threshold):
// entries sharing the same rounded coordinate are spread out in a small
// circle so multiple visits to one venue each get their own tappable pin
// instead of stacking into a single indistinguishable marker.
List<_StatisticsMapMarkerData> _statisticsMapMarkersForEntries(
  List<DrinkEntry> entries,
) {
  final groupedEntries = <String, _StatisticsMapCoordinateGroup>{};

  for (final entry in entries) {
    if (!_statisticsEntryHasCoordinates(entry)) {
      continue;
    }

    final latitude = entry.locationLatitude!;
    final longitude = entry.locationLongitude!;
    final roundedLatitude = _roundStatisticsCoordinate(latitude);
    final roundedLongitude = _roundStatisticsCoordinate(longitude);
    final groupKey = _statisticsMapCoordinateGroupKey(latitude, longitude);
    final group = groupedEntries[groupKey];

    if (group == null) {
      groupedEntries[groupKey] = _StatisticsMapCoordinateGroup(
        center: maplibre.LatLng(roundedLatitude, roundedLongitude),
        entries: <DrinkEntry>[entry],
      );
      continue;
    }

    group.entries.add(entry);
  }

  final markers = <_StatisticsMapMarkerData>[];
  for (final group in groupedEntries.values) {
    if (group.entries.length == 1) {
      final entry = group.entries.single;
      markers.add(
        _StatisticsMapMarkerData(
          entry: entry,
          position: maplibre.LatLng(
            entry.locationLatitude!,
            entry.locationLongitude!,
          ),
        ),
      );
      continue;
    }

    // Distribute entries evenly around the shared center rather than
    // stacking them, so every marker in the group is separately visible
    // and tappable.
    final bearingStep = 360 / group.entries.length;
    for (var index = 0; index < group.entries.length; index++) {
      markers.add(
        _StatisticsMapMarkerData(
          entry: group.entries[index],
          position: _statisticsMapLatLngFromOffset(
            _statisticsMapDistance.offset(
              latlong2.LatLng(group.center.latitude, group.center.longitude),
              _statisticsMapFanOutDistanceMeters,
              bearingStep * index,
            ),
          ),
        ),
      );
    }
  }

  return markers;
}

maplibre.LatLng _statisticsMapLatLngFromOffset(latlong2.LatLng position) {
  return maplibre.LatLng(position.latitude, position.longitude);
}

@visibleForTesting
List<DrinkEntry> statisticsMapEntriesForFilters({
  required List<DrinkEntry> entries,
  required bool photoOnly,
}) {
  if (!photoOnly) {
    return entries;
  }
  return entries.where(_statisticsGalleryHasImage).toList(growable: false);
}

@visibleForTesting
List<int> statisticsMapOverlappingMarkerIndexes({
  required List<Offset> offsets,
  required int tappedIndex,
  double overlapRadius = _statisticsMapMarkerOverlapRadius,
}) {
  if (tappedIndex < 0 || tappedIndex >= offsets.length) {
    return const <int>[];
  }

  final tappedOffset = offsets[tappedIndex];
  return List<int>.generate(offsets.length, (index) => index)
      .where(
        (index) => (offsets[index] - tappedOffset).distance <= overlapRadius,
      )
      .toList(growable: false);
}

@visibleForTesting
StatisticsMapTapResolution resolveStatisticsMapMarkerTap({
  required List<Offset> offsets,
  required int tappedIndex,
  required double currentZoom,
  double overlapRadius = _statisticsMapMarkerOverlapRadius,
  double zoomResolutionMaxZoom = _statisticsMapTapResolveMaxZoom,
}) {
  final overlappingIndexes = statisticsMapOverlappingMarkerIndexes(
    offsets: offsets,
    tappedIndex: tappedIndex,
    overlapRadius: overlapRadius,
  );
  // If several fanned-out markers still overlap on screen and we haven't
  // hit the max useful zoom yet, zoom in instead of guessing which entry
  // the user meant to tap — once zoomed further the fan-out spreads them
  // apart enough for a precise tap.
  if (overlappingIndexes.length > 1 && currentZoom < zoomResolutionMaxZoom) {
    return StatisticsMapTapResolution.zoomIn;
  }
  return StatisticsMapTapResolution.openSheet;
}

/// Resolves the marker indexes belonging to a tapped cluster by screen-space
/// proximity, since maplibre_gl 0.26.1 exposes no cluster-leaves API.
///
/// Collects markers within [baseRadius] of [clusterOffset] and widens the
/// search (x1.5, x2, capped at x2.5) until [expectedCount] markers are found.
/// When more markers match than expected, only the nearest [expectedCount]
/// are kept. Returns fewer indexes when the cap is reached without a full
/// match — callers should fall back to zooming in that case.
@visibleForTesting
List<int> statisticsMapClusterLeafIndexes({
  required List<Offset> offsets,
  required Offset clusterOffset,
  required int expectedCount,
  double baseRadius = _statisticsMapClusterRadius,
}) {
  if (offsets.isEmpty || expectedCount <= 0) {
    return const <int>[];
  }

  final distances = offsets
      .map((offset) => (offset - clusterOffset).distance)
      .toList(growable: false);

  List<int> withinRadius(double radius) {
    return List<int>.generate(
      offsets.length,
      (index) => index,
    ).where((index) => distances[index] <= radius).toList(growable: false);
  }

  var matches = const <int>[];
  for (final radiusFactor in const <double>[1, 1.5, 2, 2.5]) {
    matches = withinRadius(baseRadius * radiusFactor);
    if (matches.length >= expectedCount) {
      break;
    }
  }

  if (matches.length > expectedCount) {
    final sorted = matches.toList()
      ..sort((a, b) => distances[a].compareTo(distances[b]));
    matches = sorted.sublist(0, expectedCount)..sort();
  }

  return matches;
}

// Used by the non-MapLibre fallback surface, which has no native clustering
// engine: groups markers by transitive screen-space proximity (flood fill)
// so nearby pins can be treated as one cluster there too.
@visibleForTesting
List<List<int>> statisticsMapClusterGroups({
  required List<Offset> offsets,
  double clusterRadius = _statisticsMapLonelyMarkerRadius,
}) {
  final visited = List<bool>.filled(offsets.length, false);
  final groups = <List<int>>[];

  for (var index = 0; index < offsets.length; index++) {
    if (visited[index]) {
      continue;
    }

    final pending = <int>[index];
    final group = <int>[];
    visited[index] = true;

    while (pending.isNotEmpty) {
      final currentIndex = pending.removeLast();
      group.add(currentIndex);
      final current = offsets[currentIndex];

      for (var otherIndex = 0; otherIndex < offsets.length; otherIndex++) {
        if (visited[otherIndex]) {
          continue;
        }
        if ((offsets[otherIndex] - current).distance <= clusterRadius) {
          visited[otherIndex] = true;
          pending.add(otherIndex);
        }
      }
    }

    group.sort();
    groups.add(group);
  }

  return groups;
}

@visibleForTesting
List<int> statisticsMapStandaloneMarkerIndexes({
  required List<Offset> offsets,
  double isolationRadius = _statisticsMapLonelyMarkerRadius,
}) {
  return statisticsMapClusterGroups(
        offsets: offsets,
        clusterRadius: isolationRadius,
      )
      .where((group) => group.length == 1)
      .map((group) => group.single)
      .toList(growable: false);
}

// Bounds are meaningless (and MapLibre rejects a zero-size bounding box) for
// zero or one marker; callers handle those cases separately by centering
// the camera on the single marker instead.
maplibre.LatLngBounds? _statisticsMapBounds(
  List<_StatisticsMapMarkerData> markers,
) {
  if (markers.length < 2) {
    return null;
  }

  var south = markers.first.position.latitude;
  var north = markers.first.position.latitude;
  var west = markers.first.position.longitude;
  var east = markers.first.position.longitude;

  for (final marker in markers.skip(1)) {
    south = math.min(south, marker.position.latitude);
    north = math.max(north, marker.position.latitude);
    west = math.min(west, marker.position.longitude);
    east = math.max(east, marker.position.longitude);
  }

  return maplibre.LatLngBounds(
    southwest: maplibre.LatLng(south, west),
    northeast: maplibre.LatLng(north, east),
  );
}

// Used as part of a widget ValueKey so the MapLibreMap widget (and its
// underlying platform view) is recreated whenever the marker set actually
// changes, rather than trying to diff/patch an existing native map instance.
String _statisticsMapSignature(List<_StatisticsMapMarkerData> markers) {
  return markers.map((marker) => marker.signature).join('|');
}

// FNV-1a hash: not for security, just a short, deterministic-across-runs
// fingerprint for building stable MapLibre sprite image ids (Dart's built-in
// hashCode is explicitly not guaranteed stable between runs/isolates).
String _statisticsMapStableHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

// Captures everything that affects how a marker sprite is drawn (theme
// colors, icon, scale). Comparing/hashing this lets us detect when sprites
// must be regenerated and re-uploaded to MapLibre — e.g. after a light/dark
// theme change — instead of reusing stale cached images.
String _statisticsMapMarkerAssetSignature(
  Map<DrinkCategory, Color> colors, {
  double spriteScale = 1,
}) {
  return DrinkCategory.values
      .map((category) {
        final backgroundColor = colors[category]!;
        final foregroundColor = _statisticsMapMarkerForegroundColor(
          backgroundColor,
        );
        return <Object>[
          category.storageValue,
          category.icon.codePoint,
          _statisticsMapHexColor(backgroundColor),
          _statisticsMapHexColor(foregroundColor),
          spriteScale.toStringAsFixed(2),
        ].join(':');
      })
      .join('|');
}

// The signature hash is baked into the sprite id itself so that when the
// asset signature changes, features referencing the old id keep rendering
// the old (still-valid) image until the style is reconfigured, and MapLibre
// never conflates two visually different sprites under one id.
String _statisticsMapMarkerSpriteId(
  DrinkCategory category,
  String markerAssetSignature,
) {
  final assetHash = _statisticsMapStableHash(markerAssetSignature);
  return 'statistics-map-marker-${category.storageValue}-$assetHash';
}

Map<String, Object> _statisticsMapFeatureForMarker({
  required _StatisticsMapMarkerData marker,
  required String markerAssetSignature,
}) {
  final entry = marker.entry;
  return <String, Object>{
    'type': 'Feature',
    'id': entry.id,
    'properties': <String, Object>{
      'entryId': entry.id,
      'category': entry.category.storageValue,
      'markerImageId': _statisticsMapMarkerSpriteId(
        entry.category,
        markerAssetSignature,
      ),
    },
    'geometry': <String, Object>{
      'type': 'Point',
      'coordinates': <double>[
        marker.position.longitude,
        marker.position.latitude,
      ],
    },
  };
}

Map<String, Object> _statisticsMapSourceGeoJson(
  List<_StatisticsMapMarkerData> markers, {
  required String markerAssetSignature,
}) {
  return <String, Object>{
    'type': 'FeatureCollection',
    'features': markers
        .map(
          (marker) => _statisticsMapFeatureForMarker(
            marker: marker,
            markerAssetSignature: markerAssetSignature,
          ),
        )
        .toList(growable: false),
  };
}

@visibleForTesting
Map<String, Object> statisticsMapClusteredSourceGeoJsonForEntries({
  required List<DrinkEntry> entries,
  required String markerAssetSignature,
}) {
  return _statisticsMapSourceGeoJson(
    _statisticsMapRawMarkersForEntries(entries),
    markerAssetSignature: markerAssetSignature,
  );
}

@visibleForTesting
Map<String, Object> statisticsMapDetailSourceGeoJsonForEntries({
  required List<DrinkEntry> entries,
  required String markerAssetSignature,
}) {
  return _statisticsMapSourceGeoJson(
    _statisticsMapMarkersForEntries(entries),
    markerAssetSignature: markerAssetSignature,
  );
}

Map<String, Object> _statisticsMapEmptyGeoJson() {
  return const <String, Object>{
    'type': 'FeatureCollection',
    'features': <Object>[],
  };
}

@visibleForTesting
Map<String, Object> statisticsMapSelfLocationGeoJson(maplibre.LatLng position) {
  return <String, Object>{
    'type': 'FeatureCollection',
    'features': <Object>[
      <String, Object>{
        'type': 'Feature',
        'geometry': <String, Object>{
          'type': 'Point',
          'coordinates': <double>[position.longitude, position.latitude],
        },
        'properties': const <String, Object>{},
      },
    ],
  };
}

// MapLibre style layer properties are JSON/JS style expressions, not Flutter
// Color objects, so colors have to be serialized as CSS hex strings.
String _statisticsMapHexColor(Color color) {
  String component(int value) => value.toRadixString(16).padLeft(2, '0');
  int channel(double value) => (value * 255).round().clamp(0, 255);
  return '#${component(channel(color.r))}'
      '${component(channel(color.g))}'
      '${component(channel(color.b))}';
}

maplibre.SymbolLayerProperties _statisticsMapMarkerLayerProperties({
  required double iconSize,
}) {
  return maplibre.SymbolLayerProperties(
    iconImage: <Object>['get', 'markerImageId'],
    iconSize: iconSize,
    iconAnchor: 'bottom',
    iconAllowOverlap: true,
    iconIgnorePlacement: true,
  );
}

// A fully transparent circle layer, larger than the visible pin icon, drawn
// purely so taps/hover have a generous, reliable hit target — the icon
// glyph itself is too small/irregularly shaped to hit-test well on touch.
maplibre.CircleLayerProperties _statisticsMapMarkerHitLayerProperties() {
  return const maplibre.CircleLayerProperties(
    circleRadius: _statisticsMapMarkerHitSize / 2,
    circleColor: 'rgba(0, 0, 0, 0)',
    circleOpacity: 1.0,
    circleStrokeWidth: 0,
  );
}

maplibre.SymbolLayerProperties _statisticsMapMarkerHoverLayerProperties({
  required double iconSize,
}) {
  return maplibre.SymbolLayerProperties(
    iconImage: const <Object>['get', 'markerImageId'],
    iconSize: iconSize * _statisticsMapMarkerHoverIconScale,
    iconAnchor: 'bottom',
    iconAllowOverlap: true,
    iconIgnorePlacement: true,
  );
}

// MapLibre filters need a concrete value to compare against; when nothing is
// hovered we compare 'entryId' against a sentinel that can never match a
// real entry id, which effectively hides the hover layer without needing a
// separate "layer visible" toggle.
Object _statisticsMapEntryIdFilter(String? entryId) {
  return <Object>[
    '==',
    const <Object>['get', 'entryId'],
    entryId ?? '__statistics_map_no_hover__',
  ];
}

maplibre.SymbolLayerProperties _statisticsMapClusterCountLayerProperties({
  required Color labelColor,
}) {
  return maplibre.SymbolLayerProperties(
    textField: '{point_count}',
    textFont: const <String>['Open Sans Bold', 'Arial Unicode MS Bold'],
    textSize: 16,
    textColor: _statisticsMapHexColor(labelColor),
    textHaloWidth: 0.0,
    textAnchor: 'center',
    textJustify: 'center',
    textOffset: const <double>[0, _statisticsMapClusterCountTextOffsetY],
    textAllowOverlap: true,
    textIgnorePlacement: true,
  );
}

@visibleForTesting
maplibre.SymbolLayerProperties statisticsMapClusterCountLayerProperties({
  required Color labelColor,
}) {
  return _statisticsMapClusterCountLayerProperties(labelColor: labelColor);
}

Future<void> _configureStatisticsMapMarkerImages(
  maplibre.MapLibreMapController controller, {
  required Map<DrinkCategory, Color> colors,
  required String markerAssetSignature,
  double spriteScale = 1,
}) async {
  final sprites = await Future.wait(
    DrinkCategory.values.map((category) async {
      final backgroundColor = colors[category]!;
      return MapEntry(
        category,
        await _statisticsMapMarkerSpriteBytes(
          category: category,
          backgroundColor: backgroundColor,
          spriteScale: spriteScale,
        ),
      );
    }),
  );

  for (final sprite in sprites) {
    await controller.addImage(
      _statisticsMapMarkerSpriteId(sprite.key, markerAssetSignature),
      sprite.value,
    );
  }
}

// MapLibre's symbol layers need raster images, not Flutter widgets, so the
// pin (with its category icon punched into the center) is rasterized once
// per category/theme via Canvas and uploaded as a sprite rather than drawn
// as an overlay widget per marker (which wouldn't scale to many entries).
Future<Uint8List> _statisticsMapMarkerSpriteBytes({
  required DrinkCategory category,
  required Color backgroundColor,
  double spriteScale = 1,
}) async {
  const size = _statisticsMapNativeMarkerSpriteSize;
  const innerCircleRadius = _statisticsMapNativeMarkerInnerCircleSize / 2;
  const innerCircleTop = 6.0;
  const innerIconTop = 12.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (spriteScale != 1) {
    canvas.scale(spriteScale, spriteScale);
  }
  final foregroundColor = _statisticsMapMarkerForegroundColor(backgroundColor);

  _statisticsMapPaintIconGlyph(
    canvas,
    icon: Icons.location_on_rounded,
    color: backgroundColor,
    size: size,
    top: 0,
    width: size,
  );

  canvas.drawCircle(
    const Offset(size / 2, innerCircleTop + innerCircleRadius),
    innerCircleRadius,
    Paint()..color = backgroundColor,
  );

  _statisticsMapPaintIconGlyph(
    canvas,
    icon: category.icon,
    color: foregroundColor,
    size: _statisticsMapNativeMarkerInnerIconSize,
    top: innerIconTop,
    width: size,
  );

  final image = await recorder.endRecording().toImage(
    (size * spriteScale).ceil(),
    (size * spriteScale).ceil(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode statistics map marker sprite.');
  }
  return byteData.buffer.asUint8List();
}

void _statisticsMapPaintIconGlyph(
  Canvas canvas, {
  required IconData icon,
  required Color color,
  required double size,
  required double top,
  required double width,
}) {
  final painter = TextPainter(
    textDirection: ui.TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: color,
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        height: 1,
      ),
    ),
  )..layout();

  painter.paint(canvas, Offset((width - painter.width) / 2, top));
}

maplibre.CameraPosition _statisticsMapInitialCameraPosition(
  List<_StatisticsMapMarkerData> markers,
) {
  if (markers.length == 1) {
    return maplibre.CameraPosition(
      target: markers.single.position,
      zoom: _statisticsMapSingleMarkerZoom,
    );
  }

  // A coarse, cheap-to-compute starting point (world-ish zoom centered on
  // the bounds midpoint) so the map has something reasonable to render
  // immediately; _fitStatisticsMapCamera later animates to a tight fit
  // once the style has actually loaded.
  final bounds = _statisticsMapBounds(markers)!;
  return maplibre.CameraPosition(
    target: maplibre.LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    ),
    zoom: 4,
  );
}

Future<void> _fitStatisticsMapCamera(
  maplibre.MapLibreMapController controller,
  List<_StatisticsMapMarkerData> markers,
) async {
  if (markers.length == 1) {
    await controller.moveCamera(
      maplibre.CameraUpdate.newLatLngZoom(
        markers.single.position,
        _statisticsMapSingleMarkerZoom,
      ),
    );
    return;
  }

  final bounds = _statisticsMapBounds(markers);
  if (bounds == null) {
    return;
  }

  await controller.moveCamera(
    maplibre.CameraUpdate.newLatLngBounds(
      bounds,
      left: _statisticsMapBoundsPadding,
      top: _statisticsMapBoundsPadding,
      right: _statisticsMapBoundsPadding,
      bottom: _statisticsMapBoundsPadding,
    ),
  );
}

// Used when MapLibre isn't available on the platform (see
// runtime_platform.isMapLibrePlatformSupported): projects markers onto the
// fallback surface by simple linear normalization within their own bounds
// rather than a real map projection, since there's no actual basemap to
// align coordinates against — only relative positions matter here.
Offset _statisticsMapFallbackOffsetForMarker({
  required _StatisticsMapMarkerData marker,
  required List<_StatisticsMapMarkerData> markers,
  required Size size,
}) {
  if (markers.length == 1) {
    return Offset(size.width / 2, size.height / 2);
  }

  final bounds = _statisticsMapBounds(markers)!;
  final availableWidth = math.max(
    size.width - (_statisticsMapFallbackPadding * 2),
    _statisticsMapMarkerHitSize,
  );
  final availableHeight = math.max(
    size.height - (_statisticsMapFallbackPadding * 2),
    _statisticsMapMarkerHitSize,
  );
  // Floor the span so a group of markers that share (almost) the same
  // longitude/latitude doesn't divide by ~zero and blow up the normalized
  // position.
  final longitudeSpan = math.max(
    bounds.northeast.longitude - bounds.southwest.longitude,
    0.0001,
  );
  final latitudeSpan = math.max(
    bounds.northeast.latitude - bounds.southwest.latitude,
    0.0001,
  );
  final normalizedX =
      (marker.position.longitude - bounds.southwest.longitude) / longitudeSpan;
  // Latitude increases northward but screen Y increases downward, so the
  // vertical axis has to be flipped relative to the horizontal one.
  final normalizedY =
      (bounds.northeast.latitude - marker.position.latitude) / latitudeSpan;

  return Offset(
    _statisticsMapFallbackPadding + (availableWidth * normalizedX),
    _statisticsMapFallbackPadding + (availableHeight * normalizedY),
  );
}
