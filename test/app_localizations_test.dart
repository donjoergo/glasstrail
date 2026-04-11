import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/l10n_extensions.dart';
import 'package:glasstrail/src/models.dart';

void main() {
  group('AppLocalizations', () {
    test('uses singular day wording for one day in German', () {
      final l10n = lookupAppLocalizations(const Locale('de'));

      expect(l10n.dayLabel(1), 'Tag');
      expect(l10n.dayLabel(2), 'Tage');
    });

    test('uses singular day wording for one day in English', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(l10n.dayLabel(1), 'day');
      expect(l10n.dayLabel(2), 'days');
    });

    test('localizes the extended drink categories', () {
      final english = lookupAppLocalizations(const Locale('en'));
      final german = lookupAppLocalizations(const Locale('de'));

      expect(
        english.categoryLabel(DrinkCategory.sparklingWines),
        'Sparkling Wines',
      );
      expect(german.categoryLabel(DrinkCategory.sparklingWines), 'Schaumweine');
      expect(english.categoryLabel(DrinkCategory.longdrinks), 'Longdrinks');
      expect(german.categoryLabel(DrinkCategory.longdrinks), 'Langdrinks');
      expect(english.categoryLabel(DrinkCategory.shots), 'Shots');
      expect(german.categoryLabel(DrinkCategory.shots), 'Shots');
      expect(english.categoryLabel(DrinkCategory.appleWines), 'Apple Wines');
      expect(german.categoryLabel(DrinkCategory.appleWines), 'Apfelweine');
    });
  });
}
