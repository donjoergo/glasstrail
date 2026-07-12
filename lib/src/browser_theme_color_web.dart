import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'browser_theme_color_core.dart';

// Keeps the browser's address-bar/PWA theme-color meta tag in sync with the
// app's current brightness (e.g. Flutter theme follows system dark mode),
// so the surrounding browser chrome matches the app instead of staying a
// fixed color. Needs State (not Stateless, unlike the stub) because it must
// react to brightness changes after the widget is already built via
// didUpdateWidget, not just once at construction.
class BrowserThemeColorSync extends StatefulWidget {
  const BrowserThemeColorSync({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  State<BrowserThemeColorSync> createState() => _BrowserThemeColorSyncState();
}

class _BrowserThemeColorSyncState extends State<BrowserThemeColorSync> {
  @override
  void initState() {
    super.initState();
    _syncThemeColor();
  }

  @override
  void didUpdateWidget(covariant BrowserThemeColorSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      _syncThemeColor();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _syncThemeColor() {
    final head = web.document.head;
    if (head == null) {
      return;
    }
    // Reuse an existing <meta name="theme-color"> tag if the host HTML
    // (index.html) already declares one, rather than creating a duplicate
    // that could conflict with it; only create+append a new element when
    // none exists yet.
    final existingMeta = web.document.querySelector('meta[name="theme-color"]');
    final meta =
        existingMeta != null
              ? existingMeta as web.HTMLMetaElement
              : web.HTMLMetaElement()
          ..name = 'theme-color';
    meta.content = browserThemeColorHex(widget.brightness);
    if (meta.parentNode == null) {
      head.appendChild(meta);
    }
  }
}
