// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Glass Trail';

  @override
  String get feed => 'Feed';

  @override
  String get statistics => 'Statistiken';

  @override
  String get statisticsOverview => 'Überblick';

  @override
  String get statisticsMap => 'Karte';

  @override
  String get statisticsGallery => 'Galerie';

  @override
  String get bar => 'Bar';

  @override
  String get profile => 'Profil';

  @override
  String get welcomeTitle => 'Jedes Glas festhalten';

  @override
  String get welcomeBody =>
      'Erfasse Getränke, beobachte Serien und verstehe deine Gewohnheiten besser.';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Konto erstellen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get birthday => 'Geburtstag';

  @override
  String get optional => 'Optional';

  @override
  String get removeBirthday => 'Geburtstag entfernen';

  @override
  String get pickPhoto => 'Foto wählen';

  @override
  String get pickPhotoSource => 'Fotoquelle wählen';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get takePhoto => 'Kamera verwenden';

  @override
  String get chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get removePhoto => 'Foto entfernen';

  @override
  String get addDrink => 'Getränk hinzufügen';

  @override
  String get searchDrinks => 'Getränke suchen';

  @override
  String get recentDrinks => 'Zuletzt verwendet';

  @override
  String get catalog => 'Getränkeliste';

  @override
  String get location => 'Standort';

  @override
  String get saveLocationForEntry => 'Standort für diesen Eintrag speichern';

  @override
  String get locationLoading => 'Aktueller Standort wird ermittelt…';

  @override
  String get locationUnavailable =>
      'Standort nicht verfügbar. Der Eintrag kann trotzdem gespeichert werden.';

  @override
  String get locationAddressUnavailable =>
      'Adresse nicht verfügbar. Die Koordinaten werden trotzdem gespeichert.';

  @override
  String get locationDisabledForEntry =>
      'Standort für diesen Eintrag deaktiviert.';

  @override
  String get locationApproximateWarning =>
      'Android liefert aktuell nur einen ungefähren Standort. Aktiviere den genauen Standort in den App-Einstellungen.';

  @override
  String get openAppSettings => 'App-Einstellungen öffnen';

  @override
  String get comment => 'Kommentar';

  @override
  String get confirmDrink => 'Eintrag speichern';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get close => 'Schließen';

  @override
  String get accept => 'Annehmen';

  @override
  String get reject => 'Ablehnen';

  @override
  String get pending => 'Ausstehend';

  @override
  String get share => 'Teilen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get whatsNew => 'Was gibt\'s Neues';

  @override
  String get editEntry => 'Eintrag bearbeiten';

  @override
  String get drinkType => 'Getränketyp';

  @override
  String get changeDrinkType => 'Getränketyp ändern';

  @override
  String get deleteEntry => 'Eintrag löschen';

  @override
  String get deleteEntryPrompt =>
      'Diesen Getränkeeintrag löschen? Der gespeicherte Kommentar und das Foto werden ebenfalls entfernt.';

  @override
  String get createCustomDrink => 'Eigenes Getränk erstellen';

  @override
  String get editCustomDrink => 'Eigenes Getränk bearbeiten';

  @override
  String get deleteCustomDrink => 'Eigenes Getränk löschen';

  @override
  String get deleteCustomDrinkPrompt =>
      'Dieses eigene Getränk löschen? Bereits erfasste Einträge bleiben erhalten.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String deleteAccountBody(String phrase) {
    return 'Dadurch werden dein Konto, Profil, Verlauf, Freunde und Benachrichtigungen dauerhaft gelöscht. Gib \"$phrase\" ein, um das Löschen zu aktivieren.';
  }

  @override
  String deleteAccountVerificationLabel(String phrase) {
    return '\"$phrase\" zum Bestätigen eingeben';
  }

  @override
  String get deleteAccountVerificationPhrase => 'KONTO LÖSCHEN';

  @override
  String get deleteAccountAction => 'Konto löschen';

  @override
  String get drinkName => 'Getränkename';

  @override
  String get category => 'Kategorie';

  @override
  String get volume => 'Volumen';

  @override
  String get alcoholFree => 'Alkoholfrei';

  @override
  String get customDrinkAlcoholFreeSwitch => 'Alkoholfrei';

  @override
  String get appUpdatedTitle => 'App aktualisiert';

  @override
  String appUpdatedBody(String appName, String version) {
    return '$appName wurde gerade auf $version aktualisiert. Möchtest du dir die Änderungsnotizen ansehen?';
  }

  @override
  String get feedHeadline => 'Dein Aktivitätsfeed';

  @override
  String get feedCheersAction => 'Prost';

  @override
  String get noEntries => 'Noch keine Getränke erfasst.';

  @override
  String get startLogging => 'Starte mit deinem ersten Eintrag.';

  @override
  String get weeklyTotal => 'Diese Woche';

  @override
  String get monthlyTotal => 'Dieser Monat';

  @override
  String get yearlyTotal => 'Dieses Jahr';

  @override
  String get currentStreak => 'Aktuelle Serie';

  @override
  String get bestStreak => 'Beste Serie';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get streakPromptStart =>
      'Logge jetzt ein Getränk und starte deine Serie.';

  @override
  String get streakPromptKeepAlive =>
      'Logge jetzt ein Getränk, damit deine Serie bestehen bleibt.';

  @override
  String get streakPromptStartedToday =>
      'Sehr gut! Du hast deine Serie heute gestartet.';

  @override
  String get streakPromptContinuedToday =>
      'Sehr gut! Du hast deine Serie heute fortgeführt.';

  @override
  String get weekdayMondayShort => 'Mo';

  @override
  String get weekdayTuesdayShort => 'Di';

  @override
  String get weekdayWednesdayShort => 'Mi';

  @override
  String get weekdayThursdayShort => 'Do';

  @override
  String get weekdayFridayShort => 'Fr';

  @override
  String get weekdaySaturdayShort => 'Sa';

  @override
  String get weekdaySundayShort => 'So';

  @override
  String get categoryBreakdown => 'Kategorien';

  @override
  String get beerBreakdown => 'Bier-Aufteilung';

  @override
  String get regularBeer => 'Normales Bier';

  @override
  String get alcoholFreeBeer => 'Alkoholfreies Bier';

  @override
  String get history => 'Historie';

  @override
  String get statisticsMapEmptyTitle => 'Noch keine Drinks mit Standort';

  @override
  String get statisticsMapEmptyBody =>
      'Aktiviere beim Loggen den Standort, damit Drinks hier auf der Karte erscheinen.';

  @override
  String get statisticsGalleryEmptyTitle => 'Noch keine Drink-Fotos';

  @override
  String get statisticsGalleryEmptyBody =>
      'Fotos aus deinen Log-Einträgen erscheinen hier automatisch.';

  @override
  String get totalDrinks => 'Getränke gesamt';

  @override
  String get settings => 'Einstellungen';

  @override
  String get globalDrinks => 'Globale Getränke';

  @override
  String get barDrinkSortingTab => 'Getränke Sortierung';

  @override
  String get barCustomDrinksTab => 'Eigene Getränke';

  @override
  String get barGlobalDrinksBody =>
      'Sortiere globale und eigene Getränke innerhalb jeder Kategorie neu und blende globale Einträge aus, die du in Auswahllisten nicht sehen willst.';

  @override
  String get barCustomDrinksBody =>
      'Erstelle und bearbeite deine eigenen Getränke.';

  @override
  String get hiddenDrinks => 'Ausgeblendete Getränke';

  @override
  String get hideCategory => 'Kategorie ausblenden';

  @override
  String get showCategory => 'Kategorie einblenden';

  @override
  String get hideDrink => 'Ausblenden';

  @override
  String get showDrink => 'Einblenden';

  @override
  String get allGlobalDrinksHidden =>
      'Alle globalen Getränke dieser Kategorie sind ausgeblendet.';

  @override
  String get backend => 'Backend';

  @override
  String get backendRemoteBody =>
      'Supabase ist konfiguriert und die Remote-Synchronisierung ist aktiv.';

  @override
  String get backendLocalBody =>
      'Es wurde keine Supabase-Konfiguration gesetzt, daher nutzt die App das lokale Fallback-Backend.';

  @override
  String get theme => 'Design';

  @override
  String get language => 'Sprache';

  @override
  String get units => 'Einheiten';

  @override
  String get handedness => 'Bedienseite';

  @override
  String get shareStatsWithFriends => 'Statistiken mit Freunden teilen';

  @override
  String get shareStatsWithFriendsBody =>
      'Bestätigte Freunde können deine geteilten Statistiken direkt in der App öffnen.';

  @override
  String get logout => 'Abmelden';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get accountSectionTitle => 'Konto';

  @override
  String get accountSectionBody =>
      'Ändere dein Passwort oder lösche dieses Konto dauerhaft.';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordBody =>
      'Bestätige dein aktuelles Passwort und wähle ein neues.';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get repeatNewPassword => 'Neues Passwort wiederholen';

  @override
  String get changePasswordAction => 'Passwort aktualisieren';

  @override
  String get changePasswordConfirmationMismatch =>
      'Die neuen Passwörter stimmen nicht überein.';

  @override
  String get changePasswordSameAsCurrent =>
      'Das neue Passwort muss sich vom aktuellen Passwort unterscheiden.';

  @override
  String get friends => 'Freunde';

  @override
  String get friendsSectionBody =>
      'Teile deinen Profillink, damit andere dir eine Freundschaftsanfrage senden können.';

  @override
  String get friendsEmpty => 'Noch keine Freunde oder ausstehenden Anfragen.';

  @override
  String get friendProfile => 'Freundesprofil';

  @override
  String get friendProfileLinkAction => 'Mein Profil zeigen';

  @override
  String get friendProfileLinkTitle => 'Dein Freundesprofil';

  @override
  String get friendProfileLinkBody =>
      'Freunde können diesen Code scannen oder den Link öffnen, um dir eine Anfrage zu senden.';

  @override
  String get friendProfileShareTitle => 'Füge mich auf Glass Trail hinzu';

  @override
  String friendProfileShareText(String profileName, String link) {
    return 'Hey! $profileName hat dich zu Glass Trail eingeladen, der App um Getränke aufzuzeichnen, Statistiken auszuwerten und mit Freunden anzustoßen. Probier’s doch mal aus!\n\n$link';
  }

  @override
  String get friendProfileLinkCopied => 'Profillink kopiert.';

  @override
  String get friendIncomingRequest => 'Möchte befreundet sein';

  @override
  String get friendAccepted => 'Freund';

  @override
  String get friendRequestPending => 'Wartet auf Antwort';

  @override
  String get friendAlreadyFriends => 'Ihr seid bereits befreundet.';

  @override
  String get friendIncomingRequestFromProfile =>
      'Diese Person hat dir bereits eine Anfrage gesendet. Prüfe sie im Freunde-Bereich.';

  @override
  String get friendProfileSelf => 'Das ist dein eigener Freundes-Profillink.';

  @override
  String friendProfileRequestPrompt(String name) {
    return '$name möchte mit dir befreundet sein.';
  }

  @override
  String friendProfilePublicPrompt(String name) {
    return '$name möchte dein Freund in Glass Trail sein.';
  }

  @override
  String get friendStatsNotSharedTitle => 'Statistiken nicht geteilt';

  @override
  String friendStatsNotSharedBody(String name) {
    return '$name teilt aktuell keine Statistiken mit Freunden.';
  }

  @override
  String get friendStatsUnavailableTitle => 'Freundesprofil nicht verfügbar';

  @override
  String get friendStatsUnavailableBody =>
      'Dieses geteilte Freundesprofil ist nicht verfügbar oder wird nicht mehr mit dir geteilt.';

  @override
  String get addAsFriend => 'Als Freund hinzufügen';

  @override
  String get goToFeed => 'Zum Feed';

  @override
  String get withdrawFriendRequest => 'Zurückziehen';

  @override
  String get unfriend => 'Entfreunden';

  @override
  String unfriendConfirmTitle(String name) {
    return '$name entfreunden?';
  }

  @override
  String unfriendConfirmBody(String name) {
    return 'Du und $name seht dann die geteilten Aktivitäten des jeweils anderen nicht mehr. Du kannst später erneut eine Freundschaftsanfrage senden.';
  }

  @override
  String get friendProfileLinkInvalidTitle => 'Profillink nicht verfügbar';

  @override
  String get friendProfileLinkInvalidBody =>
      'Dieser Freundes-Profillink ist ungültig oder nicht mehr verfügbar.';

  @override
  String get notifications => 'Mitteilungen';

  @override
  String get notificationsTooltip => 'Mitteilungen';

  @override
  String get notificationsEmptyTitle => 'Aktuell keine Benachrichtigungen';

  @override
  String get notificationsEmptyBody =>
      'Sobald Freunde Getränke erfassen oder dir Freundschaftsanfragen senden, siehst du diese hier. Gelesene Benachrichtigungen werden nach 30 Tagen gelöscht, ungelesene nach 90 Tagen.';

  @override
  String notificationFriendRequestSentTitle(String name) {
    return '$name hat dir eine Freundschaftsanfrage gesendet';
  }

  @override
  String get notificationFriendRequestSentBody =>
      'Prüfe sie in deinem Freunde-Bereich.';

  @override
  String notificationFriendRequestAcceptedTitle(String name) {
    return '$name hat deine Freundschaftsanfrage angenommen';
  }

  @override
  String get notificationFriendRequestAcceptedBody =>
      'Ihr könnt jetzt gegenseitig geteilte Aktivitäten sehen.';

  @override
  String notificationFriendRequestRejectedTitle(String name) {
    return '$name hat deine Freundschaftsanfrage abgelehnt';
  }

  @override
  String get notificationFriendRequestRejectedBody =>
      'Du kannst später eine neue Anfrage senden.';

  @override
  String notificationFriendRemovedTitle(String name) {
    return '$name hat dich als Freund entfernt';
  }

  @override
  String get notificationFriendRemovedBody =>
      'Öffne deinen Freunde-Bereich, um deine Verbindungen zu prüfen.';

  @override
  String notificationFriendDrinkCheeredTitle(String name) {
    return '$name prostet dir zu 🍻';
  }

  @override
  String get notificationFriendDrinkCheeredBody => '';

  @override
  String notificationFriendDrinkLoggedTitle(String name, String drink) {
    return '$name trinkt $drink';
  }

  @override
  String notificationFriendDrinkLoggedBody(
    String commentLine,
    String locationAddressLine,
  ) {
    return '$commentLine\n$locationAddressLine';
  }

  @override
  String get notificationsMarkAllRead => 'Alle als gelesen markieren';

  @override
  String get customDrinks => 'Meine eigenen Getränke';

  @override
  String get addCustomDrinkAction => 'Eigenes Getränk hinzufügen';

  @override
  String get customDrinksEmptyTitle => 'Noch keine eigenen Getränke';

  @override
  String get customDrinksEmptyBody =>
      'Erstelle dein erstes eigenes Getränk, dann erscheint es hier.';

  @override
  String get statisticsHistoryEmptyTitle => 'Noch keine Historie';

  @override
  String get statisticsHistoryEmptyBody =>
      'Geloggte Drinks erscheinen hier als deine persönliche Historie.';

  @override
  String get roadmap => 'Als Nächstes geplant';

  @override
  String get about => 'Über die App';

  @override
  String get github => 'GitHub';

  @override
  String get roadmapBody => 'Als Nächstes kommen Erfolge.';

  @override
  String get beerWithMeImport => 'Beer With Me-Import';

  @override
  String get beerWithMeImportBody =>
      'Importiere einen Beer With Me-Export in deine GlassTrail-Historie. Bereits importierte Beer With Me-Einträge werden automatisch erkannt und übersprungen.';

  @override
  String get beerWithMePostSignUpTitle => 'Beer With Me-Verlauf importieren?';

  @override
  String get beerWithMePostSignUpBody =>
      'Wenn du bereits Getränke in Beer With Me erfasst hast, kannst du den Export jetzt importieren und deinen Verlauf in GlassTrail übernehmen.';

  @override
  String get beerWithMePostSignUpHint =>
      'Du kannst den Import später auch im Profil starten.';

  @override
  String get beerWithMeImportAction => 'Beer With Me-Export importieren';

  @override
  String get beerWithMeImportEmpty =>
      'Der ausgewählte Beer With Me-Export enthält keine Einträge.';

  @override
  String get beerWithMeImportInvalidFile =>
      'Die ausgewählte Datei ist kein gültiger Beer With Me-Export.';

  @override
  String get beerWithMeImportReadFailed =>
      'Der Beer With Me-Export konnte nicht gelesen werden.';

  @override
  String get beerWithMeImportConfirmTitle => 'Beer With Me-Export importieren?';

  @override
  String beerWithMeImportConfirmBody(int count) {
    return 'Dadurch werden $count Einträge in deine GlassTrail-Historie importiert.';
  }

  @override
  String beerWithMeImportProgress(int processed, int total) {
    return 'Importiere $processed von $total Einträgen';
  }

  @override
  String beerWithMeImportProgressDetails(
    int imported,
    int skipped,
    int errors,
  ) {
    return '$imported importiert, $skipped Duplikate, $errors Fehler';
  }

  @override
  String get beerWithMeImportCancelAction => 'Import abbrechen';

  @override
  String get beerWithMeImportCancelling =>
      'Wird nach dem aktuellen Eintrag abgebrochen...';

  @override
  String get beerWithMeImportResultTitle => 'Beer With Me-Import abgeschlossen';

  @override
  String beerWithMeImportResultCancelled(int processed, int total) {
    return 'Import nach $processed von $total Einträgen abgebrochen.';
  }

  @override
  String beerWithMeImportResultTotal(int count) {
    return 'Einträge insgesamt: $count';
  }

  @override
  String beerWithMeImportResultImported(int count) {
    return 'Erfolgreich importiert: $count';
  }

  @override
  String beerWithMeImportResultSkipped(int count) {
    return 'Als Duplikate übersprungen: $count';
  }

  @override
  String beerWithMeImportResultErrors(int count) {
    return 'Fehler: $count';
  }

  @override
  String get beerWithMeImportErrorListTitle => 'Fehlgeschlagene Einträge';

  @override
  String get beerWithMeImportInvalidEntry =>
      'Der Eintrag ist kein gültiges JSON-Objekt';

  @override
  String get beerWithMeImportMissingId => 'Beer With Me-ID fehlt';

  @override
  String get beerWithMeImportMissingGlassType =>
      'Beer With Me-Getränketyp fehlt';

  @override
  String get beerWithMeImportMissingTimestamp => 'Zeitstempel fehlt';

  @override
  String get beerWithMeImportInvalidTimestamp => 'Zeitstempel ist ungültig';

  @override
  String beerWithMeImportUnknownGlassType(String glassType) {
    return 'BeerWithMe-Typ „$glassType“ wird nicht unterstützt';
  }

  @override
  String beerWithMeImportMissingMappedDrink(String glassType) {
    return 'GlassTrail konnte das gemappte Getränk für „$glassType“ nicht finden.';
  }

  @override
  String get beerWithMeImportAlreadyImported =>
      'BeerWithMe-Eintrag wurde bereits importiert';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get handednessRight => 'Rechts';

  @override
  String get handednessLeft => 'Links';

  @override
  String get invalidRequired => 'Bitte alle Pflichtfelder ausfüllen.';

  @override
  String get emptyFilter => 'Keine Getränke für den aktuellen Filter gefunden.';

  @override
  String get launchingApp => 'Getränke und Einstellungen werden geladen.';

  @override
  String get welcomeToGlassTrail => 'Willkommen bei Glass Trail.';

  @override
  String get welcomeBack => 'Willkommen zurück.';

  @override
  String get profileUpdated => 'Profil aktualisiert.';

  @override
  String get changePasswordSuccess => 'Passwort geändert.';

  @override
  String get customDrinkSaved => 'Eigenes Getränk gespeichert.';

  @override
  String get customDrinkDeleted => 'Eigenes Getränk gelöscht.';

  @override
  String drinkLogged(String drink) {
    return '$drink erfasst.';
  }

  @override
  String get entryUpdated => 'Eintrag aktualisiert.';

  @override
  String get entryDeleted => 'Eintrag gelöscht.';

  @override
  String get friendRequestSent => 'Freundschaftsanfrage gesendet.';

  @override
  String get friendRequestAccepted => 'Freundschaftsanfrage angenommen.';

  @override
  String get friendRequestRejected => 'Freundschaftsanfrage abgelehnt.';

  @override
  String get friendRequestCanceled => 'Freundschaftsanfrage zurückgezogen.';

  @override
  String get friendRemoved => 'Freund entfernt.';

  @override
  String get somethingWentWrong =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get accountAlreadyExists =>
      'Es gibt bereits ein Konto mit dieser E-Mail-Adresse.';

  @override
  String get invalidCredentials => 'Die E-Mail oder das Passwort ist falsch.';

  @override
  String get changePasswordCurrentPasswordIncorrect =>
      'Das aktuelle Passwort ist nicht korrekt.';

  @override
  String get profileUpdateFailed =>
      'Das Profil konnte nicht aktualisiert werden.';

  @override
  String get changePasswordFailed =>
      'Das Passwort konnte nicht geändert werden.';

  @override
  String get deleteAccountSuccess => 'Konto gelöscht.';

  @override
  String get deleteAccountFailed => 'Das Konto konnte nicht gelöscht werden.';

  @override
  String get entryUpdateFailed =>
      'Der Getränkeeintrag konnte nicht aktualisiert werden.';

  @override
  String get entryDeleteFailed =>
      'Der Getränkeeintrag konnte nicht gelöscht werden.';

  @override
  String get friendProfileLinkInvalid => 'Der Profillink ist ungültig.';

  @override
  String get friendSelfRequestBlocked =>
      'Du kannst dich nicht selbst als Freund hinzufügen.';

  @override
  String get friendRequestAcceptFailed =>
      'Die Freundschaftsanfrage konnte nicht angenommen werden.';

  @override
  String get friendRequestRejectFailed =>
      'Die Freundschaftsanfrage konnte nicht abgelehnt werden.';

  @override
  String get friendRequestCancelFailed =>
      'Die Freundschaftsanfrage konnte nicht zurückgezogen werden.';

  @override
  String get friendRemoveFailed => 'Der Freund konnte nicht entfernt werden.';

  @override
  String get customDrinkDeleteFailed =>
      'Das eigene Getränk konnte nicht gelöscht werden.';

  @override
  String get customDrinkAlreadyExists =>
      'Du hast bereits ein eigenes Getränk mit diesem Namen.';

  @override
  String get signUpMissingUser =>
      'Die Registrierung hat keinen Benutzer zurückgegeben.';

  @override
  String get signUpConfirmationRequired =>
      'Die Registrierung bei Supabase war erfolgreich, aber die E-Mail-Bestätigung ist aktiviert. Bestätige zuerst die E-Mail und melde dich dann an.';

  @override
  String get beer => 'Bier';

  @override
  String get wine => 'Wein';

  @override
  String get sparklingWines => 'Schaumweine';

  @override
  String get longdrinks => 'Longdrinks';

  @override
  String get spirits => 'Spirituosen';

  @override
  String get shots => 'Shots';

  @override
  String get cocktails => 'Cocktails';

  @override
  String get appleWines => 'Apfelweine';

  @override
  String get nonAlcoholic => 'Alkoholfrei';

  @override
  String dayLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage',
      one: 'Tag',
    );
    return '$_temp0';
  }

  @override
  String get achievementFamilyTotalDrinksTitle => 'Prosit-Parade';

  @override
  String get achievementFamilyTotalDrinksLevel1Title => 'Erster Einschenk';

  @override
  String get achievementFamilyTotalDrinksLevel1Description =>
      'Logge dein erstes Getränk.';

  @override
  String get achievementFamilyTotalDrinksLevel10Title => 'Schluckstarter';

  @override
  String get achievementFamilyTotalDrinksLevel10Description =>
      'Logge 10 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel25Title => 'Gläsersammler';

  @override
  String get achievementFamilyTotalDrinksLevel25Description =>
      'Logge 25 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel50Title => 'Schluckstratege';

  @override
  String get achievementFamilyTotalDrinksLevel50Description =>
      'Logge 50 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel100Title => 'Prositprofi';

  @override
  String get achievementFamilyTotalDrinksLevel100Description =>
      'Logge 100 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel200Title => 'Pegelpfadfinder';

  @override
  String get achievementFamilyTotalDrinksLevel200Description =>
      'Logge 200 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel300Title => 'Prosttaktiker';

  @override
  String get achievementFamilyTotalDrinksLevel300Description =>
      'Logge 300 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel400Title => 'Feierfürst';

  @override
  String get achievementFamilyTotalDrinksLevel400Description =>
      'Logge 400 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel500Title => 'Partypatron';

  @override
  String get achievementFamilyTotalDrinksLevel500Description =>
      'Logge 500 Getränke.';

  @override
  String get achievementFamilyTotalDrinksLevel1000Title => 'Prositlegende';

  @override
  String get achievementFamilyTotalDrinksLevel1000Description =>
      'Logge 1000 Getränke.';

  @override
  String get achievementFamilyStreaksTitle => 'Dauerdurst';

  @override
  String get achievementFamilyStreaksLevel3Title => 'Serienstart';

  @override
  String get achievementFamilyStreaksLevel3Description =>
      'Erreiche eine 3-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel7Title => 'Wochenwunder';

  @override
  String get achievementFamilyStreaksLevel7Description =>
      'Erreiche eine 7-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel14Title => 'Zweiwochenzauber';

  @override
  String get achievementFamilyStreaksLevel14Description =>
      'Erreiche eine 14-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel30Title => 'Dreißig-Tage-Drang';

  @override
  String get achievementFamilyStreaksLevel30Description =>
      'Erreiche eine 30-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel60Title => 'Ausdauer-Ass';

  @override
  String get achievementFamilyStreaksLevel60Description =>
      'Erreiche eine 60-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel90Title => 'Neunziger-Navigator';

  @override
  String get achievementFamilyStreaksLevel90Description =>
      'Erreiche eine 90-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel180Title => 'Ausdauer-Experte';

  @override
  String get achievementFamilyStreaksLevel180Description =>
      'Erreiche eine 180-Tage-Serie.';

  @override
  String get achievementFamilyStreaksLevel365Title => 'Dauerlegende';

  @override
  String get achievementFamilyStreaksLevel365Description =>
      'Erreiche eine 365-Tage-Serie.';

  @override
  String get achievementFamilyBeerTitle => 'Bierjagd';

  @override
  String get achievementFamilyBeerLevel10Title => 'Bierneuling';

  @override
  String get achievementFamilyBeerLevel10Description => 'Logge 10 Biere.';

  @override
  String get achievementFamilyBeerLevel25Title => 'Schaumfreund';

  @override
  String get achievementFamilyBeerLevel25Description => 'Logge 25 Biere.';

  @override
  String get achievementFamilyBeerLevel50Title => 'Bierblicker';

  @override
  String get achievementFamilyBeerLevel50Description => 'Logge 50 Biere.';

  @override
  String get achievementFamilyBeerLevel100Title => 'Hopfenheld';

  @override
  String get achievementFamilyBeerLevel100Description => 'Logge 100 Biere.';

  @override
  String get achievementFamilyBeerLevel200Title => 'Bierboss';

  @override
  String get achievementFamilyBeerLevel200Description => 'Logge 200 Biere.';

  @override
  String get achievementFamilyBeerLevel300Title => 'Hopfenhauptmann';

  @override
  String get achievementFamilyBeerLevel300Description => 'Logge 300 Biere.';

  @override
  String get achievementFamilyBeerLevel400Title => 'Bierbaron';

  @override
  String get achievementFamilyBeerLevel400Description => 'Logge 400 Biere.';

  @override
  String get achievementFamilyBeerLevel500Title => 'Bierlegende';

  @override
  String get achievementFamilyBeerLevel500Description => 'Logge 500 Biere.';

  @override
  String get achievementFamilyBeerLevel1000Title => 'Bierunsterblich';

  @override
  String get achievementFamilyBeerLevel1000Description => 'Logge 1000 Biere.';

  @override
  String get achievementFamilyWineTitle => 'Vino-Voyage';

  @override
  String get achievementFamilyWineLevel10Title => 'Traubengast';

  @override
  String get achievementFamilyWineLevel10Description => 'Logge 10 Weine.';

  @override
  String get achievementFamilyWineLevel25Title => 'Vino-Visitor';

  @override
  String get achievementFamilyWineLevel25Description => 'Logge 25 Weine.';

  @override
  String get achievementFamilyWineLevel50Title => 'Traubensammler';

  @override
  String get achievementFamilyWineLevel50Description => 'Logge 50 Weine.';

  @override
  String get achievementFamilyWineLevel100Title => 'Korkkapitän';

  @override
  String get achievementFamilyWineLevel100Description => 'Logge 100 Weine.';

  @override
  String get achievementFamilyWineLevel200Title => 'Vino-Virtuose';

  @override
  String get achievementFamilyWineLevel200Description => 'Logge 200 Weine.';

  @override
  String get achievementFamilyWineLevel300Title => 'Traubenguru';

  @override
  String get achievementFamilyWineLevel300Description => 'Logge 300 Weine.';

  @override
  String get achievementFamilyWineLevel400Title => 'Weinzauberer';

  @override
  String get achievementFamilyWineLevel400Description => 'Logge 400 Weine.';

  @override
  String get achievementFamilyWineLevel500Title => 'Vino-VIP';

  @override
  String get achievementFamilyWineLevel500Description => 'Logge 500 Weine.';

  @override
  String get achievementFamilyWineLevel1000Title => 'Weinwunder';

  @override
  String get achievementFamilyWineLevel1000Description => 'Logge 1000 Weine.';

  @override
  String get achievementFamilySparklingWinesTitle => 'Perlparade';

  @override
  String get achievementFamilySparklingWinesLevel10Title => 'Perlenstarter';

  @override
  String get achievementFamilySparklingWinesLevel10Description =>
      'Logge 10 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel25Title => 'Prickelfreund';

  @override
  String get achievementFamilySparklingWinesLevel25Description =>
      'Logge 25 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel50Title => 'Perlensucher';

  @override
  String get achievementFamilySparklingWinesLevel50Description =>
      'Logge 50 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel100Title => 'Korkkommandant';

  @override
  String get achievementFamilySparklingWinesLevel100Description =>
      'Logge 100 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel200Title => 'Cuvée-Kapitän';

  @override
  String get achievementFamilySparklingWinesLevel200Description =>
      'Logge 200 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel300Title => 'Perlenfürst';

  @override
  String get achievementFamilySparklingWinesLevel300Description =>
      'Logge 300 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel400Title => 'Cuvée-Könner';

  @override
  String get achievementFamilySparklingWinesLevel400Description =>
      'Logge 400 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel500Title => 'Prickelruhm';

  @override
  String get achievementFamilySparklingWinesLevel500Description =>
      'Logge 500 Schaumweine.';

  @override
  String get achievementFamilySparklingWinesLevel1000Title => 'Perlenlegende';

  @override
  String get achievementFamilySparklingWinesLevel1000Description =>
      'Logge 1000 Schaumweine.';

  @override
  String get achievementFamilyLongdrinksTitle => 'Mixmeister-Marsch';

  @override
  String get achievementFamilyLongdrinksLevel10Title => 'Longdrink-Lehrling';

  @override
  String get achievementFamilyLongdrinksLevel10Description =>
      'Logge 10 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel25Title => 'Mixkumpel';

  @override
  String get achievementFamilyLongdrinksLevel25Description =>
      'Logge 25 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel50Title => 'Longdrink-Loyalist';

  @override
  String get achievementFamilyLongdrinksLevel50Description =>
      'Logge 50 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel100Title => 'Mixmeister';

  @override
  String get achievementFamilyLongdrinksLevel100Description =>
      'Logge 100 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel200Title => 'Longdrink-Lotse';

  @override
  String get achievementFamilyLongdrinksLevel200Description =>
      'Logge 200 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel300Title => 'Mixmonarch';

  @override
  String get achievementFamilyLongdrinksLevel300Description =>
      'Logge 300 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel400Title => 'Mixmogul';

  @override
  String get achievementFamilyLongdrinksLevel400Description =>
      'Logge 400 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel500Title => 'Gießgraf';

  @override
  String get achievementFamilyLongdrinksLevel500Description =>
      'Logge 500 Longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel1000Title => 'Mixlegende';

  @override
  String get achievementFamilyLongdrinksLevel1000Description =>
      'Logge 1000 Longdrinks.';

  @override
  String get achievementFamilySpiritsTitle => 'Spirituosen-Spurt';

  @override
  String get achievementFamilySpiritsLevel10Title => 'Spirituosenstarter';

  @override
  String get achievementFamilySpiritsLevel10Description =>
      'Logge 10 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel25Title => 'Pegelpirat';

  @override
  String get achievementFamilySpiritsLevel25Description =>
      'Logge 25 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel50Title => 'Pegelpartner';

  @override
  String get achievementFamilySpiritsLevel50Description =>
      'Logge 50 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel100Title => 'Spirituosenprofi';

  @override
  String get achievementFamilySpiritsLevel100Description =>
      'Logge 100 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel200Title => 'Pegelpionier';

  @override
  String get achievementFamilySpiritsLevel200Description =>
      'Logge 200 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel300Title => 'Purprinz';

  @override
  String get achievementFamilySpiritsLevel300Description =>
      'Logge 300 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel400Title => 'Spirituosenstar';

  @override
  String get achievementFamilySpiritsLevel400Description =>
      'Logge 400 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel500Title => 'Pegelprestige';

  @override
  String get achievementFamilySpiritsLevel500Description =>
      'Logge 500 Spirituosen.';

  @override
  String get achievementFamilySpiritsLevel1000Title => 'Spirituosenlegende';

  @override
  String get achievementFamilySpiritsLevel1000Description =>
      'Logge 1000 Spirituosen.';

  @override
  String get achievementFamilyShotsTitle => 'Kurzer-Kick';

  @override
  String get achievementFamilyShotsLevel10Title => 'Kurzer-Könner';

  @override
  String get achievementFamilyShotsLevel10Description => 'Logge 10 Shots.';

  @override
  String get achievementFamilyShotsLevel25Title => 'Shotspäher';

  @override
  String get achievementFamilyShotsLevel25Description => 'Logge 25 Shots.';

  @override
  String get achievementFamilyShotsLevel50Title => 'Shotsprinter';

  @override
  String get achievementFamilyShotsLevel50Description => 'Logge 50 Shots.';

  @override
  String get achievementFamilyShotsLevel100Title => 'Kurzer-Kapitän';

  @override
  String get achievementFamilyShotsLevel100Description => 'Logge 100 Shots.';

  @override
  String get achievementFamilyShotsLevel200Title => 'Shotfürst';

  @override
  String get achievementFamilyShotsLevel200Description => 'Logge 200 Shots.';

  @override
  String get achievementFamilyShotsLevel300Title => 'Kurzer-König';

  @override
  String get achievementFamilyShotsLevel300Description => 'Logge 300 Shots.';

  @override
  String get achievementFamilyShotsLevel400Title => 'Shotstar';

  @override
  String get achievementFamilyShotsLevel400Description => 'Logge 400 Shots.';

  @override
  String get achievementFamilyShotsLevel500Title => 'Mini-Wirbel';

  @override
  String get achievementFamilyShotsLevel500Description => 'Logge 500 Shots.';

  @override
  String get achievementFamilyShotsLevel1000Title => 'Shotunsterblich';

  @override
  String get achievementFamilyShotsLevel1000Description => 'Logge 1000 Shots.';

  @override
  String get achievementFamilyCocktailsTitle => 'Cocktail-Karussell';

  @override
  String get achievementFamilyCocktailsLevel10Title => 'Cocktail-Cadet';

  @override
  String get achievementFamilyCocktailsLevel10Description =>
      'Logge 10 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel25Title => 'Mix-Muse';

  @override
  String get achievementFamilyCocktailsLevel25Description =>
      'Logge 25 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel50Title => 'Glasglanz';

  @override
  String get achievementFamilyCocktailsLevel50Description =>
      'Logge 50 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel100Title => 'Shakerprofi';

  @override
  String get achievementFamilyCocktailsLevel100Description =>
      'Logge 100 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel200Title => 'Cocktail-Charmeur';

  @override
  String get achievementFamilyCocktailsLevel200Description =>
      'Logge 200 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel300Title => 'Glasguru';

  @override
  String get achievementFamilyCocktailsLevel300Description =>
      'Logge 300 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel400Title => 'Mixmajestät';

  @override
  String get achievementFamilyCocktailsLevel400Description =>
      'Logge 400 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel500Title => 'Shakerlegende';

  @override
  String get achievementFamilyCocktailsLevel500Description =>
      'Logge 500 Cocktails.';

  @override
  String get achievementFamilyCocktailsLevel1000Title => 'Cocktail-Ikone';

  @override
  String get achievementFamilyCocktailsLevel1000Description =>
      'Logge 1000 Cocktails.';

  @override
  String get achievementFamilyAppleWinesTitle => 'Cider-Club';

  @override
  String get achievementFamilyAppleWinesLevel10Title => 'Apfelazubi';

  @override
  String get achievementFamilyAppleWinesLevel10Description =>
      'Logge 10 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel25Title => 'Ciderspäher';

  @override
  String get achievementFamilyAppleWinesLevel25Description =>
      'Logge 25 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel50Title => 'Ciderjäger';

  @override
  String get achievementFamilyAppleWinesLevel50Description =>
      'Logge 50 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel100Title => 'Apfel-Ass';

  @override
  String get achievementFamilyAppleWinesLevel100Description =>
      'Logge 100 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel200Title => 'Ciderkapitän';

  @override
  String get achievementFamilyAppleWinesLevel200Description =>
      'Logge 200 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel300Title => 'Apfelaristokrat';

  @override
  String get achievementFamilyAppleWinesLevel300Description =>
      'Logge 300 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel400Title => 'Ciderkrone';

  @override
  String get achievementFamilyAppleWinesLevel400Description =>
      'Logge 400 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel500Title => 'Apfelautorität';

  @override
  String get achievementFamilyAppleWinesLevel500Description =>
      'Logge 500 Apfelweine.';

  @override
  String get achievementFamilyAppleWinesLevel1000Title => 'Cider-Ikone';

  @override
  String get achievementFamilyAppleWinesLevel1000Description =>
      'Logge 1000 Apfelweine.';

  @override
  String get achievementFamilyNonAlcoholicTitle => 'Promillefrei-Parade';

  @override
  String get achievementFamilyNonAlcoholicLevel10Title => 'Alkoholfrei-Auftakt';

  @override
  String get achievementFamilyNonAlcoholicLevel10Description =>
      'Logge 10 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel25Title =>
      'Null-Pegel-Navigator';

  @override
  String get achievementFamilyNonAlcoholicLevel25Description =>
      'Logge 25 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel50Title => 'Hydroheld';

  @override
  String get achievementFamilyNonAlcoholicLevel50Description =>
      'Logge 50 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel100Title => 'Promillefrei-Profi';

  @override
  String get achievementFamilyNonAlcoholicLevel100Description =>
      'Logge 100 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel200Title => 'Null-Kapitän';

  @override
  String get achievementFamilyNonAlcoholicLevel200Description =>
      'Logge 200 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel300Title => 'Alkoholfrei-Artist';

  @override
  String get achievementFamilyNonAlcoholicLevel300Description =>
      'Logge 300 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel400Title => 'Null-Meister';

  @override
  String get achievementFamilyNonAlcoholicLevel400Description =>
      'Logge 400 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel500Title => 'Null-Promille-Star';

  @override
  String get achievementFamilyNonAlcoholicLevel500Description =>
      'Logge 500 alkoholfreie Getränke.';

  @override
  String get achievementFamilyNonAlcoholicLevel1000Title =>
      'Alkoholfrei-Allstar';

  @override
  String get achievementFamilyNonAlcoholicLevel1000Description =>
      'Logge 1000 alkoholfreie Getränke.';

  @override
  String get achievementFamilyHomeTitle => 'Heimspiel';

  @override
  String get achievementFamilyHomeLevel1Title => 'Heimauftakt';

  @override
  String get achievementFamilyHomeLevel1Description =>
      'Logge ein Getränk zu Hause.';

  @override
  String get achievementFamilyHomeLevel10Title => 'Daheimstarter';

  @override
  String get achievementFamilyHomeLevel10Description =>
      'Logge 10 Getränke zu Hause.';

  @override
  String get achievementFamilyHomeLevel25Title => 'Sofakumpel';

  @override
  String get achievementFamilyHomeLevel25Description =>
      'Logge 25 Getränke zu Hause.';

  @override
  String get achievementFamilyHomeLevel50Title => 'Heimheld';

  @override
  String get achievementFamilyHomeLevel50Description =>
      'Logge 50 Getränke zu Hause.';

  @override
  String get achievementFamilyHomeLevel100Title => 'Daheimfürst';

  @override
  String get achievementFamilyHomeLevel100Description =>
      'Logge 100 Getränke zu Hause.';

  @override
  String get achievementFamilyWorkTitle => 'Büro-Bilanz';

  @override
  String get achievementFamilyWorkLevel1Title => 'Arbeitsauftakt';

  @override
  String get achievementFamilyWorkLevel1Description =>
      'Logge ein Getränk bei der Arbeit.';

  @override
  String get achievementFamilyWorkLevel10Title => 'Bürobeginner';

  @override
  String get achievementFamilyWorkLevel10Description =>
      'Logge 10 Getränke bei der Arbeit.';

  @override
  String get achievementFamilyWorkLevel25Title => 'Bürooffizier';

  @override
  String get achievementFamilyWorkLevel25Description =>
      'Logge 25 Getränke bei der Arbeit.';

  @override
  String get achievementFamilyWorkLevel50Title => 'Arbeitsass';

  @override
  String get achievementFamilyWorkLevel50Description =>
      'Logge 50 Getränke bei der Arbeit.';

  @override
  String get achievementFamilyWorkLevel100Title => 'Büroikone';

  @override
  String get achievementFamilyWorkLevel100Description =>
      'Logge 100 Getränke bei der Arbeit.';

  @override
  String get achievementFamilyTravelCountriesTitle => 'Pässeparade';

  @override
  String get achievementFamilyTravelCountriesLevel3Title => 'Passpionier';

  @override
  String get achievementFamilyTravelCountriesLevel3Description =>
      'Logge Drinks in 3 Ländern.';

  @override
  String get achievementFamilyTravelCountriesLevel5Title => 'Grenzfreund';

  @override
  String get achievementFamilyTravelCountriesLevel5Description =>
      'Logge Drinks in 5 Ländern.';

  @override
  String get achievementFamilyTravelCountriesLevel10Title => 'Länderläufer';

  @override
  String get achievementFamilyTravelCountriesLevel10Description =>
      'Logge Drinks in 10 Ländern.';

  @override
  String get achievementFamilyTravelCountriesLevel15Title => 'Kartenkönner';

  @override
  String get achievementFamilyTravelCountriesLevel15Description =>
      'Logge Drinks in 15 Ländern.';

  @override
  String get achievementFamilyTravelCountriesLevel20Title => 'Spurensucher';

  @override
  String get achievementFamilyTravelCountriesLevel20Description =>
      'Logge Drinks in 20 Ländern.';

  @override
  String get achievementFamilyTravelCountriesLevel30Title => 'Weltwanderer';

  @override
  String get achievementFamilyTravelCountriesLevel30Description =>
      'Logge Drinks in 30 Ländern.';

  @override
  String get achievementFamilyTravelCountriesLevel50Title =>
      'Weltenbummler-Legende';

  @override
  String get achievementFamilyTravelCountriesLevel50Description =>
      'Logge Drinks in 50 Ländern.';

  @override
  String get achievementOccasionBirthdayTitle => 'Geburtstagsglanz';

  @override
  String get achievementOccasionBirthdayDescription =>
      'Logge ein Getränk an deinem Geburtstag.';

  @override
  String get achievementOccasionFirstSipAnniversaryTitle => 'Jubiläumsschluck';

  @override
  String get achievementOccasionFirstSipAnniversaryDescription =>
      'Logge ein Getränk am Jahrestag deines ersten bekannten Drinks.';

  @override
  String get achievementOccasionNewYearTitle => 'Neujahrs-Nachschlag';

  @override
  String get achievementOccasionNewYearDescription =>
      'Logge ein Getränk an Silvester oder Neujahr.';

  @override
  String get achievementOccasionChristmasTitle => 'Weihnachtsklang';

  @override
  String get achievementOccasionChristmasDescription =>
      'Logge ein Getränk zwischen dem 24. und 26. Dezember.';

  @override
  String get achievementOccasionEasterTitle => 'Oster-Prosit';

  @override
  String get achievementOccasionEasterDescription =>
      'Logge ein Getränk zwischen Karfreitag und Ostermontag.';

  @override
  String get achievementOccasionHalloweenTitle => 'Schreckensschluck';

  @override
  String get achievementOccasionHalloweenDescription =>
      'Logge ein Getränk an Halloween.';

  @override
  String get achievementOccasionStPatricksDayTitle => 'Glücksgerste';

  @override
  String get achievementOccasionStPatricksDayDescription =>
      'Logge am 17. März ein Bier.';

  @override
  String get achievementOccasionOktoberfestTitle => 'Festbierfieber';

  @override
  String get achievementOccasionOktoberfestDescription =>
      'Logge während des Oktoberfests ein Bier.';

  @override
  String get achievementOccasionCarnivalTitle => 'Konfetti-Klirren';

  @override
  String get achievementOccasionCarnivalDescription =>
      'Logge während des Karnevals ein Getränk.';

  @override
  String get achievementCountryDeTitle => 'Biergarten-Bingo';

  @override
  String get achievementCountryDeLabel => 'Deutschland';

  @override
  String get achievementCountryDeDescription =>
      'Logge ein Getränk in Deutschland.';

  @override
  String get achievementCountryNlTitle => 'Grachtenklirren';

  @override
  String get achievementCountryNlLabel => 'Niederlande';

  @override
  String get achievementCountryNlDescription =>
      'Logge ein Getränk in den Niederlanden.';

  @override
  String get achievementCountryBeTitle => 'Belgien-Boost';

  @override
  String get achievementCountryBeLabel => 'Belgien';

  @override
  String get achievementCountryBeDescription => 'Logge ein Getränk in Belgien.';

  @override
  String get achievementCountryLuTitle => 'Großherzog-Glanz';

  @override
  String get achievementCountryLuLabel => 'Luxemburg';

  @override
  String get achievementCountryLuDescription =>
      'Logge ein Getränk in Luxemburg.';

  @override
  String get achievementCountryFrTitle => 'Frankreich-Flair';

  @override
  String get achievementCountryFrLabel => 'Frankreich';

  @override
  String get achievementCountryFrDescription =>
      'Logge ein Getränk in Frankreich.';

  @override
  String get achievementCountryEsTitle => 'Fiesta-Fieber';

  @override
  String get achievementCountryEsLabel => 'Spanien';

  @override
  String get achievementCountryEsDescription => 'Logge ein Getränk in Spanien.';

  @override
  String get achievementCountryPtTitle => 'Portugal-Prost';

  @override
  String get achievementCountryPtLabel => 'Portugal';

  @override
  String get achievementCountryPtDescription =>
      'Logge ein Getränk in Portugal.';

  @override
  String get achievementCountryItTitle => 'Aperitivo-Ankunft';

  @override
  String get achievementCountryItLabel => 'Italien';

  @override
  String get achievementCountryItDescription => 'Logge ein Getränk in Italien.';

  @override
  String get achievementCountryAtTitle => 'Alpenglühen';

  @override
  String get achievementCountryAtLabel => 'Österreich';

  @override
  String get achievementCountryAtDescription =>
      'Logge ein Getränk in Österreich.';

  @override
  String get achievementCountryChTitle => 'Gipfel-Prost';

  @override
  String get achievementCountryChLabel => 'Schweiz';

  @override
  String get achievementCountryChDescription =>
      'Logge ein Getränk in der Schweiz.';

  @override
  String get achievementCountryPlTitle => 'Polen-Prost';

  @override
  String get achievementCountryPlLabel => 'Polen';

  @override
  String get achievementCountryPlDescription => 'Logge ein Getränk in Polen.';

  @override
  String get achievementCountryCzTitle => 'Tschechien-Toast';

  @override
  String get achievementCountryCzLabel => 'Tschechien';

  @override
  String get achievementCountryCzDescription =>
      'Logge ein Getränk in Tschechien.';

  @override
  String get achievementCountryIeTitle => 'Smaragdschluck';

  @override
  String get achievementCountryIeLabel => 'Irland';

  @override
  String get achievementCountryIeDescription => 'Logge ein Getränk in Irland.';

  @override
  String get achievementCountryGbTitle => 'Königreich-Klirren';

  @override
  String get achievementCountryGbLabel => 'Vereinigtes Königreich';

  @override
  String get achievementCountryGbDescription =>
      'Logge ein Getränk im Vereinigten Königreich.';

  @override
  String get achievementCountryDkTitle => 'Dänen-Durst';

  @override
  String get achievementCountryDkLabel => 'Dänemark';

  @override
  String get achievementCountryDkDescription =>
      'Logge ein Getränk in Dänemark.';

  @override
  String get achievementCountrySeTitle => 'Skandi-Schwung';

  @override
  String get achievementCountrySeLabel => 'Schweden';

  @override
  String get achievementCountrySeDescription =>
      'Logge ein Getränk in Schweden.';

  @override
  String get achievementCountryNoTitle => 'Fjord-Fieber';

  @override
  String get achievementCountryNoLabel => 'Norwegen';

  @override
  String get achievementCountryNoDescription =>
      'Logge ein Getränk in Norwegen.';

  @override
  String get achievementCountryFiTitle => 'Sauna-Schluck';

  @override
  String get achievementCountryFiLabel => 'Finnland';

  @override
  String get achievementCountryFiDescription =>
      'Logge ein Getränk in Finnland.';

  @override
  String get achievementCountryGrTitle => 'Ägäis-Anstoß';

  @override
  String get achievementCountryGrLabel => 'Griechenland';

  @override
  String get achievementCountryGrDescription =>
      'Logge ein Getränk in Griechenland.';

  @override
  String get achievementCountryHrTitle => 'Adria-Anstoß';

  @override
  String get achievementCountryHrLabel => 'Kroatien';

  @override
  String get achievementCountryHrDescription =>
      'Logge ein Getränk in Kroatien.';

  @override
  String get achievementCountryHuTitle => 'Donau-Durst';

  @override
  String get achievementCountryHuLabel => 'Ungarn';

  @override
  String get achievementCountryHuDescription => 'Logge ein Getränk in Ungarn.';

  @override
  String get achievementCountryRoTitle => 'Karpaten-Klirren';

  @override
  String get achievementCountryRoLabel => 'Rumänien';

  @override
  String get achievementCountryRoDescription =>
      'Logge ein Getränk in Rumänien.';

  @override
  String get achievementCountryTrTitle => 'Bosporus-Boost';

  @override
  String get achievementCountryTrLabel => 'Türkei';

  @override
  String get achievementCountryTrDescription =>
      'Logge ein Getränk in der Türkei.';

  @override
  String get achievementCountryUsTitle => 'Sterne & Schluck';

  @override
  String get achievementCountryUsLabel => 'Vereinigte Staaten';

  @override
  String get achievementCountryUsDescription =>
      'Logge ein Getränk in den Vereinigten Staaten.';

  @override
  String get achievementCountryJpTitle => 'Sakura-Schluck';

  @override
  String get achievementCountryJpLabel => 'Japan';

  @override
  String get achievementCountryJpDescription => 'Logge ein Getränk in Japan.';

  @override
  String get achievementCountrySiTitle => 'Drachen-Durst';

  @override
  String get achievementCountrySiLabel => 'Slowenien';

  @override
  String get achievementCountrySiDescription =>
      'Logge ein Getränk in Slowenien.';

  @override
  String get achievementCountryMcTitle => 'Monaco-Moment';

  @override
  String get achievementCountryMcLabel => 'Monaco';

  @override
  String get achievementCountryMcDescription => 'Logge ein Getränk in Monaco.';

  @override
  String get achievementsTab => 'Achievements';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementsBadgesEarned => 'Badges verdient';

  @override
  String get achievementsFilterAll => 'Alle';

  @override
  String get achievementsFilterUnlocked => 'Freigeschaltet';

  @override
  String get achievementsFilterLocked => 'Gesperrt';

  @override
  String get achievementsRecentlyUnlocked => 'Kürzlich freigeschaltet';

  @override
  String get achievementsViewAll => 'Alle ansehen';

  @override
  String get achievementsSetupRequired => 'Einrichtung erforderlich';

  @override
  String get achievementsSetUpNow => 'Jetzt einrichten';

  @override
  String get achievementsEarnableToday => 'Heute erreichbar';

  @override
  String get achievementsNextEligible => 'Nächstes Zeitfenster';

  @override
  String get achievementsUnlocked => 'Freigeschaltet';

  @override
  String get achievementsLocked => 'Gesperrt';

  @override
  String get achievementsCompleted => 'Abgeschlossen';

  @override
  String get achievementsSummaryBackfillTitle => 'Achievements freigeschaltet';

  @override
  String get shareAchievements => 'Achievements mit Freunden teilen';

  @override
  String get shareAchievementsBody =>
      'Bestätigte Freunde können deine verdienten Badges in der App sehen.';

  @override
  String get achievementReminders => 'Achievement-Erinnerungen';

  @override
  String get achievementRemindersBody =>
      'Erhalte Push-Erinnerungen für jährliche und anlassbezogene Badges.';

  @override
  String get savedPlacesTitle => 'Orte';

  @override
  String get savedPlacesHome => 'Zuhause';

  @override
  String get savedPlacesWork => 'Arbeit';

  @override
  String get savedPlacesArchived => 'Frühere Orte';

  @override
  String achievementsSummaryBackfillBody(int count) {
    return 'Du hast $count Badges aus deinem Verlauf freigeschaltet.';
  }

  @override
  String achievementsOverflowUnlocked(int count) {
    return '+$count weitere freigeschaltet';
  }
}
