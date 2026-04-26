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

  String unitLabel(AppUnit unit) => unit.name;

  String weekdayShortLabel(int weekday) => switch (weekday) {
    DateTime.monday => weekdayMondayShort,
    DateTime.tuesday => weekdayTuesdayShort,
    DateTime.wednesday => weekdayWednesdayShort,
    DateTime.thursday => weekdayThursdayShort,
    DateTime.friday => weekdayFridayShort,
    DateTime.saturday => weekdaySaturdayShort,
    DateTime.sunday => weekdaySundayShort,
    _ => '',
  };

  String handednessLabel(AppHandedness handedness) => switch (handedness) {
    AppHandedness.right => handednessRight,
    AppHandedness.left => handednessLeft,
  };
}
