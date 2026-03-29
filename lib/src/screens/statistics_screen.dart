import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:url_launcher/url_launcher.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../maplibre_web_registration.dart' as maplibre_web_registration;
import '../models.dart';
import '../runtime_platform.dart' as runtime_platform;
import '../stats_calculator.dart';
import '../widgets/app_media.dart';

Future<void> _refreshStatistics(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.controllerOf(context);
  final success = await controller.refreshData();
  if (!context.mounted || success) {
    return;
  }
  final message = controller.takeFlashMessage(l10n);
  if (message != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

Map<DrinkCategory, Color> _statisticsCategoryColors(ThemeData theme) {
  return <DrinkCategory, Color>{
    DrinkCategory.beer: theme.colorScheme.primary,
    DrinkCategory.wine: theme.colorScheme.secondary,
    DrinkCategory.spirits: theme.colorScheme.tertiary,
    DrinkCategory.cocktails: theme.colorScheme.error,
    DrinkCategory.nonAlcoholic: theme.colorScheme.primaryContainer,
  };
}

bool _statisticsGalleryHasImage(DrinkEntry entry) {
  final imagePath = entry.imagePath?.trim();
  return imagePath != null && imagePath.isNotEmpty;
}

int _statisticsGalleryCrossAxisCount(double maxWidth) {
  if (maxWidth >= 900) {
    return 5;
  }
  if (maxWidth >= 600) {
    return 4;
  }
  return 3;
}

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

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                key: const Key('statistics-tab-bar'),
                dividerColor: Colors.transparent,
                tabs: <Widget>[
                  Tab(text: l10n.statisticsOverview),
                  Tab(text: l10n.statisticsMap),
                  Tab(text: l10n.statisticsGallery),
                  Tab(text: l10n.history),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                const _StatisticsOverviewPage(),
                const _StatisticsMapPage(),
                const _StatisticsGalleryPage(),
                const _StatisticsHistoryPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsOverviewPage extends StatelessWidget {
  const _StatisticsOverviewPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = controller.statistics;
    final localeCode = controller.settings.localeCode;
    final colors = _statisticsCategoryColors(theme);

    return RefreshIndicator(
      key: const Key('statistics-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: ListView(
        key: const Key('statistics-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          _StatisticsOverviewPanel(stats: stats, localeCode: localeCode),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.categoryBreakdown,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 60,
                      sectionsSpace: 2,
                      sections: _buildSections(context, stats, colors),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: DrinkCategory.values.map((category) {
                    final count = stats.categoryCounts[category] ?? 0;
                    return _StatisticsLegendChip(
                      iconKey: Key(
                        'stats-category-chip-icon-${category.storageValue}',
                      ),
                      label: '${l10n.categoryLabel(category)} ($count)',
                      icon: category.icon,
                      accentColor: colors[category]!,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    BuildContext context,
    AppStatistics stats,
    Map<DrinkCategory, Color> colors,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return DrinkCategory.values.map((category) {
      final count = stats.categoryCounts[category] ?? 0;
      return PieChartSectionData(
        value: count.toDouble(),
        color: colors[category],
        radius: 48,
        title: count == 0 ? '' : '${l10n.categoryLabel(category)}\n$count',
        titleStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimary,
        ),
      );
    }).toList();
  }
}

class _StatisticsMapPage extends StatelessWidget {
  const _StatisticsMapPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final markers = _statisticsMapMarkersForEntries(
      AppScope.controllerOf(context).entries,
    );

    if (markers.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = math.max(constraints.maxHeight - 8, 1.0);

          return RefreshIndicator(
            key: const Key('statistics-map-refresh-indicator'),
            onRefresh: () => _refreshStatistics(context),
            child: ListView(
              key: const Key('statistics-map-list-view'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              children: <Widget>[
                SizedBox(
                  height: cardHeight,
                  child: _StatisticsEmptyStateCard(
                    key: const Key('statistics-map-empty-state'),
                    icon: Icons.map_rounded,
                    title: l10n.statisticsMapEmptyTitle,
                    body: l10n.statisticsMapEmptyBody,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = math.max(constraints.maxHeight - 8, 1.0);

        return RefreshIndicator(
          key: const Key('statistics-map-refresh-indicator'),
          onRefresh: () => _refreshStatistics(context),
          child: ListView(
            key: const Key('statistics-map-list-view'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            children: <Widget>[
              SizedBox(
                height: mapHeight,
                child: _StatisticsMapCard(markers: markers),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatisticsMapCard extends StatefulWidget {
  const _StatisticsMapCard({required this.markers});

  final List<_StatisticsMapMarkerData> markers;

  @override
  State<_StatisticsMapCard> createState() => _StatisticsMapCardState();
}

class _StatisticsMapCardState extends State<_StatisticsMapCard> {
  maplibre.MapLibreMapController? _controller;
  List<Offset> _markerOffsets = const <Offset>[];
  bool _isSyncScheduled = false;
  int _projectionRetryEpoch = 0;
  late double _currentZoom;
  late final maplibre.OnFeatureInteractionCallback _featureTapListener;

  bool get _usesOverlayClusters =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  double get _projectionScale {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 1;
    }
    return MediaQuery.devicePixelRatioOf(context);
  }

  @override
  void initState() {
    super.initState();
    _currentZoom = _statisticsMapInitialCameraPosition(widget.markers).zoom;
    _featureTapListener = _handleFeatureTap;
  }

  @override
  void didUpdateWidget(covariant _StatisticsMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_statisticsMapSignature(oldWidget.markers) !=
        _statisticsMapSignature(widget.markers)) {
      _projectionRetryEpoch += 1;
      _currentZoom = _statisticsMapInitialCameraPosition(widget.markers).zoom;
      _markerOffsets = const <Offset>[];
      _scheduleMarkerSync();
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.onFeatureTapped.remove(_featureTapListener);
    }
    super.dispose();
  }

  Future<void> _handleStyleLoaded() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    if (!_usesOverlayClusters) {
      await _configureClusterLayers(controller);
    }
    await _fitStatisticsMapCamera(controller, widget.markers);
    _scheduleMarkerSync();
    _scheduleProjectionRetries();
  }

  Future<void> _configureClusterLayers(
    maplibre.MapLibreMapController controller,
  ) async {
    final theme = Theme.of(context);
    final clusterColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.primary;
    final labelColor = _statisticsMapMarkerForegroundColor(clusterColor);
    final strokeColor = theme.colorScheme.surface;

    for (final layerId in <String>[
      _statisticsMapClusterCountLayerId,
      _statisticsMapClusterCircleLayerId,
    ]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Ignore style resets while recreating layers.
      }
    }

    try {
      await controller.removeSource(_statisticsMapClusterSourceId);
    } catch (_) {
      // Ignore missing source during initial style loads.
    }

    await controller.addSource(
      _statisticsMapClusterSourceId,
      maplibre.GeojsonSourceProperties(
        data: _statisticsMapClusterGeoJson(widget.markers),
        cluster: true,
        clusterRadius: _statisticsMapClusterRadius,
        clusterMaxZoom: _statisticsMapClusterMaxZoom,
      ),
    );
    await controller.addCircleLayer(
      _statisticsMapClusterSourceId,
      _statisticsMapClusterCircleLayerId,
      maplibre.CircleLayerProperties(
        circleColor: _statisticsMapHexColor(clusterColor),
        circleOpacity: 0.96,
        circleRadius: const <Object>[
          'step',
          <Object>['get', 'point_count'],
          18,
          3,
          21,
          8,
          24,
          20,
          28,
        ],
        circleStrokeColor: _statisticsMapHexColor(strokeColor),
        circleStrokeOpacity: 0.92,
        circleStrokeWidth: 2.5,
      ),
      maxzoom: _statisticsMapDetailMarkerMinZoom,
      filter: const <Object>['has', 'point_count'],
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      _statisticsMapClusterSourceId,
      _statisticsMapClusterCountLayerId,
      maplibre.SymbolLayerProperties(
        textField: '{point_count}',
        textFont: const <String>['Noto Sans Medium', 'Noto Sans Regular'],
        textSize: 13,
        textColor: _statisticsMapHexColor(labelColor),
        textHaloColor: _statisticsMapHexColor(strokeColor),
        textHaloWidth: 1.2,
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      maxzoom: _statisticsMapDetailMarkerMinZoom,
      filter: const <Object>['has', 'point_count'],
      enableInteraction: true,
    );
  }

  Future<void> _handleFeatureTap(
    math.Point<double> point,
    maplibre.LatLng coordinates,
    String id,
    String layerId,
    maplibre.Annotation? annotation,
  ) async {
    if (layerId != _statisticsMapClusterCircleLayerId &&
        layerId != _statisticsMapClusterCountLayerId) {
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }

    final nextZoom = math.min(
      _currentZoom + _statisticsMapTapResolveZoomStep,
      _statisticsMapTapResolveMaxZoom,
    );
    await controller.animateCamera(
      maplibre.CameraUpdate.newLatLngZoom(coordinates, nextZoom),
    );
  }

  void _scheduleMarkerSync() {
    if (_isSyncScheduled || !mounted) {
      return;
    }

    _isSyncScheduled = true;
    scheduleMicrotask(() async {
      _isSyncScheduled = false;
      await _syncMarkerOffsets();
    });
  }

  Future<void> _syncMarkerOffsets() async {
    final controller = _controller;
    if (controller == null || !mounted) {
      return;
    }

    try {
      final points = await controller.toScreenLocationBatch(
        widget.markers.map((marker) => marker.position),
      );
      if (!mounted) {
        return;
      }

      final projectionScale = _projectionScale;
      final nextOffsets = points
          .map(
            (point) => Offset(
              point.x.toDouble() / projectionScale,
              point.y.toDouble() / projectionScale,
            ),
          )
          .toList(growable: false);
      if (_statisticsMapOffsetsEqual(_markerOffsets, nextOffsets)) {
        return;
      }

      setState(() {
        _markerOffsets = nextOffsets;
      });
    } catch (_) {
      // Ignore transient projection errors during initial style loads.
    }
  }

  void _handleCameraMove(maplibre.CameraPosition cameraPosition) {
    final previousShowsMarkers = _statisticsMapShowsIndividualMarkers(
      _currentZoom,
    );
    _currentZoom = cameraPosition.zoom;
    final nextShowsMarkers = _statisticsMapShowsIndividualMarkers(_currentZoom);
    if (previousShowsMarkers != nextShowsMarkers && mounted) {
      setState(() {});
    }
    _scheduleMarkerSync();
  }

  void _handleCameraIdle() {
    _scheduleMarkerSync();
  }

  Future<void> _handleMarkerTap(
    int index,
    _StatisticsMapMarkerData marker,
    List<Offset> offsets,
    Map<DrinkCategory, Color> colors,
  ) async {
    final tapResolution = resolveStatisticsMapMarkerTap(
      offsets: offsets,
      tappedIndex: index,
      currentZoom: _currentZoom,
    );
    if (tapResolution == StatisticsMapTapResolution.zoomIn &&
        runtime_platform.isMapLibrePlatformSupported) {
      final controller = _controller;
      if (controller != null) {
        final overlappingIndexes = statisticsMapOverlappingMarkerIndexes(
          offsets: offsets,
          tappedIndex: index,
        );
        final group = overlappingIndexes
            .map((markerIndex) => widget.markers[markerIndex])
            .toList(growable: false);
        await _zoomToMarkerGroup(controller, group);
        return;
      }
    }

    if (!mounted) {
      return;
    }

    final backgroundColor = colors[marker.entry.category]!;
    await _showStatisticsMapEntrySheet(context, marker, backgroundColor);
  }

  Future<void> _zoomToMarkerGroup(
    maplibre.MapLibreMapController controller,
    List<_StatisticsMapMarkerData> markers,
  ) async {
    if (markers.isEmpty) {
      return;
    }

    if (markers.length == 1) {
      await controller.animateCamera(
        maplibre.CameraUpdate.newLatLngZoom(
          markers.single.position,
          math.min(
            _currentZoom + _statisticsMapTapResolveZoomStep,
            _statisticsMapTapResolveMaxZoom,
          ),
        ),
      );
      return;
    }

    final bounds = _statisticsMapBounds(markers);
    if (bounds != null) {
      final latitudeSpan =
          (bounds.northeast.latitude - bounds.southwest.latitude).abs();
      final longitudeSpan =
          (bounds.northeast.longitude - bounds.southwest.longitude).abs();
      if (latitudeSpan > 0.000001 || longitudeSpan > 0.000001) {
        await controller.animateCamera(
          maplibre.CameraUpdate.newLatLngBounds(
            bounds,
            left: _statisticsMapBoundsPadding,
            top: _statisticsMapBoundsPadding,
            right: _statisticsMapBoundsPadding,
            bottom: _statisticsMapBoundsPadding,
          ),
        );
        return;
      }
    }

    final averageLatitude =
        markers.fold<double>(
          0,
          (sum, current) => sum + current.position.latitude,
        ) /
        markers.length;
    final averageLongitude =
        markers.fold<double>(
          0,
          (sum, current) => sum + current.position.longitude,
        ) /
        markers.length;
    await controller.animateCamera(
      maplibre.CameraUpdate.newLatLngZoom(
        maplibre.LatLng(averageLatitude, averageLongitude),
        math.min(
          _currentZoom + _statisticsMapTapResolveZoomStep,
          _statisticsMapTapResolveMaxZoom,
        ),
      ),
    );
  }

  Future<void> _handleOverlayClusterTap(List<int> markerIndexes) async {
    if (markerIndexes.isEmpty) {
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }

    final markers = markerIndexes
        .map((index) => widget.markers[index])
        .toList(growable: false);
    await _zoomToMarkerGroup(controller, markers);
  }

  void _scheduleProjectionRetries() {
    final retryEpoch = ++_projectionRetryEpoch;
    const retryDelays = <Duration>[
      Duration(milliseconds: 120),
      Duration(milliseconds: 320),
      Duration(milliseconds: 700),
    ];

    for (final delay in retryDelays) {
      Future<void>.delayed(delay, () async {
        if (!mounted || retryEpoch != _projectionRetryEpoch) {
          return;
        }
        await _syncMarkerOffsets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    maplibre_web_registration.ensureMapLibreWebRegistered();

    final theme = Theme.of(context);
    final controller = AppScope.controllerOf(context);
    final colors = _statisticsCategoryColors(theme);
    final styleString = _statisticsMapStyleString(
      brightness: theme.brightness,
      localeCode: controller.settings.localeCode,
    );
    final useMapLibre = runtime_platform.isMapLibrePlatformSupported;

    return ClipRect(
      key: const Key('statistics-map-card'),
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showsIndividualMarkers =
                !useMapLibre ||
                _statisticsMapShowsIndividualMarkers(_currentZoom);
            final showsOverlayClusters =
                useMapLibre && _usesOverlayClusters && !showsIndividualMarkers;
            final overlayOffsets =
                _markerOffsets.length == widget.markers.length
                ? _markerOffsets
                : _statisticsMapFallbackOffsets(
                    markers: widget.markers,
                    size: constraints.biggest,
                  );
            final overlayChildren = !useMapLibre
                ? const <Widget>[]
                : showsOverlayClusters
                ? _statisticsMapClusterOverlayWidgets(
                    markers: widget.markers,
                    offsets: overlayOffsets,
                    colors: colors,
                    onMarkerTap: (index, marker) =>
                        _handleMarkerTap(index, marker, overlayOffsets, colors),
                    onClusterTap: _handleOverlayClusterTap,
                  )
                : () {
                    final visibleMarkerIndexes = showsIndividualMarkers
                        ? List<int>.generate(
                            widget.markers.length,
                            (index) => index,
                          )
                        : statisticsMapStandaloneMarkerIndexes(
                            offsets: overlayOffsets,
                          );
                    final visibleMarkers = visibleMarkerIndexes
                        .map((index) => widget.markers[index])
                        .toList(growable: false);
                    final visibleOffsets = visibleMarkerIndexes
                        .map((index) => overlayOffsets[index])
                        .toList(growable: false);
                    return visibleOffsets.isNotEmpty
                        ? _statisticsMapMarkerWidgets(
                            markers: visibleMarkers,
                            markerIndexes: visibleMarkerIndexes,
                            offsets: visibleOffsets,
                            colors: colors,
                            onMarkerTap: (index, marker) => _handleMarkerTap(
                              index,
                              marker,
                              overlayOffsets,
                              colors,
                            ),
                          )
                        : const <Widget>[];
                  }();

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: useMapLibre
                      ? maplibre.MapLibreMap(
                          key: ValueKey<String>(
                            '${_statisticsMapSignature(widget.markers)}:$styleString',
                          ),
                          initialCameraPosition:
                              _statisticsMapInitialCameraPosition(
                                widget.markers,
                              ),
                          styleString: styleString,
                          logoEnabled: false,
                          compassEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          gestureRecognizers: _statisticsMapGestureRecognizers,
                          trackCameraPosition: true,
                          attributionButtonPosition:
                              maplibre.AttributionButtonPosition.bottomRight,
                          onMapCreated: (controller) {
                            _controller?.onFeatureTapped.remove(
                              _featureTapListener,
                            );
                            _controller = controller;
                            controller.onFeatureTapped.add(_featureTapListener);
                            _scheduleProjectionRetries();
                          },
                          onStyleLoadedCallback: _handleStyleLoaded,
                          onCameraMove: _handleCameraMove,
                          onCameraIdle: _handleCameraIdle,
                        )
                      : _StatisticsMapFallbackSurface(
                          markers: widget.markers,
                          colors: colors,
                        ),
                ),
                ...overlayChildren,
                if (!useMapLibre)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _StatisticsMapAttributionCard(
                      children: _statisticsMapAttributionChildren(theme),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
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
    final categoryLabel = l10n.categoryLabel(entry.category);
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

class _StatisticsHistoryPage extends StatefulWidget {
  const _StatisticsHistoryPage();

  @override
  State<_StatisticsHistoryPage> createState() => _StatisticsHistoryPageState();
}

class _StatisticsHistoryPageState extends State<_StatisticsHistoryPage> {
  DrinkCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = _selectedCategory == null
        ? controller.entries
        : controller.entries
              .where((entry) => entry.category == _selectedCategory)
              .toList();

    return RefreshIndicator(
      key: const Key('statistics-history-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: ListView(
        key: const Key('statistics-history-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: DrinkCategory.values.map((category) {
                final count =
                    controller.statistics.categoryCounts[category] ?? 0;
                return FilterChip(
                  selected: _selectedCategory == category,
                  showCheckmark: false,
                  avatar: Icon(
                    category.icon,
                    key: Key(
                      'statistics-history-category-chip-icon-${category.storageValue}',
                    ),
                    size: 18,
                  ),
                  label: Text('${l10n.categoryLabel(category)} ($count)'),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = _selectedCategory == category
                          ? null
                          : category;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l10n.emptyFilter),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StatisticsHistoryEntryCard(entry: entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatisticsHistoryEntryCard extends StatelessWidget {
  const _StatisticsHistoryEntryCard({required this.entry});

  final DrinkEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final locationAddress = _normalizedLocationAddress(entry.locationAddress);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(entry.category.icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  controller.localizedEntryDrinkName(entry),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat.yMMMd(
                    controller.settings.localeCode,
                  ).format(entry.consumedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (locationAddress != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        key: Key(
                          'statistics-history-location-icon-${entry.id}',
                        ),
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationAddress,
                          key: Key('statistics-history-location-${entry.id}'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(controller.settings.unit.formatVolume(entry.volumeMl)),
        ],
      ),
    );
  }

  String? _normalizedLocationAddress(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class _StatisticsGalleryPage extends StatelessWidget {
  const _StatisticsGalleryPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final entries = controller.entries
        .where(_statisticsGalleryHasImage)
        .toList(growable: false);
    final galleryItems = entries
        .map(
          (entry) => AppGalleryViewerItem(
            imagePath: entry.imagePath!.trim(),
            drinkName: controller.localizedEntryDrinkName(
              entry,
              localeCode: localeCode,
            ),
            metadata: <String>[
              l10n.categoryLabel(entry.category),
              DateFormat.yMMMd(localeCode).add_Hm().format(entry.consumedAt),
              if (entry.volumeMl != null) unit.formatVolume(entry.volumeMl),
              if (_normalizedLocationAddress(entry.locationAddress) != null)
                _normalizedLocationAddress(entry.locationAddress)!,
            ],
            comment: _normalizedGalleryComment(entry.comment),
          ),
        )
        .toList(growable: false);

    if (entries.isEmpty) {
      return RefreshIndicator(
        key: const Key('statistics-gallery-refresh-indicator'),
        onRefresh: () => _refreshStatistics(context),
        child: ListView(
          key: const Key('statistics-gallery-list-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            _StatisticsEmptyStateCard(
              key: const Key('statistics-gallery-empty-state'),
              icon: Icons.photo_library_rounded,
              title: l10n.statisticsGalleryEmptyTitle,
              body: l10n.statisticsGalleryEmptyBody,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const Key('statistics-gallery-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            key: const Key('statistics-gallery-grid'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _statisticsGalleryCrossAxisCount(
                constraints.maxWidth,
              ),
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final galleryItem = galleryItems[index];

              return _StatisticsGalleryTile(
                key: Key('statistics-gallery-tile-${entry.id}'),
                imagePath: galleryItem.imagePath,
                onTap: () {
                  showAppGalleryViewerDialog(
                    context,
                    items: galleryItems,
                    initialIndex: index,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String? _normalizedGalleryComment(String? comment) {
    final normalized = comment?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _normalizedLocationAddress(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

class _StatisticsGalleryTile extends StatefulWidget {
  const _StatisticsGalleryTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  final String imagePath;
  final VoidCallback onTap;

  @override
  State<_StatisticsGalleryTile> createState() => _StatisticsGalleryTileState();
}

class _StatisticsGalleryTileState extends State<_StatisticsGalleryTile> {
  late Future<ImageProvider<Object>?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateImageFuture();
  }

  @override
  void didUpdateWidget(covariant _StatisticsGalleryTile oldWidget) {
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: FutureBuilder<ImageProvider<Object>?>(
                future: _imageFuture,
                builder: (context, snapshot) {
                  final imageProvider = snapshot.data;
                  if (imageProvider == null) {
                    return Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    );
                  }
                  return Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsEmptyStateCard extends StatelessWidget {
  const _StatisticsEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 36, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsLegendChip extends StatelessWidget {
  const _StatisticsLegendChip({
    required this.iconKey,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final Key iconKey;
  final String label;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withValues(alpha: 0.1),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, key: iconKey, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsOverviewPanel extends StatelessWidget {
  const _StatisticsOverviewPanel({
    required this.stats,
    required this.localeCode,
  });

  final AppStatistics stats;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final panelPadding = isCompact ? 16.0 : 20.0;
        final tileSpacing = isCompact ? 8.0 : 12.0;

        return Container(
          key: const Key('stats-overview-panel'),
          padding: EdgeInsets.all(panelPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  key: const Key('stats-overview-totals-row'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.calendar_view_week_rounded,
                        iconKey: const Key('stats-card-icon-weekly'),
                        label: l10n.weeklyTotal,
                        value: '${stats.weeklyTotal}',
                        valueKey: const Key('stats-card-value-weekly'),
                        accentColor: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        isCompact: isCompact,
                      ),
                    ),
                    SizedBox(width: tileSpacing),
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.calendar_month_rounded,
                        iconKey: const Key('stats-card-icon-monthly'),
                        label: l10n.monthlyTotal,
                        value: '${stats.monthlyTotal}',
                        valueKey: const Key('stats-card-value-monthly'),
                        accentColor: theme.colorScheme.secondary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        isCompact: isCompact,
                      ),
                    ),
                    SizedBox(width: tileSpacing),
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.event_available_rounded,
                        iconKey: const Key('stats-card-icon-yearly'),
                        label: l10n.yearlyTotal,
                        value: '${stats.yearlyTotal}',
                        valueKey: const Key('stats-card-value-yearly'),
                        accentColor: theme.colorScheme.tertiary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tileSpacing),
              IntrinsicHeight(
                child: Row(
                  key: const Key('stats-overview-streaks-row'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.local_fire_department_rounded,
                        iconKey: const Key('stats-card-icon-current-streak'),
                        label: l10n.currentStreak,
                        value:
                            '${stats.currentStreak} ${l10n.dayLabel(stats.currentStreak)}',
                        valueKey: const Key('stats-card-value-current-streak'),
                        accentColor: _currentStreakAccentColor(theme, stats),
                        backgroundColor: _currentStreakBackgroundColor(
                          theme,
                          stats,
                        ),
                        isCompact: isCompact,
                        isEmphasized: true,
                      ),
                    ),
                    SizedBox(width: tileSpacing),
                    Expanded(
                      child: _OverviewMetricTile(
                        icon: Icons.emoji_events_rounded,
                        iconKey: const Key('stats-card-icon-best-streak'),
                        label: l10n.bestStreak,
                        value:
                            '${stats.bestStreak} ${l10n.dayLabel(stats.bestStreak)}',
                        valueKey: const Key('stats-card-value-best-streak'),
                        subtitle: _formatBestStreakRange(stats),
                        subtitleKey: const Key('stats-card-best-streak-range'),
                        accentColor: theme.colorScheme.secondary,
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.secondary.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.22
                                : 0.1,
                          ),
                          theme.colorScheme.surface,
                        ),
                        isCompact: isCompact,
                        isEmphasized: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _formatBestStreakRange(AppStatistics stats) {
    final start = stats.bestStreakStart;
    final end = stats.bestStreakEnd;
    if (start == null || end == null || stats.bestStreak == 0) {
      return null;
    }

    if (DateUtils.isSameDay(start, end)) {
      return DateFormat.MMMd(localeCode).format(start);
    }

    final formatter = start.year == end.year
        ? DateFormat.MMMd(localeCode)
        : DateFormat.yMMMd(localeCode);
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  Color _currentStreakAccentColor(ThemeData theme, AppStatistics stats) {
    final scheme = theme.colorScheme;
    return switch (stats.streakMessageState) {
      StreakMessageState.start => scheme.onSurfaceVariant,
      StreakMessageState.keepAlive =>
        theme.brightness == Brightness.dark
            ? scheme.tertiary
            : const Color(0xFF8A5A00),
      StreakMessageState.startedToday =>
        theme.brightness == Brightness.dark
            ? scheme.secondary
            : const Color(0xFF2F6F6D),
      StreakMessageState.continuedToday => scheme.primary,
    };
  }

  Color _currentStreakBackgroundColor(ThemeData theme, AppStatistics stats) {
    final accentColor = _currentStreakAccentColor(theme, stats);
    return Color.alphaBlend(
      accentColor.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.22 : 0.1,
      ),
      theme.colorScheme.surface,
    );
  }
}

class _OverviewMetricTile extends StatelessWidget {
  const _OverviewMetricTile({
    required this.icon,
    required this.iconKey,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.backgroundColor,
    required this.isCompact,
    this.valueKey,
    this.subtitle,
    this.subtitleKey,
    this.isEmphasized = false,
  });

  final IconData icon;
  final Key iconKey;
  final String label;
  final String value;
  final Color accentColor;
  final Color backgroundColor;
  final bool isCompact;
  final Key? valueKey;
  final String? subtitle;
  final Key? subtitleKey;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = isCompact ? 16.0 : 18.0;
    final badgePadding = isCompact ? 7.0 : 8.0;
    final tilePadding = isCompact ? 12.0 : 14.0;
    final labelStyle =
        (isEmphasized
                ? theme.textTheme.labelLarge
                : theme.textTheme.labelMedium)
            ?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            );
    final valueStyle =
        (isEmphasized
                ? theme.textTheme.headlineSmall
                : theme.textTheme.titleLarge)
            ?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.05,
            );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return Container(
      padding: EdgeInsets.all(tilePadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(badgePadding),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, key: iconKey, color: accentColor, size: iconSize),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            label,
            maxLines: isEmphasized ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(key: valueKey, value, style: valueStyle),
          ),
          if (subtitle != null) ...<Widget>[
            SizedBox(height: isCompact ? 8 : 10),
            Text(
              key: subtitleKey,
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ],
        ],
      ),
    );
  }
}
