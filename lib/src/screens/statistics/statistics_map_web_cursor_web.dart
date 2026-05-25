import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

List<web.HTMLElement> _statisticsMapWebCursorElements() {
  return <web.Element?>[
    web.document.querySelector('flt-platform-view'),
    web.document.querySelector('.maplibregl-map'),
    web.document.querySelector('.maplibregl-canvas-container'),
    web.document.querySelector('.maplibregl-canvas'),
  ].whereType<web.HTMLElement>().toList(growable: false);
}

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

void setStatisticsMapWebCursor(String cursor) {
  for (final element in _statisticsMapWebCursorElements()) {
    element.style.cursor = cursor;
  }
}
