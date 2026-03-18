import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('uses singular day wording for one day in German', () {
      final l10n = AppLocalizations(const Locale('de'));

      expect(l10n.dayLabel(1), 'Tag');
      expect(l10n.dayLabel(2), 'Tage');
    });

    test('uses singular day wording for one day in English', () {
      final l10n = AppLocalizations(const Locale('en'));

      expect(l10n.dayLabel(1), 'day');
      expect(l10n.dayLabel(2), 'days');
    });
  });
}
