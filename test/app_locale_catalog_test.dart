import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app_locale_catalog.dart';

void main() {
  test('keeps auth locale options in native-label order', () {
    expect(
      AppLocaleCatalog.options.map((option) => option.code).toList(),
      <String>['en', 'de'],
    );
    expect(
      AppLocaleCatalog.options.map((option) => option.nativeLabel).toList(),
      <String>['English', 'Deutsch'],
    );
  });

  test('normalizes unsupported locale codes to english', () {
    expect(AppLocaleCatalog.normalizeCode('en'), 'en');
    expect(AppLocaleCatalog.normalizeCode('de'), 'de');
    expect(AppLocaleCatalog.normalizeCode('fr'), AppLocaleCatalog.fallbackCode);
    expect(AppLocaleCatalog.normalizeCode(null), AppLocaleCatalog.fallbackCode);
  });
}
