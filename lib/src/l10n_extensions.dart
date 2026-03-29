import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import 'models.dart';

extension AppLocalizationsX on AppLocalizations {
  Locale get locale => Locale(localeName);

  String categoryLabel(DrinkCategory category) => switch (category) {
    DrinkCategory.beer => beer,
    DrinkCategory.wine => wine,
    DrinkCategory.spirits => spirits,
    DrinkCategory.cocktails => cocktails,
    DrinkCategory.nonAlcoholic => nonAlcoholic,
  };

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
