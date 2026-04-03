import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

Map<String, dynamic> _readArbFile(String path) {
  return Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  group('AppLocalizations', () {
    test('uses singular day wording for one day in German', () {
      final l10n = lookupAppLocalizations(const Locale('de'));

      expect(l10n.dayLabel(1), 'Tag');
      expect(l10n.dayLabel(2), 'Tage');
    });

    test('uses singular day wording for one day in English', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(l10n.dayLabel(1), 'day');
      expect(l10n.dayLabel(2), 'days');
    });

    test('loads the Fränggisch locale', () {
      final l10n = lookupAppLocalizations(
        const Locale.fromSubtags(languageCode: 'de', countryCode: 'QM'),
      );

      expect(l10n.localeName, 'de_QM');
      expect(l10n.language, 'Sprooch');
      expect(l10n.franconian, 'Fränggisch');
      expect(l10n.welcomeTitle, 'Jeds Gläsla fesdhaldn');
      expect(l10n.drinkLogged('Bier'), 'Bier is eigdroong.');
      expect(l10n.dayLabel(1), 'Dog');
      expect(l10n.dayLabel(2), 'Däg');
    });

    test('keeps app_de_QM.arb aligned with the other locale files', () {
      final english = _readArbFile('lib/l10n/app_en.arb');
      final german = _readArbFile('lib/l10n/app_de.arb');
      final franconian = _readArbFile('lib/l10n/app_de_QM.arb');

      expect(english['@@locale'], 'en');
      expect(german['@@locale'], 'de');
      expect(franconian['@@locale'], 'de_QM');
      expect(_messageKeys(franconian), _messageKeys(german));
      expect(_messageKeys(franconian), _messageKeys(english));
    });

    testWidgets('supports the de_QM locale through the standard delegate', (
      tester,
    ) async {
      late BuildContext context;

      await tester.pumpWidget(
        Localizations(
          locale: const Locale.fromSubtags(
            languageCode: 'de',
            countryCode: 'QM',
          ),
          delegates: AppLocalizations.localizationsDelegates,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (buildContext) {
                context = buildContext;
                return Text(AppLocalizations.of(buildContext).language);
              },
            ),
          ),
        ),
      );

      expect(Localizations.localeOf(context).languageCode, 'de');
      expect(Localizations.localeOf(context).countryCode, 'QM');
      expect(AppLocalizations.of(context).localeName, 'de_QM');
      expect(find.text('Sprooch'), findsOneWidget);
    });
  });
}
