import 'package:flutter/material.dart';

import 'app_theme.dart';

// Kept separate from browser_theme_color_web.dart so the hex-formatting
// logic (platform-independent) can be shared/imported by both the web
// implementation and, if needed, tests without dragging in dart:js_interop
// or package:web, which are only available on web builds.
String browserThemeColorHex(Brightness brightness) {
  final color = AppTheme.browserThemeColorForBrightness(brightness);
  // Mask off the alpha channel: the <meta name="theme-color"> tag expects a
  // plain #RRGGBB hex color, which has no alpha component.
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
