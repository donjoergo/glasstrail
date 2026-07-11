import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/resizable_master_detail.dart';

void main() {
  const masterKey = Key('rmd-master');
  const detailKey = Key('rmd-detail');
  const dividerKey = Key('rmd-divider');

  Future<void> pumpSplit(
    WidgetTester tester, {
    double defaultMasterWidth = 480,
    double minMasterWidth = 320,
    double maxMasterFraction = 0.6,
  }) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResizableMasterDetail(
            defaultMasterWidth: defaultMasterWidth,
            minMasterWidth: minMasterWidth,
            maxMasterFraction: maxMasterFraction,
            dividerKey: dividerKey,
            master: const SizedBox.expand(key: masterKey),
            detail: const SizedBox.expand(key: detailKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double masterWidth(WidgetTester tester) =>
      tester.getSize(find.byKey(masterKey)).width;

  testWidgets('lays out master at the default width', (tester) async {
    await pumpSplit(tester);

    expect(masterWidth(tester), 480);
    expect(find.byKey(detailKey), findsOneWidget);
  });

  testWidgets('dragging the divider resizes the master pane', (tester) async {
    await pumpSplit(tester);

    await tester.drag(find.byKey(dividerKey), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 540);

    await tester.drag(find.byKey(dividerKey), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 440);
  });

  testWidgets('clamps the dragged width to the minimum', (tester) async {
    await pumpSplit(tester);

    await tester.drag(find.byKey(dividerKey), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(masterWidth(tester), 320);
  });

  testWidgets('clamps the dragged width to the maximum fraction', (
    tester,
  ) async {
    await pumpSplit(tester);

    await tester.drag(find.byKey(dividerKey), const Offset(900, 0));
    await tester.pumpAndSettle();

    expect(masterWidth(tester), 1300 * 0.6);
  });

  testWidgets('follows a changed default width until the user drags', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Widget build(double defaultWidth) {
      return MaterialApp(
        home: Scaffold(
          body: ResizableMasterDetail(
            defaultMasterWidth: defaultWidth,
            dividerKey: dividerKey,
            master: const SizedBox.expand(key: masterKey),
            detail: const SizedBox.expand(key: detailKey),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(480));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 480);

    await tester.pumpWidget(build(560));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 560);
  });

  testWidgets('keeps the dragged width when the default changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Widget build(double defaultWidth) {
      return MaterialApp(
        home: Scaffold(
          body: ResizableMasterDetail(
            defaultMasterWidth: defaultWidth,
            dividerKey: dividerKey,
            master: const SizedBox.expand(key: masterKey),
            detail: const SizedBox.expand(key: detailKey),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(480));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(dividerKey), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 520);

    await tester.pumpWidget(build(560));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 520);
  });

  testWidgets('survives layouts narrower than the minimum master width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResizableMasterDetail(
            defaultMasterWidth: 480,
            dividerKey: dividerKey,
            master: const SizedBox.expand(key: masterKey),
            detail: const SizedBox.expand(key: detailKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 400 * 0.6 = 240 < minMasterWidth (320): the fraction cap wins and
    // the build must not throw a clamp assertion.
    expect(tester.takeException(), isNull);
    expect(masterWidth(tester), 240);
  });

  testWidgets('reverses drag direction in RTL layouts', (tester) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ResizableMasterDetail(
              defaultMasterWidth: 480,
              dividerKey: dividerKey,
              master: const SizedBox.expand(key: masterKey),
              detail: const SizedBox.expand(key: detailKey),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In RTL the master pane sits on the right; dragging the divider to the
    // left makes the master wider.
    await tester.drag(find.byKey(dividerKey), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(masterWidth(tester), 540);
  });
}
