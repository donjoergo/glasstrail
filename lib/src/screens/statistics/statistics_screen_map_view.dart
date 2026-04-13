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
