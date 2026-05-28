part of '../statistics_screen.dart';

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
  String? _hoveredMarkerEntryId;
  bool _isWebHoverQueryInFlight = false;
  int _webHoverEpoch = 0;
  math.Point<double>? _pendingWebHoverPoint;
  VoidCallback? _detachWebMouseLeaveListener;
  late double _currentZoom;
  late final maplibre.OnFeatureInteractionCallback _featureTapListener;
  late final maplibre.OnFeatureHoverCallback _featureHoverListener;
  late final maplibre.OnMapMouseMoveCallback _mapMouseMoveListener;
  Map<String, DrinkDefinition> _drinkDefinitionsById =
      const <String, DrinkDefinition>{};
  String _markerAssetSignature = '';

  double get _nativeMarkerIconSize => 1;

  double get _nativeMarkerSpriteScale {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MediaQuery.devicePixelRatioOf(context);
    }
    return 1;
  }

  double get _projectionScale {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 1;
    }
    return MediaQuery.devicePixelRatioOf(context);
  }

  List<DrinkEntry> get _entries =>
      widget.markers.map((marker) => marker.entry).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _currentZoom = _statisticsMapInitialCameraPosition(widget.markers).zoom;
    _featureTapListener = _handleFeatureTap;
    _featureHoverListener = _handleFeatureHover;
    _mapMouseMoveListener = _handleMapMouseMove;
  }

  @override
  void didUpdateWidget(covariant _StatisticsMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_statisticsMapSignature(oldWidget.markers) !=
        _statisticsMapSignature(widget.markers)) {
      _currentZoom = _statisticsMapInitialCameraPosition(widget.markers).zoom;
      if (_hoveredMarkerEntryId != null &&
          !widget.markers.any(
            (marker) => marker.entry.id == _hoveredMarkerEntryId,
          )) {
        _hoveredMarkerEntryId = null;
      }
      _updateMarkerAssetCache();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMarkerAssetCache();
  }

  void _updateMarkerAssetCache() {
    final allDrinks = AppScope.controllerOf(context).allDrinks;
    _drinkDefinitionsById = _statisticsMapDrinkDefinitionsById(allDrinks);
    _markerAssetSignature = _statisticsMapMarkerAssetSignature(
      widget.markers,
      Theme.of(context),
      drinkDefinitionsById: _drinkDefinitionsById,
      spriteScale: _nativeMarkerSpriteScale,
    );
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.onFeatureTapped.remove(_featureTapListener);
      controller.onFeatureHover.remove(_featureHoverListener);
      controller.onMapMouseMove.remove(_mapMouseMoveListener);
    }
    _detachWebMouseLeaveListener?.call();
    _setWebCanvasCursor('');
    super.dispose();
  }

  Future<void> _handleStyleLoaded() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final theme = Theme.of(context);

    await _configureNativeLayers(
      controller,
      theme: theme,
      drinkDefinitionsById: _drinkDefinitionsById,
      markerAssetSignature: _markerAssetSignature,
    );
    _attachWebMouseLeaveListener();
    _setWebCanvasCursor('');
    await _fitStatisticsMapCamera(controller, widget.markers);
  }

  Future<void> _configureNativeLayers(
    maplibre.MapLibreMapController controller, {
    required ThemeData theme,
    required Map<String, DrinkDefinition> drinkDefinitionsById,
    required String markerAssetSignature,
  }) async {
    final clusterColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.primary;
    final labelColor = _statisticsMapMarkerForegroundColor(clusterColor);
    final strokeColor = theme.colorScheme.surface;

    for (final layerId in <String>[
      _statisticsMapDetailMarkerHitLayerId,
      _statisticsMapDetailMarkerHoverLayerId,
      _statisticsMapDetailMarkerLayerId,
      _statisticsMapLowZoomMarkerHitLayerId,
      _statisticsMapLowZoomMarkerHoverLayerId,
      _statisticsMapLowZoomMarkerLayerId,
      _statisticsMapClusterCountLayerId,
      _statisticsMapClusterCircleLayerId,
    ]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Ignore style resets while recreating layers.
      }
    }

    for (final sourceId in <String>[
      _statisticsMapDetailSourceId,
      _statisticsMapClusteredSourceId,
    ]) {
      try {
        await controller.removeSource(sourceId);
      } catch (_) {
        // Ignore missing sources during initial style loads.
      }
    }

    await _configureStatisticsMapMarkerImages(
      controller,
      theme: theme,
      entries: _entries,
      drinkDefinitionsById: drinkDefinitionsById,
      markerAssetSignature: markerAssetSignature,
      spriteScale: _nativeMarkerSpriteScale,
    );

    await controller.addSource(
      _statisticsMapClusteredSourceId,
      maplibre.GeojsonSourceProperties(
        data: statisticsMapClusteredSourceGeoJsonForEntries(
          entries: _entries,
          markerAssetSignature: markerAssetSignature,
          theme: theme,
          drinkDefinitionsById: drinkDefinitionsById,
        ),
        cluster: true,
        clusterRadius: _statisticsMapClusterRadius,
        clusterMaxZoom: _statisticsMapClusterMaxZoom,
      ),
    );
    await controller.addSource(
      _statisticsMapDetailSourceId,
      maplibre.GeojsonSourceProperties(
        data: statisticsMapDetailSourceGeoJsonForEntries(
          entries: _entries,
          markerAssetSignature: markerAssetSignature,
          theme: theme,
          drinkDefinitionsById: drinkDefinitionsById,
        ),
      ),
    );
    await controller.addCircleLayer(
      _statisticsMapClusteredSourceId,
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
      _statisticsMapClusteredSourceId,
      _statisticsMapClusterCountLayerId,
      _statisticsMapClusterCountLayerProperties(labelColor: labelColor),
      maxzoom: _statisticsMapDetailMarkerMinZoom,
      filter: const <Object>['has', 'point_count'],
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      _statisticsMapClusteredSourceId,
      _statisticsMapLowZoomMarkerLayerId,
      _statisticsMapMarkerLayerProperties(iconSize: _nativeMarkerIconSize),
      maxzoom: _statisticsMapDetailMarkerMinZoom,
      filter: <Object>[
        '!',
        const <Object>['has', 'point_count'],
      ],
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      _statisticsMapClusteredSourceId,
      _statisticsMapLowZoomMarkerHoverLayerId,
      _statisticsMapMarkerHoverLayerProperties(iconSize: _nativeMarkerIconSize),
      maxzoom: _statisticsMapDetailMarkerMinZoom,
      filter: _statisticsMapEntryIdFilter(_hoveredMarkerEntryId),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _statisticsMapClusteredSourceId,
      _statisticsMapLowZoomMarkerHitLayerId,
      _statisticsMapMarkerHitLayerProperties(),
      maxzoom: _statisticsMapDetailMarkerMinZoom,
      filter: <Object>[
        '!',
        const <Object>['has', 'point_count'],
      ],
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      _statisticsMapDetailSourceId,
      _statisticsMapDetailMarkerLayerId,
      _statisticsMapMarkerLayerProperties(iconSize: _nativeMarkerIconSize),
      minzoom: _statisticsMapDetailMarkerMinZoom,
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      _statisticsMapDetailSourceId,
      _statisticsMapDetailMarkerHoverLayerId,
      _statisticsMapMarkerHoverLayerProperties(iconSize: _nativeMarkerIconSize),
      minzoom: _statisticsMapDetailMarkerMinZoom,
      filter: _statisticsMapEntryIdFilter(_hoveredMarkerEntryId),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _statisticsMapDetailSourceId,
      _statisticsMapDetailMarkerHitLayerId,
      _statisticsMapMarkerHitLayerProperties(),
      minzoom: _statisticsMapDetailMarkerMinZoom,
      enableInteraction: true,
    );

    await _updateHoveredMarkerFilters();
  }

  Future<void> _handleFeatureTap(
    math.Point<double> point,
    maplibre.LatLng coordinates,
    String id,
    String layerId,
    maplibre.Annotation? annotation,
  ) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    if (layerId == _statisticsMapClusterCircleLayerId ||
        layerId == _statisticsMapClusterCountLayerId) {
      final nextZoom = math.min(
        _currentZoom + _statisticsMapTapResolveZoomStep,
        _statisticsMapTapResolveMaxZoom,
      );
      await controller.animateCamera(
        maplibre.CameraUpdate.newLatLngZoom(coordinates, nextZoom),
      );
      return;
    }

    final markerIndex = await _resolveTappedMarkerIndex(
      controller: controller,
      point: point,
      layerId: layerId,
      featureId: id,
    );
    if (markerIndex == -1) {
      return;
    }

    final marker = widget.markers[markerIndex];
    if (layerId == _statisticsMapLowZoomMarkerLayerId ||
        layerId == _statisticsMapLowZoomMarkerHitLayerId) {
      await _openMarkerSheet(marker);
      return;
    }

    if (layerId != _statisticsMapDetailMarkerLayerId &&
        layerId != _statisticsMapDetailMarkerHitLayerId) {
      return;
    }

    try {
      final offsets = await _projectMarkerOffsets(controller);
      final tapResolution = resolveStatisticsMapMarkerTap(
        offsets: offsets,
        tappedIndex: markerIndex,
        currentZoom: _currentZoom,
      );
      if (tapResolution == StatisticsMapTapResolution.zoomIn) {
        final overlappingIndexes = statisticsMapOverlappingMarkerIndexes(
          offsets: offsets,
          tappedIndex: markerIndex,
        );
        final group = overlappingIndexes
            .map((index) => widget.markers[index])
            .toList(growable: false);
        await _zoomToMarkerGroup(controller, group);
        return;
      }
    } catch (_) {
      // Fall back to the tapped marker when transient projection fails.
    }

    await _openMarkerSheet(marker);
  }

  Future<void> _handleFeatureHover(
    math.Point<double> point,
    maplibre.LatLng coordinates,
    String id,
    maplibre.Annotation? annotation,
    maplibre.HoverEventType eventType,
  ) async {
    final markerExists = widget.markers.any((marker) => marker.entry.id == id);
    if (!markerExists) {
      return;
    }

    final nextHoveredEntryId = switch (eventType) {
      maplibre.HoverEventType.enter => id,
      maplibre.HoverEventType.move => id,
      maplibre.HoverEventType.leave =>
        _hoveredMarkerEntryId == id ? null : _hoveredMarkerEntryId,
    };

    if (nextHoveredEntryId == _hoveredMarkerEntryId) {
      return;
    }

    await _setHoveredMarkerEntryId(nextHoveredEntryId);
  }

  Future<void> _handleMapMouseMove(
    math.Point<double> point,
    maplibre.LatLng coordinates,
  ) async {
    if (!kIsWeb || !runtime_platform.isMapLibrePlatformSupported) {
      return;
    }

    final epoch = _webHoverEpoch;
    if (_isWebHoverQueryInFlight) {
      _pendingWebHoverPoint = point;
      return;
    }

    await _runWebHoverQuery(point: point, epoch: epoch);
  }

  Future<void> _runWebHoverQuery({
    required math.Point<double> point,
    required int epoch,
  }) async {
    _isWebHoverQueryInFlight = true;
    try {
      await _updateHoveredMarkerFromPoint(point: point, epoch: epoch);
    } finally {
      _isWebHoverQueryInFlight = false;
      final pendingPoint = _pendingWebHoverPoint;
      _pendingWebHoverPoint = null;
      if (pendingPoint != null && mounted && epoch == _webHoverEpoch) {
        unawaited(_runWebHoverQuery(point: pendingPoint, epoch: epoch));
      }
    }
  }

  Future<void> _updateHoveredMarkerFromPoint({
    required math.Point<double> point,
    required int epoch,
  }) async {
    final controller = _controller;
    if (controller == null) {
      await _setHoveredMarkerEntryId(null);
      return;
    }

    String? nextHoveredEntryId;
    try {
      final features = await controller.queryRenderedFeatures(point, <String>[
        _statisticsMapLowZoomMarkerLayerId,
        _statisticsMapDetailMarkerLayerId,
        _statisticsMapLowZoomMarkerHitLayerId,
        _statisticsMapDetailMarkerHitLayerId,
      ], null);
      for (final feature in features) {
        if (feature is! Map) {
          continue;
        }
        final properties = feature['properties'];
        if (properties is! Map) {
          continue;
        }
        final entryId = properties['entryId']?.toString();
        if (entryId == null || entryId.isEmpty) {
          continue;
        }
        if (widget.markers.any((marker) => marker.entry.id == entryId)) {
          nextHoveredEntryId = entryId;
          break;
        }
      }
    } catch (_) {
      // Ignore transient rendered-feature query failures during hover.
    }

    if (!mounted || epoch != _webHoverEpoch) {
      return;
    }
    await _setHoveredMarkerEntryId(nextHoveredEntryId);
  }

  Future<void> _handleWebMouseExit() async {
    _webHoverEpoch += 1;
    _pendingWebHoverPoint = null;
    await _setHoveredMarkerEntryId(null);
  }

  void _attachWebMouseLeaveListener() {
    if (!kIsWeb) {
      return;
    }

    _detachWebMouseLeaveListener?.call();
    _detachWebMouseLeaveListener = statistics_map_web_cursor
        .attachStatisticsMapWebMouseLeaveListener(() {
          unawaited(_handleWebMouseExit());
        });
  }

  void _setWebCanvasCursor(String cursor) {
    if (!kIsWeb) {
      return;
    }
    statistics_map_web_cursor.setStatisticsMapWebCursor(cursor);
  }

  Future<void> _setHoveredMarkerEntryId(String? nextHoveredEntryId) async {
    if (nextHoveredEntryId == _hoveredMarkerEntryId) {
      return;
    }

    if (mounted) {
      setState(() {
        _hoveredMarkerEntryId = nextHoveredEntryId;
      });
    } else {
      _hoveredMarkerEntryId = nextHoveredEntryId;
    }
    _setWebCanvasCursor(nextHoveredEntryId == null ? '' : 'pointer');
    await _updateHoveredMarkerFilters();
  }

  Future<int> _resolveTappedMarkerIndex({
    required maplibre.MapLibreMapController controller,
    required math.Point<double> point,
    required String layerId,
    required String featureId,
  }) async {
    final directIndex = widget.markers.indexWhere(
      (marker) => marker.entry.id == featureId,
    );
    if (directIndex != -1) {
      return directIndex;
    }

    try {
      final features = await controller.queryRenderedFeatures(point, <String>[
        layerId,
      ], null);
      for (final feature in features) {
        if (feature is! Map) {
          continue;
        }
        final properties = feature['properties'];
        if (properties is! Map) {
          continue;
        }
        final entryId = properties['entryId']?.toString();
        if (entryId == null || entryId.isEmpty) {
          continue;
        }
        final resolvedIndex = widget.markers.indexWhere(
          (marker) => marker.entry.id == entryId,
        );
        if (resolvedIndex != -1) {
          return resolvedIndex;
        }
      }
    } catch (_) {
      // Ignore transient rendered-feature query failures and fall through.
    }

    return -1;
  }

  Future<void> _updateHoveredMarkerFilters() async {
    if (!kIsWeb) {
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }

    final filter = _statisticsMapEntryIdFilter(_hoveredMarkerEntryId);
    try {
      await controller.setFilter(
        _statisticsMapLowZoomMarkerHoverLayerId,
        filter,
      );
      await controller.setFilter(
        _statisticsMapDetailMarkerHoverLayerId,
        filter,
      );
    } catch (_) {
      // Ignore transient style resets while hover layers are being recreated.
    }
  }

  void _handleCameraMove(maplibre.CameraPosition cameraPosition) {
    _currentZoom = cameraPosition.zoom;
  }

  Future<List<Offset>> _projectMarkerOffsets(
    maplibre.MapLibreMapController controller,
  ) async {
    final points = await controller.toScreenLocationBatch(
      widget.markers.map((marker) => marker.position),
    );
    final projectionScale = _projectionScale;
    return points
        .map(
          (point) => Offset(
            point.x.toDouble() / projectionScale,
            point.y.toDouble() / projectionScale,
          ),
        )
        .toList(growable: false);
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

  Future<void> _openMarkerSheet(_StatisticsMapMarkerData marker) async {
    if (!mounted) {
      return;
    }

    final backgroundColor = _statisticsMapResolvedDrinkIconVisual(
      theme: Theme.of(context),
      entry: marker.entry,
      drinkDefinitionsById: _drinkDefinitionsById,
    ).backgroundColor;
    await _showStatisticsMapEntrySheet(context, marker, backgroundColor);
  }

  @override
  Widget build(BuildContext context) {
    maplibre_web_registration.ensureMapLibreWebRegistered();

    final theme = Theme.of(context);
    final styleString = statisticsMapStyleUrl(theme.brightness);
    final useMapLibre = runtime_platform.isMapLibrePlatformSupported;

    final content = Stack(
      children: <Widget>[
        Positioned.fill(
          child: useMapLibre
              ? maplibre.MapLibreMap(
                  key: ValueKey<String>(
                    '${_statisticsMapSignature(widget.markers)}:'
                    '$styleString:$_markerAssetSignature',
                  ),
                  initialCameraPosition: _statisticsMapInitialCameraPosition(
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
                    _controller?.onFeatureTapped.remove(_featureTapListener);
                    _controller?.onFeatureHover.remove(_featureHoverListener);
                    _controller?.onMapMouseMove.remove(_mapMouseMoveListener);
                    _controller = controller;
                    controller.onFeatureTapped.add(_featureTapListener);
                    controller.onFeatureHover.add(_featureHoverListener);
                    controller.onMapMouseMove.add(_mapMouseMoveListener);
                  },
                  onStyleLoadedCallback: _handleStyleLoaded,
                  onCameraMove: _handleCameraMove,
                )
              : _StatisticsMapFallbackSurface(
                  markers: widget.markers,
                  drinkDefinitionsById: _drinkDefinitionsById,
                ),
        ),
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

    return ClipRect(
      key: const Key('statistics-map-card'),
      child: ColoredBox(color: theme.colorScheme.surface, child: content),
    );
  }
}
