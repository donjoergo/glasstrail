import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:maplibre_gl_web/maplibre_gl_web.dart' as maplibre_web;

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
  maplibre.MapLibrePlatform.createInstance = () =>
      _GlasstrailMapLibreWebController();
}
