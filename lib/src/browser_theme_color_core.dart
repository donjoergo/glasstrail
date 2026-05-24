import 'package:flutter/material.dart';

import 'app_theme.dart';

String browserThemeColorHex(Brightness brightness) {
  final color = AppTheme.browserThemeColorForBrightness(brightness);
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
