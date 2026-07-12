import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

// MapLibre GL JS renders into nested DOM elements on top of (and inside)
// Flutter's platform view, so cursor styling and mouseleave detection have
// to be applied to several selectors — querying just the canvas would miss
// pointer exits that happen over the surrounding container/platform view.
List<web.HTMLElement> _statisticsMapWebCursorElements() {
  return <web.Element?>[
    web.document.querySelector('flt-platform-view'),
    web.document.querySelector('.maplibregl-map'),
    web.document.querySelector('.maplibregl-canvas-container'),
    web.document.querySelector('.maplibregl-canvas'),
  ].whereType<web.HTMLElement>().toList(growable: false);
}

// Flutter web has no cross-platform "pointer left the map" event for a
// platform view, so we attach a native DOM mouseleave listener directly
// and hand back a detach closure for disposal.
VoidCallback? attachStatisticsMapWebMouseLeaveListener(VoidCallback onLeave) {
  final elements = _statisticsMapWebCursorElements();
  if (elements.isEmpty) {
    return null;
  }

  final listener = ((web.Event event) {
    onLeave();
  }).toJS;
  for (final element in elements) {
    element.addEventListener('mouseleave', listener);
  }
  return () {
    for (final element in elements) {
      element.removeEventListener('mouseleave', listener);
    }
  };
}

// MapLibre doesn't expose a cursor API of its own on web, so hover feedback
// (e.g. pointer over a marker) is done by writing the CSS cursor style
// straight onto the underlying DOM elements.
void setStatisticsMapWebCursor(String cursor) {
  for (final element in _statisticsMapWebCursorElements()) {
    element.style.cursor = cursor;
  }
}
