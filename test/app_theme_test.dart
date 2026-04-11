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
    final theme = await _pumpTheme(tester, AppTheme.darkTheme);
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

  testWidgets('destructive action styles use error colors in both themes', (
    tester,
  ) async {
    for (final themeData in <ThemeData>[
      AppTheme.lightTheme,
      AppTheme.darkTheme,
    ]) {
      final theme = await _pumpTheme(tester, themeData);
      final scheme = theme.colorScheme;

      final textStyle = AppTheme.destructiveTextButtonStyle(scheme);
      final outlinedStyle = AppTheme.destructiveOutlinedButtonStyle(scheme);
      final filledStyle = AppTheme.destructiveFilledButtonStyle(scheme);
      final iconStyle = AppTheme.destructiveIconButtonStyle(scheme);

      expect(textStyle.foregroundColor?.resolve(<WidgetState>{}), scheme.error);
      expect(
        outlinedStyle.foregroundColor?.resolve(<WidgetState>{}),
        scheme.error,
      );
      expect(
        outlinedStyle.side?.resolve(<WidgetState>{}),
        BorderSide(color: scheme.error.withValues(alpha: 0.72)),
      );
      expect(
        filledStyle.backgroundColor?.resolve(<WidgetState>{}),
        scheme.error,
      );
      expect(
        filledStyle.foregroundColor?.resolve(<WidgetState>{}),
        scheme.onError,
      );
      expect(iconStyle.foregroundColor?.resolve(<WidgetState>{}), scheme.error);
      expect(AppTheme.destructiveMenuTextStyle(theme).color, scheme.error);
    }
  });
}

Future<ThemeData> _pumpDarkTheme(WidgetTester tester) =>
    _pumpTheme(tester, AppTheme.darkTheme);

Future<ThemeData> _pumpTheme(WidgetTester tester, ThemeData themeData) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: themeData,
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
