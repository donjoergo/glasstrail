part of '../statistics_screen.dart';

const String _statisticsMapProtomapsBasemapsVersion = '5.7.2';
const String _statisticsMapProtomapsTilesBuild = '20260325';
const String _statisticsMapCartoLightStyleUrl =
    'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
const String _statisticsMapCartoDarkStyleUrl =
    'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';
const String _statisticsMapAttributionOpenStreetMapLabel = '© OpenStreetMap';
const String _statisticsMapAttributionOpenStreetMapUrl =
    'https://www.openstreetmap.org/copyright';
const String _statisticsMapAttributionProtomapsLabel = '© Protomaps';
const String _statisticsMapAttributionProtomapsUrl = 'https://protomaps.com';
const String _statisticsMapClusterSourceId = 'statistics-map-cluster-source';
const String _statisticsMapClusterCircleLayerId =
    'statistics-map-cluster-circle-layer';
const String _statisticsMapClusterCountLayerId =
    'statistics-map-cluster-count-layer';
const double _statisticsMapFanOutDistanceMeters = 9;
const double _statisticsMapClusterRadius = 52;
const double _statisticsMapClusterMaxZoom = 12;
const double _statisticsMapDetailMarkerMinZoom = 12;
const double _statisticsMapSingleMarkerZoom = 15.5;
const double _statisticsMapTapResolveZoomStep = 2;
const double _statisticsMapTapResolveMaxZoom = 18.5;
const double _statisticsMapMarkerOverlapRadius = 28;
const double _statisticsMapLonelyMarkerRadius = 52;
const double _statisticsMapBoundsPadding = 48;
const double _statisticsMapMarkerHitSize = 56;
const double _statisticsMapMarkerVisualSize = 44;
const double _statisticsMapFallbackPadding = 56;
const latlong2.Distance _statisticsMapDistance = latlong2.Distance();

final Set<Factory<OneSequenceGestureRecognizer>>
_statisticsMapGestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
  Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
};

String _statisticsMapStyleString({
  required Brightness brightness,
  required String localeCode,
}) {
  if (kIsWeb) {
    return brightness == Brightness.dark
        ? _statisticsMapCartoDarkStyleUrl
        : _statisticsMapCartoLightStyleUrl;
  }

  final theme = brightness == Brightness.dark ? 'dark' : 'light';
  return 'https://npm-style.protomaps.dev/style.json'
      '?version=$_statisticsMapProtomapsBasemapsVersion'
      '&theme=$theme'
      '&tiles=$_statisticsMapProtomapsTilesBuild'
      '&lang=$localeCode';
}

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

class _StatisticsMapScreenCluster {
  const _StatisticsMapScreenCluster({
    required this.markerIndexes,
    required this.center,
  });

  final List<int> markerIndexes;
  final Offset center;
}

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

double _roundStatisticsCoordinate(double value) {
  return double.parse(value.toStringAsFixed(4));
}

String _statisticsMapCoordinateGroupKey(double latitude, double longitude) {
  return '${_roundStatisticsCoordinate(latitude).toStringAsFixed(4)}|'
      '${_roundStatisticsCoordinate(longitude).toStringAsFixed(4)}';
}

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

bool _statisticsMapShowsIndividualMarkers(double zoom) {
  return zoom >= _statisticsMapDetailMarkerMinZoom;
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
  if (overlappingIndexes.length > 1 && currentZoom < zoomResolutionMaxZoom) {
    return StatisticsMapTapResolution.zoomIn;
  }
  return StatisticsMapTapResolution.openSheet;
}

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

List<_StatisticsMapScreenCluster> _statisticsMapScreenClusters({
  required List<Offset> offsets,
  double clusterRadius = _statisticsMapLonelyMarkerRadius,
}) {
  return statisticsMapClusterGroups(
        offsets: offsets,
        clusterRadius: clusterRadius,
      )
      .map((group) {
        final averageDx =
            group.fold<double>(0, (sum, index) => sum + offsets[index].dx) /
            group.length;
        final averageDy =
            group.fold<double>(0, (sum, index) => sum + offsets[index].dy) /
            group.length;
        return _StatisticsMapScreenCluster(
          markerIndexes: group,
          center: Offset(averageDx, averageDy),
        );
      })
      .toList(growable: false);
}

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

String _statisticsMapSignature(List<_StatisticsMapMarkerData> markers) {
  return markers.map((marker) => marker.signature).join('|');
}

Object _statisticsMapClusterGeoJson(List<_StatisticsMapMarkerData> markers) {
  return <String, Object>{
    'type': 'FeatureCollection',
    'features': markers
        .map((marker) {
          final entry = marker.entry;
          return <String, Object>{
            'type': 'Feature',
            'id': entry.id,
            'properties': <String, Object>{'entryId': entry.id},
            'geometry': <String, Object>{
              'type': 'Point',
              'coordinates': <double>[
                entry.locationLongitude!,
                entry.locationLatitude!,
              ],
            },
          };
        })
        .toList(growable: false),
  };
}

String _statisticsMapHexColor(Color color) {
  String component(int value) => value.toRadixString(16).padLeft(2, '0');
  int channel(double value) => (value * 255).round().clamp(0, 255);
  return '#${component(channel(color.r))}'
      '${component(channel(color.g))}'
      '${component(channel(color.b))}';
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
  final normalizedY =
      (bounds.northeast.latitude - marker.position.latitude) / latitudeSpan;

  return Offset(
    _statisticsMapFallbackPadding + (availableWidth * normalizedX),
    _statisticsMapFallbackPadding + (availableHeight * normalizedY),
  );
}

List<Offset> _statisticsMapFallbackOffsets({
  required List<_StatisticsMapMarkerData> markers,
  required Size size,
}) {
  return markers
      .map(
        (marker) => _statisticsMapFallbackOffsetForMarker(
          marker: marker,
          markers: markers,
          size: size,
        ),
      )
      .toList(growable: false);
}

bool _statisticsMapOffsetsEqual(List<Offset> left, List<Offset> right) {
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    if ((left[index] - right[index]).distance > 0.1) {
      return false;
    }
  }
  return true;
}
