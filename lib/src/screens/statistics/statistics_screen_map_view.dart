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
  _StatisticsMapPanelSelection? _panelSelection;
  final FocusNode _panelFocusNode = FocusNode(
    debugLabel: 'statistics-map-panel-focus',
  );
  String? _hoveredMarkerEntryId;
  bool _isWebHoverQueryInFlight = false;
  int _webHoverEpoch = 0;
  math.Point<double>? _pendingWebHoverPoint;
  VoidCallback? _detachWebMouseLeaveListener;
  late double _currentZoom;
  late final maplibre.OnFeatureInteractionCallback _featureTapListener;
  late final maplibre.OnFeatureHoverCallback _featureHoverListener;
  late final maplibre.OnMapMouseMoveCallback _mapMouseMoveListener;

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
      _reconcilePanelSelection();
    }
  }

  void _reconcilePanelSelection() {
    final panelSelection = _panelSelection;
    if (panelSelection == null) {
      return;
    }

    final panelIds = panelSelection.markers
        .map((marker) => marker.entry.id)
        .toSet();
    final remaining = widget.markers
        .where((marker) => panelIds.contains(marker.entry.id))
        .toList(growable: false);
    if (remaining.isEmpty) {
      _panelSelection = null;
      return;
    }

    _StatisticsMapMarkerData? detail;
    final detailId = panelSelection.detail?.entry.id;
    if (detailId != null) {
      final detailIndex = remaining.indexWhere(
        (marker) => marker.entry.id == detailId,
      );
      if (detailIndex != -1) {
        detail = remaining[detailIndex];
      } else if (remaining.length == 1) {
        detail = remaining.single;
      }
    }
    _panelSelection = _StatisticsMapPanelSelection(
      markers: remaining,
      detail: detail,
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
    _panelFocusNode.dispose();
    super.dispose();
  }

  void _openPanel(_StatisticsMapPanelSelection selection) {
    setState(() {
      _panelSelection = selection;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _panelSelection != null) {
        _panelFocusNode.requestFocus();
      }
    });
  }

  void _closePanel() {
    if (_panelSelection == null) {
      return;
    }
    setState(() {
      _panelSelection = null;
    });
    unawaited(_setHoveredMarkerEntryId(null));
  }

  void _showPanelDetail(_StatisticsMapMarkerData marker) {
    final selection = _panelSelection;
    if (selection == null) {
      return;
    }
    setState(() {
      _panelSelection = _StatisticsMapPanelSelection(
        markers: selection.markers,
        detail: marker,
      );
    });
    unawaited(_highlightPanelMarkerOnMap(marker));
  }

  /// Pans/zooms the camera to the selected panel entry and enlarges its
  /// marker so the user sees where the drink was logged.
  Future<void> _highlightPanelMarkerOnMap(
    _StatisticsMapMarkerData marker,
  ) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _setHoveredMarkerEntryId(marker.entry.id);
    await controller.animateCamera(
      maplibre.CameraUpdate.newLatLngZoom(
        marker.position,
        // The detail marker layers only render individual markers from this
        // zoom on; below it the marker would stay hidden inside a cluster.
        math.max(_currentZoom, _statisticsMapDetailMarkerMinZoom),
      ),
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _showPanelList() {
    final selection = _panelSelection;
    if (selection == null) {
      return;
    }
    setState(() {
      _panelSelection = _StatisticsMapPanelSelection(
        markers: selection.markers,
      );
    });
    unawaited(_setHoveredMarkerEntryId(null));
  }

  Future<void> _handleStyleLoaded() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final theme = Theme.of(context);
    final colors = statisticsCategoryColors(theme);
    final markerAssetSignature = _statisticsMapMarkerAssetSignature(
      colors,
      spriteScale: _nativeMarkerSpriteScale,
    );

    await _configureNativeLayers(
      controller,
      theme: theme,
      colors: colors,
      markerAssetSignature: markerAssetSignature,
    );
    _attachWebMouseLeaveListener();
    _setWebCanvasCursor('');
    await _fitStatisticsMapCamera(controller, widget.markers);
  }

  Future<void> _configureNativeLayers(
    maplibre.MapLibreMapController controller, {
    required ThemeData theme,
    required Map<DrinkCategory, Color> colors,
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
      colors: colors,
      markerAssetSignature: markerAssetSignature,
      spriteScale: _nativeMarkerSpriteScale,
    );

    await controller.addSource(
      _statisticsMapClusteredSourceId,
      maplibre.GeojsonSourceProperties(
        data: statisticsMapClusteredSourceGeoJsonForEntries(
          entries: _entries,
          markerAssetSignature: markerAssetSignature,
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
      if (mounted && AppBreakpoints.isLarge(context)) {
        final leafMarkers = await _resolveClusterLeafMarkers(
          controller: controller,
          point: point,
        );
        if (!mounted) {
          return;
        }
        if (leafMarkers.length == 1) {
          await _openMarkerDetail(leafMarkers.single);
          return;
        }
        if (leafMarkers.length > 1) {
          _openPanel(_StatisticsMapPanelSelection(markers: leafMarkers));
          return;
        }
        // Empty or partial resolution — fall back to zooming in.
      }
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
      await _openMarkerDetail(marker);
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

    await _openMarkerDetail(marker);
  }

  Future<List<_StatisticsMapMarkerData>> _resolveClusterLeafMarkers({
    required maplibre.MapLibreMapController controller,
    required math.Point<double> point,
  }) async {
    try {
      final features = await controller.queryRenderedFeatures(point, <String>[
        _statisticsMapClusterCircleLayerId,
      ], null);
      int? pointCount;
      for (final feature in features) {
        if (feature is! Map) {
          continue;
        }
        final properties = feature['properties'];
        if (properties is! Map) {
          continue;
        }
        final rawCount = properties['point_count'];
        if (rawCount is num) {
          pointCount = rawCount.toInt();
          break;
        }
        final parsedCount = int.tryParse(rawCount?.toString() ?? '');
        if (parsedCount != null) {
          pointCount = parsedCount;
          break;
        }
      }
      if (pointCount == null || pointCount < 1) {
        return const <_StatisticsMapMarkerData>[];
      }

      final offsets = await _projectMarkerOffsets(controller);
      final projectionScale = _projectionScale;
      final clusterOffset = Offset(
        point.x / projectionScale,
        point.y / projectionScale,
      );
      final leafIndexes = statisticsMapClusterLeafIndexes(
        offsets: offsets,
        clusterOffset: clusterOffset,
        expectedCount: pointCount,
      );
      if (leafIndexes.length < pointCount) {
        // Partial screen-space match — hiding cluster members would be
        // worse than the zoom fallback, so report no resolution.
        return const <_StatisticsMapMarkerData>[];
      }
      return leafIndexes
          .map((index) => widget.markers[index])
          .toList(growable: false);
    } catch (_) {
      return const <_StatisticsMapMarkerData>[];
    }
  }

  Future<void> _handleFeatureHover(
    math.Point<double> point,
    maplibre.LatLng coordinates,
    String id,
    maplibre.Annotation? annotation,
    maplibre.HoverEventType eventType,
  ) async {
    if (_panelSelection?.detail != null) {
      // The panel detail pins its marker highlight; don't let hover
      // events overwrite it while the detail is shown.
      return;
    }

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
    if (_panelSelection?.detail != null) {
      // The panel detail pins its marker highlight; skip hover queries
      // while the detail is shown so mouse moves don't clear it.
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

  Future<void> _openMarkerDetail(_StatisticsMapMarkerData marker) async {
    if (!mounted) {
      return;
    }

    if (AppBreakpoints.isLarge(context)) {
      _openPanel(
        _StatisticsMapPanelSelection(
          markers: <_StatisticsMapMarkerData>[marker],
          detail: marker,
        ),
      );
      return;
    }

    final colors = statisticsCategoryColors(Theme.of(context));
    final backgroundColor = colors[marker.entry.category]!;
    // The modal blocks map mouse events, so the hover cursor and marker
    // highlight would stay stuck while it is open — reset them first.
    await _setHoveredMarkerEntryId(null);
    if (!mounted) {
      return;
    }
    await _showStatisticsMapEntrySheet(context, marker, backgroundColor);
  }

  @override
  Widget build(BuildContext context) {
    maplibre_web_registration.ensureMapLibreWebRegistered();

    final theme = Theme.of(context);
    final colors = statisticsCategoryColors(theme);
    final styleString = statisticsMapStyleUrl(theme.brightness);
    final markerAssetSignature = _statisticsMapMarkerAssetSignature(
      colors,
      spriteScale: _nativeMarkerSpriteScale,
    );
    final useMapLibre = runtime_platform.isMapLibrePlatformSupported;

    final content = Stack(
      children: <Widget>[
        Positioned.fill(
          child: useMapLibre
              ? maplibre.MapLibreMap(
                  key: ValueKey<String>(
                    '${_statisticsMapSignature(widget.markers)}:'
                    '$styleString:$markerAssetSignature',
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
                  onMapClick: (point, coordinates) => _closePanel(),
                )
              : _StatisticsMapFallbackSurface(
                  markers: widget.markers,
                  colors: colors,
                  onMarkerTap: _openMarkerDetail,
                  onBackgroundTap: _closePanel,
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
        if (_panelSelection != null)
          PositionedDirectional(
            top: 16,
            end: 16,
            bottom:
                AppScope.controllerOf(context).settings.handedness ==
                    AppHandedness.left
                ? 16
                : 96, // Clear the floating action button on the trailing side.
            width: AppBreakpoints.mapPanelWidth,
            child: Align(
              alignment: Alignment.topCenter,
              // PointerInterceptor keeps native wheel/drag events on the
              // panel instead of the MapLibre platform view underneath.
              child: PointerInterceptor(
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.escape):
                        _closePanel,
                  },
                  child: Focus(
                    focusNode: _panelFocusNode,
                    child: _StatisticsMapEntryPanel(
                      selection: _panelSelection!,
                      onClose: _closePanel,
                      onDetailSelected: _showPanelDetail,
                      onBackToList: _showPanelList,
                    ),
                  ),
                ),
              ),
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
