import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:maplibre_gl_web/maplibre_gl_web.dart' as maplibre_web;

// maplibre_gl_web's platform view chokes on a couple of options that only
// make sense for the native SDKs, so they must be stripped before any
// creation/update call reaches the underlying web controller.
class _GlasstrailMapLibreWebController
    extends maplibre_web.MapLibreMapController {
  static Map<String, dynamic> _sanitizeOptions(Map<String, dynamic> options) {
    final sanitized = Map<String, dynamic>.from(options);
    // Native-only render mode enum the web plugin can't decode.
    sanitized.remove('myLocationRenderMode');
    // Native-only margin type the web plugin can't decode.
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

  // Both the initial view creation and any later options update carry the
  // same unsupported keys, so both call paths route through sanitization.
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

// Swaps in the sanitizing controller before any MapLibre widget is built,
// so every web map instance gets the option fixups automatically.
void ensureMapLibreWebRegistered() {
  maplibre.MapLibrePlatform.createInstance = () =>
      _GlasstrailMapLibreWebController();
}
