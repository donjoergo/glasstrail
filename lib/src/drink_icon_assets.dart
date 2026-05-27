import 'package:flutter/material.dart';

import 'models.dart';

const _drinkIconAssetDirectory = 'assets/drink_icons';

class BuiltInDrinkIconSpec {
  const BuiltInDrinkIconSpec({
    required this.assetPath,
    required this.accentColorHex,
  });

  final String assetPath;
  final String accentColorHex;
}

class ResolvedDrinkIconVisual {
  const ResolvedDrinkIconVisual({
    required this.backgroundColor,
    required this.foregroundColor,
    this.builtInAssetPath,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String? builtInAssetPath;
}

const Map<String, String> _builtInDrinkAccentColorHexes = <String, String>{
  'beer-pils': '#E3A008',
  'beer-classic': '#D97706',
  'beer-can': '#F59E0B',
  'beer-helles': '#FBBF24',
  'beer-weizen': '#C0841A',
  'beer-kellerbier': '#B45309',
  'beer-kölsch': '#FCD34D',
  'beer-alt': '#92400E',
  'beer-ipa': '#C2410C',
  'beer-goassmass': '#7C2D12',
  'beer-mass': '#B7791F',
  'beer-stout': '#5B3716',
  'beer-radler': '#CA8A04',
  'beer-non-alcoholic': '#84CC16',
  'wine-red-wine': '#9F1239',
  'wine-white-wine': '#D4A017',
  'wine-rosé-wine': '#F472B6',
  'wine-aperol-spritz': '#F97316',
  'wine-mulled-wine': '#7F1D1D',
  'wine-wine-spritzer': '#0F766E',
  'wine-spritzer': '#14B8A6',
  'wine-sangria': '#B91C1C',
  'wine-sparkling-wine': '#D6A419',
  'sparklingWines-champagne': '#EAB308',
  'longdrinks-cuba-libre': '#4338CA',
  'longdrinks-gin-tonic': '#0F766E',
  'longdrinks-jacki-cola': '#7C3AED',
  'longdrinks-vodka-o': '#0284C7',
  'longdrinks-vodka-bull': '#2563EB',
  'longdrinks-longdrink': '#0891B2',
  'spirits-vodka': '#475569',
  'spirits-gin': '#0F766E',
  'spirits-rum': '#7C2D12',
  'spirits-whiskey': '#92400E',
  'spirits-cognac': '#B45309',
  'shots-shot': '#EA580C',
  'shots-jaegermeister': '#65A30D',
  'shots-berliner-luft': '#0EA5E9',
  'shots-pfeffi': '#10B981',
  'shots-ficken': '#DC2626',
  'spirits-tequila': '#CA8A04',
  'shots-limoncello': '#EAB308',
  'cocktails-mojito': '#16A34A',
  'cocktails-margarita': '#22C55E',
  'cocktails-martini': '#DB2777',
  'cocktails-cocktail': '#EC4899',
  'cocktails-caipirinha': '#65A30D',
  'appleWines-hard-seltzer': '#14B8A6',
  'appleWines-apple-wine': '#84CC16',
  'appleWines-cider': '#A3A300',
  'nonAlcoholic-water': '#0EA5E9',
  'nonAlcoholic-juice': '#F97316',
  'nonAlcoholic-sparkling-water': '#38BDF8',
  'nonAlcoholic-tea': '#A16207',
  'nonAlcoholic-mate-tea': '#ffb682',
  'nonAlcoholic-club-mate': '#B7791F',
  'nonAlcoholic-coffee': '#6F4E37',
  'nonAlcoholic-energy-drink': '#EF4444',
  'nonAlcoholic-cola': '#7C2D12',
  'nonAlcoholic-lemonade': '#EAB308',
};

BuiltInDrinkIconSpec? builtInDrinkIconSpec(String drinkId) {
  final normalized = drinkId.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final accentColorHex = _builtInDrinkAccentColorHexes[normalized];
  if (accentColorHex == null) {
    return null;
  }
  return BuiltInDrinkIconSpec(
    assetPath: '$_drinkIconAssetDirectory/$normalized.png',
    accentColorHex: accentColorHex,
  );
}

String? builtInDrinkIconAssetPath(String drinkId) {
  return builtInDrinkIconSpec(drinkId)?.assetPath;
}

String? builtInDrinkAccentColorHex(String drinkId) {
  return builtInDrinkIconSpec(drinkId)?.accentColorHex;
}

Map<DrinkCategory, Color> drinkCategoryAccentColors(ThemeData theme) {
  return <DrinkCategory, Color>{
    DrinkCategory.beer: theme.colorScheme.primary,
    DrinkCategory.wine: theme.colorScheme.secondary,
    DrinkCategory.sparklingWines: theme.colorScheme.secondaryContainer,
    DrinkCategory.longdrinks: theme.colorScheme.tertiaryContainer,
    DrinkCategory.spirits: theme.colorScheme.tertiary,
    DrinkCategory.shots: theme.colorScheme.errorContainer,
    DrinkCategory.cocktails: theme.colorScheme.error,
    DrinkCategory.appleWines: theme.colorScheme.surfaceContainerHighest,
    DrinkCategory.nonAlcoholic: theme.colorScheme.primaryContainer,
  };
}

Color drinkCategoryAccentColor(DrinkCategory category, ThemeData theme) {
  return drinkCategoryAccentColors(theme)[category]!;
}

String? normalizeDrinkAccentColorHex(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(trimmed);
  if (match == null) {
    return null;
  }
  return '#${match.group(1)!.toUpperCase()}';
}

Color? drinkAccentColorFromHex(String? value) {
  final normalized = normalizeDrinkAccentColorHex(value);
  if (normalized == null) {
    return null;
  }
  final rgbValue = int.parse(normalized.substring(1), radix: 16);
  return Color(0xFF000000 | rgbValue);
}

Color drinkIconForegroundColor(Color backgroundColor) {
  final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

ResolvedDrinkIconVisual resolveDrinkIconVisual({
  required ThemeData theme,
  required String drinkId,
  required DrinkCategory category,
  String? accentColorHex,
}) {
  final builtInSpec = builtInDrinkIconSpec(drinkId);
  final backgroundColor =
      drinkAccentColorFromHex(accentColorHex) ??
      drinkAccentColorFromHex(builtInSpec?.accentColorHex) ??
      drinkCategoryAccentColor(category, theme);
  return ResolvedDrinkIconVisual(
    backgroundColor: backgroundColor,
    foregroundColor: drinkIconForegroundColor(backgroundColor),
    builtInAssetPath: builtInSpec?.assetPath,
  );
}
