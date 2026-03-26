import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:maplibre_gl_web/maplibre_gl_web.dart' as maplibre_web;

const double _statisticsMapWebTrackpadZoomRate = 1 / 40;
const double _statisticsMapWebWheelZoomRate = 1 / 180;

bool _didPatchScrollZoomHandler = false;

void _ensureFastWebScrollZoom() {
  if (_didPatchScrollZoomHandler) {
    return;
  }

  final mapLibreGlobal = js_util.getProperty<Object?>(
    js_util.globalThis,
    'maplibregl',
  );
  if (mapLibreGlobal == null) {
    return;
  }

  final scrollZoomHandler = js_util.getProperty<Object?>(
    mapLibreGlobal,
    'ScrollZoomHandler',
  );
  if (scrollZoomHandler == null) {
    return;
  }

  final prototype = js_util.getProperty<Object?>(
    scrollZoomHandler,
    'prototype',
  );
  if (prototype == null) {
    return;
  }

  final originalEnable = js_util.getProperty<Object?>(
    prototype,
    'enable',
  );
  if (originalEnable == null) {
    return;
  }

  js_util.setProperty(prototype, '__glasstrailFastZoomPatched', true);
  js_util.setProperty(
    prototype,
    'enable',
    js_util.allowInteropCaptureThis((Object thisArg, [Object? options]) {
      final result = js_util.callMethod<Object?>(
        originalEnable,
        'call',
        <Object?>[thisArg, options],
      );
      js_util.callMethod<void>(
        thisArg,
        'setZoomRate',
        <Object>[_statisticsMapWebTrackpadZoomRate],
      );
      js_util.callMethod<void>(
        thisArg,
        'setWheelZoomRate',
        <Object>[_statisticsMapWebWheelZoomRate],
      );
      return result;
    }),
  );

  _didPatchScrollZoomHandler = true;
}

class _GlasstrailMapLibreWebController
    extends maplibre_web.MapLibreMapController {
  static Map<String, dynamic> _sanitizeOptions(Map<String, dynamic> options) {
    final sanitized = Map<String, dynamic>.from(options);
    sanitized.remove('myLocationRenderMode');
    sanitized.remove('attributionButtonMargins');
    return sanitized;
  }

  static Map<String, dynamic> _sanitizeCreationParams(
    Map<String, dynamic> creationParams,
  ) {
    final sanitized = Map<String, dynamic>.from(creationParams);
    final options = creationParams['options'];
    if (options is Map) {
      sanitized['options'] = _sanitizeOptions(
        Map<String, dynamic>.from(options.cast<Object?, Object?>()),
      );
    }
    return sanitized;
  }

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    maplibre.OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    return super.buildView(
      _sanitizeCreationParams(creationParams),
      onPlatformViewCreated,
      gestureRecognizers,
    );
  }

  @override
  Future<maplibre.CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) {
    return super.updateMapOptions(_sanitizeOptions(optionsUpdate));
  }
}

void ensureMapLibreWebRegistered() {
  _ensureFastWebScrollZoom();
  maplibre.MapLibrePlatform.createInstance = () =>
      _GlasstrailMapLibreWebController();
}
