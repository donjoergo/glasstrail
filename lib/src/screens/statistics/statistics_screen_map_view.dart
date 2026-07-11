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
  // Web hover is resolved via an async queryRenderedFeatures round-trip, so
  // mouse-move events can arrive faster than queries resolve. These fields
  // coalesce bursts of moves into "at most one query in flight, plus the
  // latest pending point" instead of firing a query per event.
  bool _isWebHoverQueryInFlight = false;
  // Bumped whenever hover state is invalidated (e.g. the pointer leaves the
  // map) so that a query response that resolves after invalidation can
  // detect it's stale and be discarded instead of reviving old hover state.
  int _webHoverEpoch = 0;
  math.Point<double>? _pendingWebHoverPoint;
  VoidCallback? _detachWebMouseLeaveListener;
  late double _currentZoom;
  late final maplibre.OnFeatureInteractionCallback _featureTapListener;
  late final maplibre.OnFeatureHoverCallback _featureHoverListener;
  late final maplibre.OnMapMouseMoveCallback _mapMouseMoveListener;

  double get _nativeMarkerIconSize => 1;

  // Android's MapLibre plugin renders sprite images at logical (not device)
  // pixels, so on high-DPI Android devices the sprite bitmap must be
  // pre-scaled by the device pixel ratio to stay crisp; other platforms
  // already account for DPI themselves.
  double get _nativeMarkerSpriteScale {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MediaQuery.devicePixelRatioOf(context);
    }
    return 1;
  }

  // Mirrors the sprite scale quirk above: on Android, screen coordinates
  // returned by toScreenLocationBatch come back in device pixels while
  // Flutter's Offset/tap coordinates are logical pixels, so they must be
  // divided back down to compare correctly. Web and other native platforms
  // don't have this mismatch.
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
    // Bound once and kept as stable `late final` tear-offs (not inline
    // closures) because MapLibre's listener lists remove by reference
    // equality in dispose(); a freshly created closure there wouldn't match
    // what was added in onMapCreated.
    _featureTapListener = _handleFeatureTap;
    _featureHoverListener = _handleFeatureHover;
    _mapMouseMoveListener = _handleMapMouseMove;
  }

  @override
  void didUpdateWidget(covariant _StatisticsMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // widget.markers is a freshly built list on every parent rebuild, so
    // list identity can't be used to detect real changes — compare the
    // marker signature (entry ids + rounded positions) instead.
    if (_statisticsMapSignature(oldWidget.markers) !=
        _statisticsMapSignature(widget.markers)) {
      _currentZoom = _statisticsMapInitialCameraPosition(widget.markers).zoom;
      // Drop hover state referencing a marker that no longer exists (e.g.
      // its entry was deleted) so a stale hover filter/cursor doesn't stick.
      if (_hoveredMarkerEntryId != null &&
          !widget.markers.any(
            (marker) => marker.entry.id == _hoveredMarkerEntryId,
          )) {
        _hoveredMarkerEntryId = null;
      }
    }
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

  // Called every time the map (re)loads its style — including when the
  // ValueKey in build() changes the style URL for a theme switch — so all
  // custom sources/layers/images have to be torn down and rebuilt from
  // scratch here; MapLibre doesn't carry them across style reloads.
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

    // Layers must be removed before the sources they reference — MapLibre
    // refuses to remove a source that's still in use by a layer — and both
    // removals are best-effort since on a fresh style load none of these
    // exist yet.
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

    // Two parallel sources cover the two zoom regimes: the clustered source
    // (with MapLibre's built-in `cluster: true`) drives low-zoom clusters
    // and lone markers, while the detail source — with entries fanned out
    // at shared coordinates — takes over above _statisticsMapDetailMarkerMinZoom
    // via each layer's minzoom/maxzoom so only one is ever visible.
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
        // Step expression: circle grows in three visible tiers (small/
        // medium/large point counts) so users get a rough sense of cluster
        // size at a glance without reading the exact count label.
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
    // A separate, larger-scaled symbol layer filtered to just the hovered
    // entry id — rather than a data-driven paint expression on the base
    // layer — because this plugin's SymbolLayerProperties don't support
    // per-feature interactive state, so "highlight on hover" is faked by
    // toggling which feature this extra layer's filter matches.
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

    // Tapping a MapLibre-generated cluster has no individual entry to open,
    // so the only sensible action is to zoom in on it — MapLibre doesn't
    // expose the cluster's child count/expansion zoom here, so we just step
    // by a fixed amount instead of computing an exact "expand" zoom.
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
    // Low-zoom (clustered-source) single markers are always distinct real
    // locations by construction, so there's nothing to disambiguate — open
    // the sheet directly.
    if (layerId == _statisticsMapLowZoomMarkerLayerId ||
        layerId == _statisticsMapLowZoomMarkerHitLayerId) {
      await _openMarkerSheet(marker);
      return;
    }

    if (layerId != _statisticsMapDetailMarkerLayerId &&
        layerId != _statisticsMapDetailMarkerHitLayerId) {
      return;
    }

    // Detail-source markers can be fanned-out siblings that still overlap
    // on screen at the current zoom; project them to screen space to check
    // for that before deciding whether to open a sheet or zoom in further.
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

    // Only clear the hover if the "leave" is for the currently hovered
    // feature. Enter/leave events for adjacent overlapping markers can
    // arrive out of order (e.g. entering B before A's leave is processed),
    // and unconditionally clearing on any leave would flicker off a still
    // relevant hover.
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

  // On web, MapLibre GL JS's onFeatureHover doesn't reliably fire per
  // feature the way native does, so hover is instead derived by querying
  // rendered features at the raw mouse position on every move.
  Future<void> _handleMapMouseMove(
    math.Point<double> point,
    maplibre.LatLng coordinates,
  ) async {
    if (!kIsWeb || !runtime_platform.isMapLibrePlatformSupported) {
      return;
    }

    final epoch = _webHoverEpoch;
    // Drop (don't queue) intermediate moves while a query is in flight —
    // only the latest point matters, and queuing every move would make
    // hover resolution lag behind the actual cursor during fast movement.
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
      // Only chase the queued point if this epoch is still current — if the
      // pointer left the map (or the widget was disposed) while this query
      // was in flight, there's nothing left to resolve hover against.
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
      // Query both the visible icon layers and their invisible larger hit
      // layers, since the actual cursor position is more likely to land
      // inside the generous hit target than the small icon glyph itself.
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
        // Guard against a query resolving against a stale rendered source
        // (e.g. entries changed but the style hasn't finished reconfiguring
        // yet) by only accepting ids that are in the current marker set.
        if (widget.markers.any((marker) => marker.entry.id == entryId)) {
          nextHoveredEntryId = entryId;
          break;
        }
      }
    } catch (_) {
      // Ignore transient rendered-feature query failures during hover.
    }

    // The epoch may have advanced (pointer already left, or another hover
    // interaction started) while this async query was pending; applying a
    // now-stale result would incorrectly resurrect hover state.
    if (!mounted || epoch != _webHoverEpoch) {
      return;
    }
    await _setHoveredMarkerEntryId(nextHoveredEntryId);
  }

  Future<void> _handleWebMouseExit() async {
    // Invalidates any in-flight or queued hover query so it can't overwrite
    // the "not hovering" state this triggers.
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

    // This can run after the widget is disposed (e.g. a query resolves
    // during teardown), so avoid calling setState off-tree — still update
    // the field directly so any late cleanup (like the cursor reset) sees
    // consistent state.
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
    // Fast path: for most layers the callback's feature id already matches
    // an entry id directly.
    final directIndex = widget.markers.indexWhere(
      (marker) => marker.entry.id == featureId,
    );
    if (directIndex != -1) {
      return directIndex;
    }

    // Fallback for layers/platforms where the reported feature id is an
    // internal MapLibre id rather than the GeoJSON `entryId` property (e.g.
    // circle hit layers) — look the real entry id up via a rendered-feature
    // query instead.
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

  // Hover highlighting is a pointer-device affordance; touch-based native
  // platforms have no hover concept, so skip the extra setFilter round
  // trips there entirely rather than pointlessly maintaining hover layers
  // that will never show anything different.
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
      // A group of fanned-out markers at the same venue has a near-zero
      // bounding box; fitting the camera to that would zoom in far too
      // aggressively (or misbehave), so fall through to a plain zoom-step
      // on the average position instead.
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

    final colors = statisticsCategoryColors(Theme.of(context));
    final backgroundColor = colors[marker.entry.category]!;
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
                  // Combining marker set, style URL and asset signature into
                  // one key forces MapLibreMap (and its native platform
                  // view) to be fully recreated whenever any of them
                  // changes, since the plugin doesn't support hot-swapping
                  // the style/camera/sources of a live map instance cleanly.
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
                    // Defensively detach from any previous controller first
                    // — because of the ValueKey above, onMapCreated can fire
                    // again with a new controller for the same State object,
                    // and without this the old controller's listener list
                    // would keep a dangling reference.
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
                  colors: colors,
                ),
        ),
        // Only needed for the fallback surface: the real MapLibreMap already
        // renders its own attribution control (attributionButtonPosition
        // above), so adding this too would duplicate the required
        // OSM/CARTO attribution.
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
