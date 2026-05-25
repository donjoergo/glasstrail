import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'browser_theme_color_core.dart';

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
