import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/adaptive_modal.dart';

void main() {
  Future<void> pumpHost(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const Key('open-modal-button'),
                onPressed: () {
                  showAdaptiveSheetOrDialog<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) =>
                        const SizedBox(key: Key('modal-content'), height: 200),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-modal-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a bottom sheet below the expanded breakpoint', (
    tester,
  ) async {
    await pumpHost(tester, size: const Size(400, 800));

    expect(find.byKey(const Key('modal-content')), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('shows a centered dialog from the expanded breakpoint', (
    tester,
  ) async {
    await pumpHost(tester, size: const Size(900, 800));

    expect(find.byKey(const Key('modal-content')), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    final contentSize = tester.getSize(find.byKey(const Key('modal-content')));
    expect(contentSize.width, lessThanOrEqualTo(560));
  });

  testWidgets('closes the dialog with escape', (tester) async {
    await pumpHost(tester, size: const Size(900, 800));

    expect(find.byKey(const Key('modal-content')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('modal-content')), findsNothing);
  });
}
