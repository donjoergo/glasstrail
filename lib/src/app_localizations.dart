import 'package:flutter/material.dart';

import 'models.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localization != null, 'AppLocalizations missing in widget tree.');
    return localization!;
  }

  static const _values = <String, Map<String, String>>{
    'en': {
      'appTitle': 'GlassTrail',
      'feed': 'Feed',
      'statistics': 'Statistics',
      'profile': 'Profile',
      'welcomeTitle': 'Track every glass',
      'welcomeBody':
          'Log drinks, spot streaks, and build a better picture of your habits.',
      'signIn': 'Sign in',
      'signUp': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'nickname': 'Nickname',
      'displayName': 'Display name',
      'birthday': 'Birthday',
      'optional': 'Optional',
      'pickPhoto': 'Pick photo',
      'changePhoto': 'Change photo',
      'removePhoto': 'Remove photo',
      'authHint':
          'The first release focuses on private tracking. Social features come later.',
      'addDrink': 'Add drink',
      'searchDrinks': 'Search drinks',
      'recentDrinks': 'Recent drinks',
      'catalog': 'Drink catalog',
      'comment': 'Comment',
      'confirmDrink': 'Save entry',
      'save': 'Save',
      'cancel': 'Cancel',
      'createCustomDrink': 'Create custom drink',
      'editCustomDrink': 'Edit custom drink',
      'drinkName': 'Drink name',
      'category': 'Category',
      'volume': 'Volume',
      'feedHeadline': 'Your activity feed',
      'feedBody':
          'This V1 shows your personal history. Friends, comments, and cheers arrive later.',
      'noEntries': 'No drinks logged yet.',
      'startLogging': 'Start by logging your first drink.',
      'weeklyTotal': 'Weekly',
      'monthlyTotal': 'Monthly',
      'yearlyTotal': 'Yearly',
      'currentStreak': 'Current streak',
      'bestStreak': 'Best streak',
      'days': 'days',
      'categoryBreakdown': 'Category breakdown',
      'history': 'History',
      'totalDrinks': 'Total drinks',
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'Language',
      'units': 'Units',
      'logout': 'Log out',
      'editProfile': 'Edit profile',
      'customDrinks': 'My custom drinks',
      'addCustomDrinkAction': 'Add custom drink',
      'roadmap': 'Planned next',
      'roadmapBody':
          'Friends, social feed, achievements, import, and map are part of the plan but intentionally not shipped in V1.',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'english': 'English',
      'german': 'German',
      'invalidRequired': 'Please fill in all required fields.',
      'emptyFilter': 'No drinks match the current filter.',
      'beer': 'Beer',
      'wine': 'Wine',
      'spirits': 'Spirits',
      'cocktails': 'Cocktails',
      'nonAlcoholic': 'Non-alcoholic',
    },
    'de': {
      'appTitle': 'GlassTrail',
      'feed': 'Feed',
      'statistics': 'Statistiken',
      'profile': 'Profil',
      'welcomeTitle': 'Jedes Glas festhalten',
      'welcomeBody':
          'Erfasse Getränke, beobachte Serien und verstehe deine Gewohnheiten besser.',
      'signIn': 'Anmelden',
      'signUp': 'Konto erstellen',
      'email': 'E-Mail',
      'password': 'Passwort',
      'nickname': 'Spitzname',
      'displayName': 'Anzeigename',
      'birthday': 'Geburtstag',
      'optional': 'Optional',
      'pickPhoto': 'Foto wählen',
      'changePhoto': 'Foto ändern',
      'removePhoto': 'Foto entfernen',
      'authHint':
          'Die erste Version konzentriert sich auf privates Tracking. Soziale Funktionen folgen später.',
      'addDrink': 'Getränk hinzufügen',
      'searchDrinks': 'Getränke suchen',
      'recentDrinks': 'Zuletzt verwendet',
      'catalog': 'Getränkeliste',
      'comment': 'Kommentar',
      'confirmDrink': 'Eintrag speichern',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'createCustomDrink': 'Eigenes Getränk erstellen',
      'editCustomDrink': 'Eigenes Getränk bearbeiten',
      'drinkName': 'Getränkename',
      'category': 'Kategorie',
      'volume': 'Volumen',
      'feedHeadline': 'Dein Aktivitätsfeed',
      'feedBody':
          'V1 zeigt deine persönliche Historie. Freunde, Kommentare und Cheers folgen später.',
      'noEntries': 'Noch keine Getränke erfasst.',
      'startLogging': 'Starte mit deinem ersten Eintrag.',
      'weeklyTotal': 'Woche',
      'monthlyTotal': 'Monat',
      'yearlyTotal': 'Jahr',
      'currentStreak': 'Aktuelle Serie',
      'bestStreak': 'Beste Serie',
      'days': 'Tage',
      'categoryBreakdown': 'Kategorien',
      'history': 'Historie',
      'totalDrinks': 'Getränke gesamt',
      'settings': 'Einstellungen',
      'theme': 'Design',
      'language': 'Sprache',
      'units': 'Einheiten',
      'logout': 'Abmelden',
      'editProfile': 'Profil bearbeiten',
      'customDrinks': 'Meine eigenen Getränke',
      'addCustomDrinkAction': 'Eigenes Getränk hinzufügen',
      'roadmap': 'Als Nächstes geplant',
      'roadmapBody':
          'Freunde, Social Feed, Erfolge, Import und Karte sind im Plan, aber bewusst nicht Teil von V1.',
      'themeSystem': 'System',
      'themeLight': 'Hell',
      'themeDark': 'Dunkel',
      'english': 'Englisch',
      'german': 'Deutsch',
      'invalidRequired': 'Bitte alle Pflichtfelder ausfüllen.',
      'emptyFilter': 'Keine Getränke für den aktuellen Filter gefunden.',
      'beer': 'Bier',
      'wine': 'Wein',
      'spirits': 'Spirituosen',
      'cocktails': 'Cocktails',
      'nonAlcoholic': 'Alkoholfrei',
    },
  };

  String _text(String key) => _values[locale.languageCode]![key]!;

  String get appTitle => _text('appTitle');
  String get feed => _text('feed');
  String get statistics => _text('statistics');
  String get profile => _text('profile');
  String get welcomeTitle => _text('welcomeTitle');
  String get welcomeBody => _text('welcomeBody');
  String get signIn => _text('signIn');
  String get signUp => _text('signUp');
  String get email => _text('email');
  String get password => _text('password');
  String get nickname => _text('nickname');
  String get displayName => _text('displayName');
  String get birthday => _text('birthday');
  String get optional => _text('optional');
  String get pickPhoto => _text('pickPhoto');
  String get changePhoto => _text('changePhoto');
  String get removePhoto => _text('removePhoto');
  String get authHint => _text('authHint');
  String get addDrink => _text('addDrink');
  String get searchDrinks => _text('searchDrinks');
  String get recentDrinks => _text('recentDrinks');
  String get catalog => _text('catalog');
  String get comment => _text('comment');
  String get confirmDrink => _text('confirmDrink');
  String get save => _text('save');
  String get cancel => _text('cancel');
  String get createCustomDrink => _text('createCustomDrink');
  String get editCustomDrink => _text('editCustomDrink');
  String get drinkName => _text('drinkName');
  String get category => _text('category');
  String get volume => _text('volume');
  String get feedHeadline => _text('feedHeadline');
  String get feedBody => _text('feedBody');
  String get noEntries => _text('noEntries');
  String get startLogging => _text('startLogging');
  String get weeklyTotal => _text('weeklyTotal');
  String get monthlyTotal => _text('monthlyTotal');
  String get yearlyTotal => _text('yearlyTotal');
  String get currentStreak => _text('currentStreak');
  String get bestStreak => _text('bestStreak');
  String get days => _text('days');
  String get categoryBreakdown => _text('categoryBreakdown');
  String get history => _text('history');
  String get totalDrinks => _text('totalDrinks');
  String get settings => _text('settings');
  String get theme => _text('theme');
  String get language => _text('language');
  String get units => _text('units');
  String get logout => _text('logout');
  String get editProfile => _text('editProfile');
  String get customDrinks => _text('customDrinks');
  String get addCustomDrinkAction => _text('addCustomDrinkAction');
  String get roadmap => _text('roadmap');
  String get roadmapBody => _text('roadmapBody');
  String get themeSystem => _text('themeSystem');
  String get themeLight => _text('themeLight');
  String get themeDark => _text('themeDark');
  String get english => _text('english');
  String get german => _text('german');
  String get invalidRequired => _text('invalidRequired');
  String get emptyFilter => _text('emptyFilter');

  String categoryLabel(DrinkCategory category) => switch (category) {
        DrinkCategory.beer => _text('beer'),
        DrinkCategory.wine => _text('wine'),
        DrinkCategory.spirits => _text('spirits'),
        DrinkCategory.cocktails => _text('cocktails'),
        DrinkCategory.nonAlcoholic => _text('nonAlcoholic'),
      };

  String themeLabel(AppThemePreference preference) => switch (preference) {
        AppThemePreference.system => themeSystem,
        AppThemePreference.light => themeLight,
        AppThemePreference.dark => themeDark,
      };

  String unitLabel(AppUnit unit) => unit.name;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((candidate) => candidate.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<AppLocalizations> old,
  ) {
    return false;
  }
}
