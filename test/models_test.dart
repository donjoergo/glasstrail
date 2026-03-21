import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/models.dart';

void main() {
  group('AppUnit', () {
    test('rounds ml display values to whole milliliters', () {
      expect(AppUnit.ml.formatVolume(42.2), '42 ml');
      expect(AppUnit.ml.formatVolume(42.8), '43 ml');
      expect(AppUnit.ml.formatVolumeInput(42.2), '42');
      expect(AppUnit.ml.formatVolumeInput(42.8), '43');
    });

    test('keeps oz display values fractional when needed', () {
      expect(AppUnit.oz.formatVolume(330), '11.2 oz');
      expect(AppUnit.oz.formatVolumeInput(330), '11.2');
    });
  });

  group('UserSettings', () {
    test('reads snake_case keys from remote rows', () {
      final settings = UserSettings.fromJson(<String, dynamic>{
        'theme_preference': 'dark',
        'locale_code': 'de',
        'unit': 'oz',
        'handedness': 'left',
        'hidden_global_drink_ids': <String>['beer-pils'],
        'hidden_global_drink_categories': <String>['beer'],
        'global_drink_order_overrides': <String, List<String>>{
          'beer': <String>['beer-ipa', 'beer-pils'],
        },
      });

      expect(settings.themePreference, AppThemePreference.dark);
      expect(settings.localeCode, 'de');
      expect(settings.unit, AppUnit.oz);
      expect(settings.handedness, AppHandedness.left);
      expect(settings.hiddenGlobalDrinkIds, <String>['beer-pils']);
      expect(settings.hiddenGlobalDrinkCategories, <DrinkCategory>[
        DrinkCategory.beer,
      ]);
      expect(settings.globalDrinkOrderOverrides[DrinkCategory.beer], <String>[
        'beer-ipa',
        'beer-pils',
      ]);
    });
  });

  group('AppUser', () {
    test('normalizes birthdays to month and day only', () {
      final user = AppUser.fromJson(<String, dynamic>{
        'id': 'user-1',
        'email': 'alice@example.com',
        'displayName': 'Alice Example',
        'birthday': '1994-07-16',
      });

      expect(user.birthday, DateTime(2000, 7, 16));
      expect(user.toJson()['birthday'], '2000-07-16T00:00:00.000');
    });
  });

  group('DrinkEntry', () {
    test('copyWith can clear comment and image independently', () {
      final entry = DrinkEntry(
        id: 'entry-1',
        userId: 'user-1',
        drinkId: 'water',
        drinkName: 'Water',
        category: DrinkCategory.nonAlcoholic,
        consumedAt: DateTime(2026, 3, 19, 12),
        volumeMl: 250,
        comment: 'Original',
        imagePath: '/tmp/original.png',
        locationLatitude: 52.52,
        locationLongitude: 13.405,
        locationAddress: 'Alexanderplatz 1, 10178 Berlin',
      );

      final updated = entry.copyWith(comment: 'Updated', clearImagePath: true);
      final cleared = updated.copyWith(clearComment: true);

      expect(updated.comment, 'Updated');
      expect(updated.imagePath, isNull);
      expect(updated.locationLatitude, 52.52);
      expect(updated.locationLongitude, 13.405);
      expect(updated.locationAddress, 'Alexanderplatz 1, 10178 Berlin');
      expect(cleared.comment, isNull);
      expect(cleared.drinkId, entry.drinkId);
      expect(cleared.consumedAt, entry.consumedAt);
    });

    test('reads snake_case location keys from remote rows', () {
      final entry = DrinkEntry.fromJson(<String, dynamic>{
        'id': 'entry-remote',
        'userId': 'user-1',
        'drinkId': 'water',
        'drinkName': 'Water',
        'category': 'nonAlcoholic',
        'consumedAt': '2026-03-19T12:00:00.000Z',
        'volume_ml': 250,
        'location_latitude': 52.52,
        'location_longitude': 13.405,
        'location_address': 'Alexanderplatz 1, 10178 Berlin',
      });

      expect(entry.volumeMl, 250);
      expect(entry.locationLatitude, 52.52);
      expect(entry.locationLongitude, 13.405);
      expect(entry.locationAddress, 'Alexanderplatz 1, 10178 Berlin');
    });
  });
}
