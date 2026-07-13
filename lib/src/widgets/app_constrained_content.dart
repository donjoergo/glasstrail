import 'package:flutter/widgets.dart';

import '../app_breakpoints.dart';

/// Centers and caps content width on expanded (>=840) layouts.
///
/// Below the expanded breakpoint the child is returned unchanged, so
/// mobile layouts keep their edge-to-edge behavior. Place this between a
/// `RefreshIndicator` and its scrollable so pull-to-refresh keeps working.
class AppConstrainedContent extends StatelessWidget {
  const AppConstrainedContent({
    super.key,
    this.maxWidth = AppBreakpoints.formContentMaxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isExpanded(context)) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
