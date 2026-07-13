import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import 'models.dart';

extension AppLocalizationsX on AppLocalizations {
  Locale get locale => Locale(localeName);

  String categoryLabel(DrinkCategory category) => switch (category) {
    DrinkCategory.beer => beer,
    DrinkCategory.wine => wine,
    DrinkCategory.sparklingWines => sparklingWines,
    DrinkCategory.longdrinks => longdrinks,
    DrinkCategory.spirits => spirits,
    DrinkCategory.shots => shots,
    DrinkCategory.cocktails => cocktails,
    DrinkCategory.appleWines => appleWines,
    DrinkCategory.nonAlcoholic => nonAlcoholic,
  };

  String drinkDefinitionMetadata(DrinkDefinition drink, AppUnit unit) {
    return <String>[
      categoryLabel(drink.category),
      if (drink.shouldShowAlcoholFreeMarker) alcoholFree,
      if (drink.volumeMl != null) unit.formatVolume(drink.volumeMl),
    ].join(' • ');
  }

  String drinkEntryMetadata(DrinkEntry entry, AppUnit unit) {
    return <String>[
      categoryLabel(entry.category),
      if (entry.shouldShowAlcoholFreeMarker) alcoholFree,
      if (entry.volumeMl != null) unit.formatVolume(entry.volumeMl),
    ].join(' • ');
  }

  String themeLabel(AppThemePreference preference) => switch (preference) {
    AppThemePreference.system => themeSystem,
    AppThemePreference.light => themeLight,
    AppThemePreference.dark => themeDark,
  };

  // Unit symbols ("ml"/"oz") are identical across supported locales, so the
  // raw enum name doubles as the display label without needing a
  // localization entry.
  String unitLabel(AppUnit unit) => unit.name;

  String weekdayShortLabel(int weekday) => switch (weekday) {
    DateTime.monday => weekdayMondayShort,
    DateTime.tuesday => weekdayTuesdayShort,
    DateTime.wednesday => weekdayWednesdayShort,
    DateTime.thursday => weekdayThursdayShort,
    DateTime.friday => weekdayFridayShort,
    DateTime.saturday => weekdaySaturdayShort,
    DateTime.sunday => weekdaySundayShort,
    // DateTime.weekday is always 1-7, so this is unreachable in practice —
    // kept as a safe default rather than throwing if that ever changes.
    _ => '',
  };

  String handednessLabel(AppHandedness handedness) => switch (handedness) {
    AppHandedness.right => handednessRight,
    AppHandedness.left => handednessLeft,
  };
}
