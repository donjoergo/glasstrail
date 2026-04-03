import 'package:flutter/material.dart';

const String kEnglishLocaleCode = 'en';
const String kGermanLocaleCode = 'de';
const String kFranconianLocaleCode = 'de_QM';
const String kEnglishLocaleName = 'en_US';
const String kGermanLocaleName = 'de_DE';
const String kFranconianRegionCode = 'QM';
const String kGermanCountryCode = 'DE';
const String kEnglishCountryCode = 'US';

String normalizeAppLanguageCode(String? localeCode) {
  return switch (localeCode) {
    kGermanLocaleCode ||
    kEnglishLocaleCode ||
    kFranconianLocaleCode => localeCode!,
    kGermanLocaleName => kGermanLocaleCode,
    kEnglishLocaleName => kEnglishLocaleCode,
    _ => kEnglishLocaleCode,
  };
}

bool usesGermanCopy(String localeCode) {
  return switch (normalizeAppLanguageCode(localeCode)) {
    kGermanLocaleCode || kFranconianLocaleCode => true,
    _ => false,
  };
}

String resolveFrameworkLocaleCode(String localeCode) {
  return usesGermanCopy(localeCode) ? kGermanLocaleCode : kEnglishLocaleCode;
}

Locale resolveAppLocale(String localeCode) {
  return switch (normalizeAppLanguageCode(localeCode)) {
    kFranconianLocaleCode => const Locale.fromSubtags(
      languageCode: kGermanLocaleCode,
      countryCode: kFranconianRegionCode,
    ),
    kGermanLocaleCode => const Locale.fromSubtags(
      languageCode: kGermanLocaleCode,
      countryCode: kGermanCountryCode,
    ),
    _ => const Locale.fromSubtags(
      languageCode: kEnglishLocaleCode,
      countryCode: kEnglishCountryCode,
    ),
  };
}

Locale resolveFrameworkLocale(String localeCode) {
  return Locale(resolveFrameworkLocaleCode(localeCode));
}
