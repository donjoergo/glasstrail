import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app_breakpoints.dart';

void main() {
  Widget buildProbe(double width, void Function(BuildContext context) onBuild) {
    return MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Builder(
        builder: (context) {
          onBuild(context);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<AppLayoutSize> sizeAtWidth(WidgetTester tester, double width) async {
    late AppLayoutSize size;
    await tester.pumpWidget(
      buildProbe(width, (context) {
        size = AppBreakpoints.sizeOf(context);
      }),
    );
    return size;
  }

  testWidgets('sizeOf maps widths to Material 3 tiers', (tester) async {
    expect(await sizeAtWidth(tester, 320), AppLayoutSize.compact);
    expect(await sizeAtWidth(tester, 599), AppLayoutSize.compact);
    expect(await sizeAtWidth(tester, 600), AppLayoutSize.medium);
    expect(await sizeAtWidth(tester, 839), AppLayoutSize.medium);
    expect(await sizeAtWidth(tester, 840), AppLayoutSize.expanded);
    expect(await sizeAtWidth(tester, 1199), AppLayoutSize.expanded);
    expect(await sizeAtWidth(tester, 1200), AppLayoutSize.large);
    expect(await sizeAtWidth(tester, 2560), AppLayoutSize.large);
  });

  testWidgets('isExpanded is true from 840 upwards', (tester) async {
    Future<bool> isExpandedAtWidth(double width) async {
      late bool value;
      await tester.pumpWidget(
        buildProbe(width, (context) {
          value = AppBreakpoints.isExpanded(context);
        }),
      );
      return value;
    }

    expect(await isExpandedAtWidth(839), isFalse);
    expect(await isExpandedAtWidth(840), isTrue);
    expect(await isExpandedAtWidth(1400), isTrue);
  });

  testWidgets('isLarge is true from 1200 upwards', (tester) async {
    Future<bool> isLargeAtWidth(double width) async {
      late bool value;
      await tester.pumpWidget(
        buildProbe(width, (context) {
          value = AppBreakpoints.isLarge(context);
        }),
      );
      return value;
    }

    expect(await isLargeAtWidth(1199), isFalse);
    expect(await isLargeAtWidth(1200), isTrue);
  });

  test('exposes layout constants used across desktop mode', () {
    expect(AppBreakpoints.medium, 600);
    expect(AppBreakpoints.expanded, 840);
    expect(AppBreakpoints.large, 1200);
    expect(AppBreakpoints.dialogMaxWidth, 560);
    expect(AppBreakpoints.formContentMaxWidth, 640);
    expect(AppBreakpoints.listContentMaxWidth, 840);
    expect(AppBreakpoints.masterPaneWidth, 420);
    expect(AppBreakpoints.mapPanelWidth, 380);
  });
}
