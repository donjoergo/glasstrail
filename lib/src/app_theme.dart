import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const _primary = Color(0xFF2D6A4F);
  static const _secondary = Color(0xFF4D908E);
  static const _tertiary = Color(0xFFE9C46A);

  static ThemeData get lightTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primary,
          secondary: _secondary,
          tertiary: _tertiary,
          surface: const Color(0xFFFFFCF8),
          surfaceContainerHighest: const Color(0xFFE7ECE8),
          onSurface: const Color(0xFF17201A),
          onSurfaceVariant: const Color(0xFF4F5C56),
          outline: const Color(0xFF7C8A84),
          inverseSurface: const Color(0xFF1B241E),
          onInverseSurface: const Color(0xFFF5FBF6),
          error: const Color(0xFFC44536),
        );
    return _buildTheme(
      scheme,
    ).copyWith(scaffoldBackgroundColor: const Color(0xFFF6F7F4));
  }

  static ThemeData get darkTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF82CCA5),
          secondary: const Color(0xFF91D6CF),
          tertiary: _tertiary,
          surface: const Color(0xFF151B18),
          surfaceContainerHighest: const Color(0xFF25302B),
          onSurface: const Color(0xFFF4FBF6),
          onSurfaceVariant: const Color(0xFFD6E2DB),
          outline: const Color(0xFF93A39A),
          inverseSurface: const Color(0xFFE8F1EB),
          onInverseSurface: const Color(0xFF16201A),
          error: const Color(0xFFFF7B72),
        );
    return _buildTheme(
      scheme,
    ).copyWith(scaffoldBackgroundColor: const Color(0xFF0D1210));
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = GoogleFonts.manropeTextTheme(
      ThemeData(
        brightness: scheme.brightness,
        colorScheme: scheme,
        useMaterial3: true,
      ).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: scheme.onSurface),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final color = states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant;
          return textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        secondarySelectedColor: scheme.primary.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
        ),
        brightness: scheme.brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        checkmarkColor: scheme.primary,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll<TextStyle?>(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(color: scheme.primary, width: 1.4);
            }
            return BorderSide(color: scheme.outline.withValues(alpha: 0.6));
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary.withValues(alpha: 0.18);
            }
            return scheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSurface;
            }
            return scheme.onSurfaceVariant;
          }),
        ),
      ),
    );
  }
}
