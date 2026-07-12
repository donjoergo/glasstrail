import 'package:flutter/material.dart';

// Non-web platforms have no browser chrome/address bar to theme, so this is
// a pure pass-through that just renders `child` — it exists only so
// callers can use BrowserThemeColorSync unconditionally without checking
// kIsWeb themselves. See browser_theme_color.dart for how this is selected.
class BrowserThemeColorSync extends StatelessWidget {
  const BrowserThemeColorSync({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
