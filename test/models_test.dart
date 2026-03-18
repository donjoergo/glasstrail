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
      });

      expect(settings.themePreference, AppThemePreference.dark);
      expect(settings.localeCode, 'de');
      expect(settings.unit, AppUnit.oz);
      expect(settings.handedness, AppHandedness.left);
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
}
