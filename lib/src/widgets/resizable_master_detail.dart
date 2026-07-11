import 'package:flutter/material.dart';

/// A master/detail split with a draggable divider.
///
/// The master pane starts at [defaultMasterWidth] and keeps following it
/// (e.g. across breakpoint changes) until the user drags the divider; from
/// then on the dragged width wins for the rest of the session. The width is
/// clamped to [minMasterWidth] and [maxMasterFraction] of the available
/// width.
class ResizableMasterDetail extends StatefulWidget {
  const ResizableMasterDetail({
    super.key,
    required this.defaultMasterWidth,
    required this.master,
    required this.detail,
    this.dividerKey,
    this.minMasterWidth = 320,
    this.maxMasterFraction = 0.6,
  });

  final double defaultMasterWidth;
  final Widget master;
  final Widget detail;
  final Key? dividerKey;
  final double minMasterWidth;
  final double maxMasterFraction;

  @override
  State<ResizableMasterDetail> createState() => _ResizableMasterDetailState();
}

class _ResizableMasterDetailState extends State<ResizableMasterDetail> {
  double? _draggedWidth;

  double _clampedMasterWidth(double totalWidth) {
    final maxWidth = totalWidth * widget.maxMasterFraction;
    final width = _draggedWidth ?? widget.defaultMasterWidth;
    return width.clamp(widget.minMasterWidth, maxWidth);
  }

  void _handleDragUpdate(DragUpdateDetails details, double totalWidth) {
    final directionFactor = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    setState(() {
      _draggedWidth =
          _clampedMasterWidth(totalWidth) +
          (details.delta.dx * directionFactor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final masterWidth = _clampedMasterWidth(totalWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: masterWidth, child: widget.master),
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                key: widget.dividerKey,
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) =>
                    _handleDragUpdate(details, totalWidth),
                child: SizedBox(
                  width: 10,
                  child: Center(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: widget.detail),
          ],
        );
      },
    );
  }
}
