import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/app_constrained_content.dart';

void main() {
  Future<Size> pumpAndMeasureChild(
    WidgetTester tester, {
    required double screenWidth,
    double maxWidth = 640,
  }) async {
    tester.view.physicalSize = Size(screenWidth, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppConstrainedContent(
            maxWidth: maxWidth,
            child: const SizedBox.expand(key: Key('constrained-child')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester.getSize(find.byKey(const Key('constrained-child')));
  }

  testWidgets('caps and centers the child from the expanded breakpoint', (
    tester,
  ) async {
    final childSize = await pumpAndMeasureChild(tester, screenWidth: 1000);

    expect(childSize.width, 640);

    final childRect = tester.getRect(
      find.byKey(const Key('constrained-child')),
    );
    expect(childRect.left, (1000 - 640) / 2);
  });

  testWidgets('leaves the child unconstrained below the expanded breakpoint', (
    tester,
  ) async {
    final childSize = await pumpAndMeasureChild(tester, screenWidth: 830);

    expect(childSize.width, 830);
  });

  testWidgets('honors a custom max width', (tester) async {
    final childSize = await pumpAndMeasureChild(
      tester,
      screenWidth: 1400,
      maxWidth: 840,
    );

    expect(childSize.width, 840);
  });
}
