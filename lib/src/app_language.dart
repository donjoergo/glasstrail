import 'package:flutter/material.dart';

const String kEnglishLocaleCode = 'en';
const String kGermanLocaleCode = 'de';
const String kFranconianLocaleCode = 'de_QM';
const String kFranconianRegionCode = 'QM';

String normalizeAppLanguageCode(String? localeCode) {
  return switch (localeCode) {
    kGermanLocaleCode ||
    kEnglishLocaleCode ||
    kFranconianLocaleCode => localeCode!,
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
    kGermanLocaleCode => const Locale(kGermanLocaleCode),
    _ => const Locale(kEnglishLocaleCode),
  };
}

Locale resolveFrameworkLocale(String localeCode) {
  return Locale(resolveFrameworkLocaleCode(localeCode));
}
