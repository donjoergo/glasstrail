class AppLocaleOption {
  const AppLocaleOption({required this.code, required this.nativeLabel});

  final String code;
  final String nativeLabel;
}

class AppLocaleCatalog {
  const AppLocaleCatalog._();

  static const fallbackCode = 'en';

  static const options = <AppLocaleOption>[
    AppLocaleOption(code: 'en', nativeLabel: 'English'),
    AppLocaleOption(code: 'de', nativeLabel: 'Deutsch'),
  ];

  static String normalizeCode(String? localeCode) {
    for (final option in options) {
      if (option.code == localeCode) {
        return option.code;
      }
    }
    return fallbackCode;
  }
}
