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
  String get feedBody =>
      'V1 zeigt deine persönliche Historie. Freunde, Kommentare und Cheers folgen später.';

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
  String get notificationsEmptyTitle => 'Noch keine Mitteilungen';

  @override
  String get notificationsEmptyBody =>
      'Freundschaftsanfragen und Aktualisierungen erscheinen hier.';

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
  String get roadmapBody =>
      'Freunde, Social Feed und Erfolge sind im Plan, aber bewusst nicht Teil von V1.';

  @override
  String get beerWithMeImport => 'Beer With Me-Import';

  @override
  String get beerWithMeImportBody =>
      'Importiere einen Beer With Me-Export in deine GlassTrail-Historie. Bereits importierte Beer With Me-Einträge werden automatisch erkannt und übersprungen.';

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
  String get profileUpdateFailed =>
      'Das Profil konnte nicht aktualisiert werden.';

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
}
