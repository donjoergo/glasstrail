import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const _primary = Color(0xFF2D6A4F);
  static const _secondary = Color(0xFF4D908E);
  static const _tertiary = Color(0xFFE9C46A);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
      surface: Colors.white,
      error: const Color(0xFFC44536),
    );
    return _buildTheme(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7F4),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF68B38D),
      secondary: const Color(0xFF73BBB3),
      tertiary: _tertiary,
      surface: const Color(0xFF182028),
      error: const Color(0xFFFF7B72),
    );
    return _buildTheme(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF101418),
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = GoogleFonts.manropeTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
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
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
      ),
    );
  }
}
