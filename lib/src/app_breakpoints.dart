import 'package:flutter/widgets.dart';

/// Material 3 window size classes used by the app.
enum AppLayoutSize { compact, medium, expanded, large }

/// Width breakpoints and shared layout constants for adaptive layouts.
///
/// Follows the Material 3 window size class tiers: compact (<600),
/// medium (600–839), expanded (840–1199), large (>=1200).
class AppBreakpoints {
  const AppBreakpoints._();

  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  static const double dialogMaxWidth = 560;
  static const double formContentMaxWidth = 640;
  static const double listContentMaxWidth = 840;
  static const double masterPaneWidth = 420;
  static const double mapPanelWidth = 380;

  static AppLayoutSize sizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= large) {
      return AppLayoutSize.large;
    }
    if (width >= expanded) {
      return AppLayoutSize.expanded;
    }
    if (width >= medium) {
      return AppLayoutSize.medium;
    }
    return AppLayoutSize.compact;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= large;
}
