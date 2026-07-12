class AppLocaleOption {
  const AppLocaleOption({required this.code, required this.nativeLabel});

  final String code;
  // Deliberately the language's own name for itself (e.g. "Deutsch", not
  // "German") so a user can find their language in a picker even if the
  // picker's current UI language isn't one they understand.
  final String nativeLabel;
}

class AppLocaleCatalog {
  const AppLocaleCatalog._();

  static const fallbackCode = 'en';

  static const options = <AppLocaleOption>[
    AppLocaleOption(code: 'en', nativeLabel: 'English'),
    AppLocaleOption(code: 'de', nativeLabel: 'Deutsch'),
  ];

  // Guards against a persisted/remote locale code that no longer matches a
  // supported option (e.g. app previously supported a locale that was later
  // dropped), falling back to English rather than passing an unsupported
  // code through to the Flutter localization machinery.
  static String normalizeCode(String? localeCode) {
    for (final option in options) {
      if (option.code == localeCode) {
        return option.code;
      }
    }
    return fallbackCode;
  }
}
