import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/catalog.dart';

Set<String> _arbKeys(String path) {
  final Map<String, dynamic> decoded =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return decoded.keys.where((String key) => !key.startsWith('@')).toSet();
}

void main() {
  test('every catalog title/description/label key exists in both ARB files', () {
    final Set<String> enKeys = _arbKeys('lib/l10n/app_en.arb');
    final Set<String> deKeys = _arbKeys('lib/l10n/app_de.arb');

    final Set<String> requiredKeys = <String>{};
    for (final AchievementFamily family in achievementCatalog) {
      requiredKeys.add(family.familyTitleKey);
      if (family.countryLabelKey != null) {
        requiredKeys.add(family.countryLabelKey!);
      }
      for (final AchievementLevelDef level in family.levels) {
        requiredKeys.add(level.titleKey);
        requiredKeys.add(level.descriptionKey);
      }
    }

    final Set<String> missingFromEn = requiredKeys.difference(enKeys);
    final Set<String> missingFromDe = requiredKeys.difference(deKeys);

    expect(missingFromEn, isEmpty, reason: 'missing from app_en.arb');
    expect(missingFromDe, isEmpty, reason: 'missing from app_de.arb');
  });
}
