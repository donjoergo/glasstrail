import 'package:flutter/material.dart';

import 'models.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('de')];

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
      'statisticsOverview': 'Overview',
      'statisticsMap': 'Map',
      'statisticsGallery': 'Gallery',
      'profile': 'Profile',
      'welcomeTitle': 'Track every glass',
      'welcomeBody':
          'Log drinks, spot streaks, and build a better picture of your habits.',
      'signIn': 'Sign in',
      'signUp': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'displayName': 'Display name',
      'birthday': 'Birthday',
      'optional': 'Optional',
      'removeBirthday': 'Remove birthday',
      'pickPhoto': 'Pick photo',
      'pickPhotoSource': 'Choose photo source',
      'changePhoto': 'Change photo',
      'takePhoto': 'Take photo',
      'chooseFromGallery': 'Choose from gallery',
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
      'editEntry': 'Edit entry',
      'deleteEntry': 'Delete entry',
      'deleteEntryPrompt':
          'Delete this drink entry? The saved comment and photo will be removed too.',
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
      'thisWeek': 'This week',
      'streakPromptStart': 'Log a drink now to start your streak.',
      'streakPromptKeepAlive': 'Log a drink now to keep your streak alive.',
      'streakPromptStartedToday': 'Very good! You started your streak today.',
      'streakPromptContinuedToday':
          'Very good! You continued your streak today.',
      'weekdayMondayShort': 'M',
      'weekdayTuesdayShort': 'T',
      'weekdayWednesdayShort': 'W',
      'weekdayThursdayShort': 'T',
      'weekdayFridayShort': 'F',
      'weekdaySaturdayShort': 'S',
      'weekdaySundayShort': 'S',
      'day': 'day',
      'days': 'days',
      'categoryBreakdown': 'Category breakdown',
      'history': 'History',
      'statisticsMapPlaceholderTitle': 'Drink map coming soon',
      'statisticsMapPlaceholderBody':
          'Logged drinks will appear here on a map in a later step.',
      'statisticsGalleryPlaceholderTitle': 'Gallery coming soon',
      'statisticsGalleryPlaceholderBody':
          'Drink photos from your log will appear here in a later step.',
      'totalDrinks': 'Total drinks',
      'settings': 'Settings',
      'backend': 'Backend',
      'backendRemoteBody': 'Supabase is configured and remote sync is active.',
      'backendLocalBody':
          'No Supabase configuration was provided, so the app is using the local fallback backend.',
      'theme': 'Theme',
      'language': 'Language',
      'units': 'Units',
      'handedness': 'Handedness',
      'logout': 'Log out',
      'editProfile': 'Edit profile',
      'customDrinks': 'My custom drinks',
      'addCustomDrinkAction': 'Add custom drink',
      'roadmap': 'Planned next',
      'about': 'About',
      'github': 'GitHub',
      'roadmapBody':
          'Friends, social feed, achievements, import, and map are part of the plan but intentionally not shipped in V1.',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'english': 'English',
      'german': 'German',
      'handednessRight': 'Right',
      'handednessLeft': 'Left',
      'invalidRequired': 'Please fill in all required fields.',
      'emptyFilter': 'No drinks match the current filter.',
      'launchingApp': 'Loading your drinks and settings.',
      'welcomeToGlassTrail': 'Welcome to GlassTrail.',
      'welcomeBack': 'Welcome back.',
      'profileUpdated': 'Profile updated.',
      'customDrinkSaved': 'Custom drink saved.',
      'drinkLogged': '{drink} logged.',
      'entryUpdated': 'Entry updated.',
      'entryDeleted': 'Entry deleted.',
      'somethingWentWrong': 'Something went wrong. Please try again.',
      'accountAlreadyExists': 'An account with that email already exists.',
      'invalidCredentials': 'The email or password is incorrect.',
      'profileUpdateFailed': 'The profile could not be updated.',
      'entryUpdateFailed': 'The drink entry could not be updated.',
      'entryDeleteFailed': 'The drink entry could not be deleted.',
      'customDrinkAlreadyExists':
          'You already have a custom drink with that name.',
      'signUpMissingUser': 'Sign-up did not return a user.',
      'signUpConfirmationRequired':
          'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.',
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
      'statisticsOverview': 'Überblick',
      'statisticsMap': 'Karte',
      'statisticsGallery': 'Galerie',
      'profile': 'Profil',
      'welcomeTitle': 'Jedes Glas festhalten',
      'welcomeBody':
          'Erfasse Getränke, beobachte Serien und verstehe deine Gewohnheiten besser.',
      'signIn': 'Anmelden',
      'signUp': 'Konto erstellen',
      'email': 'E-Mail',
      'password': 'Passwort',
      'displayName': 'Anzeigename',
      'birthday': 'Geburtstag',
      'optional': 'Optional',
      'removeBirthday': 'Geburtstag entfernen',
      'pickPhoto': 'Foto wählen',
      'pickPhotoSource': 'Fotoquelle wählen',
      'changePhoto': 'Foto ändern',
      'takePhoto': 'Kamera verwenden',
      'chooseFromGallery': 'Aus Galerie wählen',
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
      'editEntry': 'Eintrag bearbeiten',
      'deleteEntry': 'Eintrag löschen',
      'deleteEntryPrompt':
          'Diesen Getränkeeintrag löschen? Der gespeicherte Kommentar und das Foto werden ebenfalls entfernt.',
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
      'thisWeek': 'Diese Woche',
      'streakPromptStart': 'Logge jetzt ein Getränk und starte deine Serie.',
      'streakPromptKeepAlive':
          'Logge jetzt ein Getränk, damit deine Serie bestehen bleibt.',
      'streakPromptStartedToday':
          'Sehr gut! Du hast deine Serie heute gestartet.',
      'streakPromptContinuedToday':
          'Sehr gut! Du hast deine Serie heute fortgeführt.',
      'weekdayMondayShort': 'Mo',
      'weekdayTuesdayShort': 'Di',
      'weekdayWednesdayShort': 'Mi',
      'weekdayThursdayShort': 'Do',
      'weekdayFridayShort': 'Fr',
      'weekdaySaturdayShort': 'Sa',
      'weekdaySundayShort': 'So',
      'day': 'Tag',
      'days': 'Tage',
      'categoryBreakdown': 'Kategorien',
      'history': 'Historie',
      'statisticsMapPlaceholderTitle': 'Karte folgt später',
      'statisticsMapPlaceholderBody':
          'Hier werden geloggte Getränke später auf einer Karte angezeigt.',
      'statisticsGalleryPlaceholderTitle': 'Galerie folgt später',
      'statisticsGalleryPlaceholderBody':
          'Hier werden Fotos aus deinen Getränke-Logs später als Galerie angezeigt.',
      'totalDrinks': 'Getränke gesamt',
      'settings': 'Einstellungen',
      'backend': 'Backend',
      'backendRemoteBody':
          'Supabase ist konfiguriert und die Remote-Synchronisierung ist aktiv.',
      'backendLocalBody':
          'Es wurde keine Supabase-Konfiguration gesetzt, daher nutzt die App das lokale Fallback-Backend.',
      'theme': 'Design',
      'language': 'Sprache',
      'units': 'Einheiten',
      'handedness': 'Bedienseite',
      'logout': 'Abmelden',
      'editProfile': 'Profil bearbeiten',
      'customDrinks': 'Meine eigenen Getränke',
      'addCustomDrinkAction': 'Eigenes Getränk hinzufügen',
      'roadmap': 'Als Nächstes geplant',
      'about': 'Über die App',
      'github': 'GitHub',
      'roadmapBody':
          'Freunde, Social Feed, Erfolge, Import und Karte sind im Plan, aber bewusst nicht Teil von V1.',
      'themeSystem': 'System',
      'themeLight': 'Hell',
      'themeDark': 'Dunkel',
      'english': 'Englisch',
      'german': 'Deutsch',
      'handednessRight': 'Rechts',
      'handednessLeft': 'Links',
      'invalidRequired': 'Bitte alle Pflichtfelder ausfüllen.',
      'emptyFilter': 'Keine Getränke für den aktuellen Filter gefunden.',
      'launchingApp': 'Getränke und Einstellungen werden geladen.',
      'welcomeToGlassTrail': 'Willkommen bei GlassTrail.',
      'welcomeBack': 'Willkommen zurück.',
      'profileUpdated': 'Profil aktualisiert.',
      'customDrinkSaved': 'Eigenes Getränk gespeichert.',
      'drinkLogged': '{drink} erfasst.',
      'entryUpdated': 'Eintrag aktualisiert.',
      'entryDeleted': 'Eintrag gelöscht.',
      'somethingWentWrong':
          'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
      'accountAlreadyExists':
          'Es gibt bereits ein Konto mit dieser E-Mail-Adresse.',
      'invalidCredentials': 'Die E-Mail oder das Passwort ist falsch.',
      'profileUpdateFailed': 'Das Profil konnte nicht aktualisiert werden.',
      'entryUpdateFailed':
          'Der Getränkeeintrag konnte nicht aktualisiert werden.',
      'entryDeleteFailed': 'Der Getränkeeintrag konnte nicht gelöscht werden.',
      'customDrinkAlreadyExists':
          'Du hast bereits ein eigenes Getränk mit diesem Namen.',
      'signUpMissingUser':
          'Die Registrierung hat keinen Benutzer zurückgegeben.',
      'signUpConfirmationRequired':
          'Die Registrierung bei Supabase war erfolgreich, aber die E-Mail-Bestätigung ist aktiviert. Bestätige zuerst die E-Mail und melde dich dann an.',
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
  String get statisticsOverview => _text('statisticsOverview');
  String get statisticsMap => _text('statisticsMap');
  String get statisticsGallery => _text('statisticsGallery');
  String get profile => _text('profile');
  String get welcomeTitle => _text('welcomeTitle');
  String get welcomeBody => _text('welcomeBody');
  String get signIn => _text('signIn');
  String get signUp => _text('signUp');
  String get email => _text('email');
  String get password => _text('password');
  String get displayName => _text('displayName');
  String get birthday => _text('birthday');
  String get optional => _text('optional');
  String get removeBirthday => _text('removeBirthday');
  String get pickPhoto => _text('pickPhoto');
  String get pickPhotoSource => _text('pickPhotoSource');
  String get changePhoto => _text('changePhoto');
  String get takePhoto => _text('takePhoto');
  String get chooseFromGallery => _text('chooseFromGallery');
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
  String get editEntry => _text('editEntry');
  String get deleteEntry => _text('deleteEntry');
  String get deleteEntryPrompt => _text('deleteEntryPrompt');
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
  String get thisWeek => _text('thisWeek');
  String get streakPromptStart => _text('streakPromptStart');
  String get streakPromptKeepAlive => _text('streakPromptKeepAlive');
  String get streakPromptStartedToday => _text('streakPromptStartedToday');
  String get streakPromptContinuedToday => _text('streakPromptContinuedToday');
  String get day => _text('day');
  String get days => _text('days');
  String get categoryBreakdown => _text('categoryBreakdown');
  String get history => _text('history');
  String get statisticsMapPlaceholderTitle =>
      _text('statisticsMapPlaceholderTitle');
  String get statisticsMapPlaceholderBody =>
      _text('statisticsMapPlaceholderBody');
  String get statisticsGalleryPlaceholderTitle =>
      _text('statisticsGalleryPlaceholderTitle');
  String get statisticsGalleryPlaceholderBody =>
      _text('statisticsGalleryPlaceholderBody');
  String get totalDrinks => _text('totalDrinks');
  String get settings => _text('settings');
  String get backend => _text('backend');
  String get backendRemoteBody => _text('backendRemoteBody');
  String get backendLocalBody => _text('backendLocalBody');
  String get theme => _text('theme');
  String get language => _text('language');
  String get units => _text('units');
  String get handedness => _text('handedness');
  String get logout => _text('logout');
  String get editProfile => _text('editProfile');
  String get customDrinks => _text('customDrinks');
  String get addCustomDrinkAction => _text('addCustomDrinkAction');
  String get roadmap => _text('roadmap');
  String get about => _text('about');
  String get github => _text('github');
  String get roadmapBody => _text('roadmapBody');
  String get themeSystem => _text('themeSystem');
  String get themeLight => _text('themeLight');
  String get themeDark => _text('themeDark');
  String get english => _text('english');
  String get german => _text('german');
  String get handednessRight => _text('handednessRight');
  String get handednessLeft => _text('handednessLeft');
  String get invalidRequired => _text('invalidRequired');
  String get emptyFilter => _text('emptyFilter');
  String get launchingApp => _text('launchingApp');
  String get welcomeToGlassTrail => _text('welcomeToGlassTrail');
  String get welcomeBack => _text('welcomeBack');
  String get profileUpdated => _text('profileUpdated');
  String get customDrinkSaved => _text('customDrinkSaved');
  String get entryUpdated => _text('entryUpdated');
  String get entryDeleted => _text('entryDeleted');
  String get somethingWentWrong => _text('somethingWentWrong');
  String get accountAlreadyExists => _text('accountAlreadyExists');
  String get invalidCredentials => _text('invalidCredentials');
  String get profileUpdateFailed => _text('profileUpdateFailed');
  String get entryUpdateFailed => _text('entryUpdateFailed');
  String get entryDeleteFailed => _text('entryDeleteFailed');
  String get customDrinkAlreadyExists => _text('customDrinkAlreadyExists');
  String get signUpMissingUser => _text('signUpMissingUser');
  String get signUpConfirmationRequired => _text('signUpConfirmationRequired');

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

  String dayLabel(int count) => count == 1 ? day : days;

  String weekdayShortLabel(int weekday) => switch (weekday) {
    DateTime.monday => _text('weekdayMondayShort'),
    DateTime.tuesday => _text('weekdayTuesdayShort'),
    DateTime.wednesday => _text('weekdayWednesdayShort'),
    DateTime.thursday => _text('weekdayThursdayShort'),
    DateTime.friday => _text('weekdayFridayShort'),
    DateTime.saturday => _text('weekdaySaturdayShort'),
    DateTime.sunday => _text('weekdaySundayShort'),
    _ => '',
  };

  String handednessLabel(AppHandedness handedness) => switch (handedness) {
    AppHandedness.right => handednessRight,
    AppHandedness.left => handednessLeft,
  };

  String drinkLogged(String drinkName) =>
      _text('drinkLogged').replaceAll('{drink}', drinkName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (candidate) => candidate.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
