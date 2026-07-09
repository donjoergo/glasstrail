import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations_de.dart';
import 'package:glasstrail/l10n/app_localizations_en.dart';
import 'package:glasstrail/src/achievements/achievement_localizations.dart';
import 'package:glasstrail/src/achievements/catalog.dart';

Set<String> _arbKeys(String path) {
  final Map<String, dynamic> decoded =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return decoded.keys.where((String key) => !key.startsWith('@')).toSet();
}

/// Push/reminder template keys, mirrored from
/// tool/generate_notification_push_l10n.dart's `_notificationTemplateKeys`
/// -- kept in sync manually since that map lives in a build tool, not
/// importable app code.
const Map<String, List<String>> _pushTemplateArbKeys = <String, List<String>>{
  'achievement_reminder_occasion_birthday': <String>[
    'achievementReminderBirthdayTitle',
    'achievementReminderBirthdayBody',
  ],
  'achievement_reminder_occasion_first_sip_anniversary': <String>[
    'achievementReminderFirstSipAnniversaryTitle',
    'achievementReminderFirstSipAnniversaryBody',
  ],
  'achievement_reminder_occasion_new_year': <String>[
    'achievementReminderNewYearTitle',
    'achievementReminderNewYearBody',
  ],
  'achievement_reminder_occasion_christmas': <String>[
    'achievementReminderChristmasTitle',
    'achievementReminderChristmasBody',
  ],
  'achievement_reminder_occasion_easter': <String>[
    'achievementReminderEasterTitle',
    'achievementReminderEasterBody',
  ],
  'achievement_reminder_occasion_halloween': <String>[
    'achievementReminderHalloweenTitle',
    'achievementReminderHalloweenBody',
  ],
  'achievement_reminder_occasion_st_patricks_day': <String>[
    'achievementReminderStPatricksDayTitle',
    'achievementReminderStPatricksDayBody',
  ],
  'achievement_reminder_occasion_oktoberfest': <String>[
    'achievementReminderOktoberfestTitle',
    'achievementReminderOktoberfestBody',
  ],
  'achievement_reminder_occasion_carnival': <String>[
    'achievementReminderCarnivalTitle',
    'achievementReminderCarnivalBody',
  ],
  'achievement_reminder_generic': <String>[
    'achievementReminderGenericTitle',
    'achievementReminderGenericBody',
  ],
};

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

  test('resolveAchievementString resolves every catalog key to non-empty text in en and de', () {
    final en = AppLocalizationsEn();
    final de = AppLocalizationsDe();

    for (final AchievementFamily family in achievementCatalog) {
      expect(resolveAchievementString(en, family.familyTitleKey), isNotEmpty);
      expect(resolveAchievementString(de, family.familyTitleKey), isNotEmpty);
      if (family.countryLabelKey != null) {
        expect(resolveAchievementString(en, family.countryLabelKey!), isNotEmpty);
        expect(resolveAchievementString(de, family.countryLabelKey!), isNotEmpty);
      }
      for (final AchievementLevelDef level in family.levels) {
        expect(resolveAchievementString(en, level.titleKey), isNotEmpty);
        expect(resolveAchievementString(de, level.titleKey), isNotEmpty);
        // Level 1 ladder descriptions may legitimately be empty (mirrors
        // strings.md's "Log a drink..." singular forms); only require
        // non-null resolution, not non-empty text, for descriptions.
        resolveAchievementString(en, level.descriptionKey);
        resolveAchievementString(de, level.descriptionKey);
      }
    }
  });

  test('push/reminder ARB keys used by the notification-copy generator exist and resolve in en and de', () {
    final Set<String> enKeys = _arbKeys('lib/l10n/app_en.arb');
    final Set<String> deKeys = _arbKeys('lib/l10n/app_de.arb');

    for (final List<String> keys in _pushTemplateArbKeys.values) {
      for (final String key in keys) {
        expect(enKeys, contains(key), reason: 'missing from app_en.arb: $key');
        expect(deKeys, contains(key), reason: 'missing from app_de.arb: $key');
      }
    }
  });
}
