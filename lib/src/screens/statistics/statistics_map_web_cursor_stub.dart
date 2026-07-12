import 'package:flutter/foundation.dart';

// No-op fallback for non-web platforms: MapLibre there is a native view
// with its own hit-testing/cursor handling, so there's no DOM element to
// hook a mouseleave listener into or restyle.
VoidCallback? attachStatisticsMapWebMouseLeaveListener(VoidCallback onLeave) {
  return null;
}

void setStatisticsMapWebCursor(String cursor) {}
