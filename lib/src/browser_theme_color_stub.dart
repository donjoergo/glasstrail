import 'package:flutter/material.dart';

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
