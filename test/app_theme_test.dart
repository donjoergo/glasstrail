import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('dark theme text styles satisfy WCAG contrast on surfaces', (
    tester,
  ) async {
    final theme = await _pumpDarkTheme(tester);
    final scheme = theme.colorScheme;

    expect(
      _contrastRatio(theme.textTheme.bodyLarge!.color!, scheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(theme.textTheme.bodyMedium!.color!, scheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(theme.textTheme.labelLarge!.color!, scheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('dark theme form labels and chip labels satisfy WCAG contrast', (
    tester,
  ) async {
    final theme = await _pumpDarkTheme(tester);
    final scheme = theme.colorScheme;
    final inputFill = theme.inputDecorationTheme.fillColor!;
    final chipBackground = theme.chipTheme.backgroundColor!;
    final chipSelected = Color.alphaBlend(
      theme.chipTheme.selectedColor!,
      scheme.surface,
    );

    expect(
      _contrastRatio(theme.inputDecorationTheme.labelStyle!.color!, inputFill),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(
        theme.inputDecorationTheme.floatingLabelStyle!.color!,
        inputFill,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(theme.chipTheme.labelStyle!.color!, chipBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(theme.chipTheme.secondaryLabelStyle!.color!, chipSelected),
      greaterThanOrEqualTo(4.5),
    );
  });
}

Future<ThemeData> _pumpDarkTheme(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: SizedBox()),
    ),
  );
  await tester.pumpAndSettle();
  return Theme.of(tester.element(find.byType(SizedBox)));
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
