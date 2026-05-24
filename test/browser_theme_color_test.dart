import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/browser_theme_color_core.dart';

void main() {
  test('browser theme colors use the expected manifest hex values', () {
    expect(browserThemeColorHex(Brightness.light), '#2D6A4F');
    expect(browserThemeColorHex(Brightness.dark), '#151B18');
  });
}
