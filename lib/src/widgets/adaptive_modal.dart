import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../app_breakpoints.dart';

/// Shows [builder]'s content as a modal bottom sheet below the expanded
/// breakpoint and as a centered dialog from 840 upwards.
///
/// Pop semantics match in both presentations, so callers can await the
/// returned future regardless of the active layout. Dialogs get Escape
/// handling from the framework for free.
Future<T?> showAdaptiveSheetOrDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
  bool useSafeArea = true,
  double dialogMaxWidth = AppBreakpoints.dialogMaxWidth,
  double dialogMaxHeightFactor = 0.85,
}) {
  if (!AppBreakpoints.isExpanded(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      final maxHeight =
          MediaQuery.sizeOf(dialogContext).height * dialogMaxHeightFactor;
      return Dialog(
        clipBehavior: Clip.antiAlias,
        // PointerInterceptor keeps native wheel/drag events on the dialog
        // instead of platform views underneath (e.g. the MapLibre map).
        child: PointerInterceptor(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogMaxWidth,
              maxHeight: maxHeight,
            ),
            child: builder(dialogContext),
          ),
        ),
      );
    },
  );
}
