// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Glass Trail';

  @override
  String get feed => 'Feed';

  @override
  String get statistics => 'Statistics';

  @override
  String get statisticsOverview => 'Overview';

  @override
  String get statisticsMap => 'Map';

  @override
  String get statisticsGallery => 'Gallery';

  @override
  String get bar => 'Bar';

  @override
  String get profile => 'Profile';

  @override
  String get welcomeTitle => 'Track every glass';

  @override
  String get welcomeBody =>
      'Log drinks, spot streaks, and build a better picture of your habits.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Display name';

  @override
  String get birthday => 'Birthday';

  @override
  String get optional => 'Optional';

  @override
  String get removeBirthday => 'Remove birthday';

  @override
  String get pickPhoto => 'Pick photo';

  @override
  String get pickPhotoSource => 'Choose photo source';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get addDrink => 'Add drink';

  @override
  String get searchDrinks => 'Search drinks';

  @override
  String get recentDrinks => 'Recent drinks';

  @override
  String get catalog => 'Drink catalog';

  @override
  String get location => 'Location';

  @override
  String get saveLocationForEntry => 'Save location for this entry';

  @override
  String get locationLoading => 'Looking up your current location…';

  @override
  String get locationUnavailable =>
      'Location unavailable. The entry can still be saved.';

  @override
  String get locationAddressUnavailable =>
      'Address unavailable. Coordinates will still be saved.';

  @override
  String get locationDisabledForEntry => 'Location disabled for this entry.';

  @override
  String get locationApproximateWarning =>
      'Android is only providing approximate location. Enable precise location in app settings for better accuracy.';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get comment => 'Comment';

  @override
  String get confirmDrink => 'Save entry';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get pending => 'Pending';

  @override
  String get share => 'Share';

  @override
  String get copyLink => 'Copy link';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String get deleteEntryPrompt =>
      'Delete this drink entry? The saved comment and photo will be removed too.';

  @override
  String get createCustomDrink => 'Create custom drink';

  @override
  String get editCustomDrink => 'Edit custom drink';

  @override
  String get deleteCustomDrink => 'Delete custom drink';

  @override
  String get deleteCustomDrinkPrompt =>
      'Delete this custom drink? Existing history entries will remain available.';

  @override
  String get drinkName => 'Drink name';

  @override
  String get category => 'Category';

  @override
  String get volume => 'Volume';

  @override
  String get appUpdatedTitle => 'App updated';

  @override
  String appUpdatedBody(String appName, String version) {
    return '$appName was just updated to $version. Would you like to read the changelog?';
  }

  @override
  String get feedHeadline => 'Your activity feed';

  @override
  String get feedBody =>
      'This V1 shows your personal history. Friends, comments, and cheers arrive later.';

  @override
  String get noEntries => 'No drinks logged yet.';

  @override
  String get startLogging => 'Start by logging your first drink.';

  @override
  String get weeklyTotal => 'Weekly';

  @override
  String get monthlyTotal => 'Monthly';

  @override
  String get yearlyTotal => 'Yearly';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get bestStreak => 'Best streak';

  @override
  String get thisWeek => 'This week';

  @override
  String get streakPromptStart => 'Log a drink now to start your streak.';

  @override
  String get streakPromptKeepAlive =>
      'Log a drink now to keep your streak alive.';

  @override
  String get streakPromptStartedToday =>
      'Very good! You started your streak today.';

  @override
  String get streakPromptContinuedToday =>
      'Very good! You continued your streak today.';

  @override
  String get weekdayMondayShort => 'M';

  @override
  String get weekdayTuesdayShort => 'T';

  @override
  String get weekdayWednesdayShort => 'W';

  @override
  String get weekdayThursdayShort => 'T';

  @override
  String get weekdayFridayShort => 'F';

  @override
  String get weekdaySaturdayShort => 'S';

  @override
  String get weekdaySundayShort => 'S';

  @override
  String get categoryBreakdown => 'Category breakdown';

  @override
  String get history => 'History';

  @override
  String get statisticsMapEmptyTitle => 'No drinks with location yet';

  @override
  String get statisticsMapEmptyBody =>
      'Enable location while logging drinks so they can appear here on the map.';

  @override
  String get statisticsGalleryEmptyTitle => 'No drink photos yet';

  @override
  String get statisticsGalleryEmptyBody =>
      'Photos from logged drinks will appear here automatically.';

  @override
  String get totalDrinks => 'Total drinks';

  @override
  String get settings => 'Settings';

  @override
  String get globalDrinks => 'Global drinks';

  @override
  String get barDrinkSortingTab => 'Drink sorting';

  @override
  String get barCustomDrinksTab => 'My drinks';

  @override
  String get barGlobalDrinksBody =>
      'Reorder global and custom drinks inside each category and hide global entries you do not want in selectors.';

  @override
  String get barCustomDrinksBody => 'Create and edit your own drinks.';

  @override
  String get hiddenDrinks => 'Hidden drinks';

  @override
  String get hideCategory => 'Hide category';

  @override
  String get showCategory => 'Show category';

  @override
  String get hideDrink => 'Hide';

  @override
  String get showDrink => 'Show';

  @override
  String get allGlobalDrinksHidden =>
      'All global drinks in this category are hidden.';

  @override
  String get backend => 'Backend';

  @override
  String get backendRemoteBody =>
      'Supabase is configured and remote sync is active.';

  @override
  String get backendLocalBody =>
      'No Supabase configuration was provided, so the app is using the local fallback backend.';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get units => 'Units';

  @override
  String get handedness => 'Handedness';

  @override
  String get logout => 'Log out';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get friends => 'Friends';

  @override
  String get friendsSectionBody =>
      'Share your profile link so others can send you a friend request.';

  @override
  String get friendsEmpty => 'No friends or pending requests yet.';

  @override
  String get friendProfile => 'Friend profile';

  @override
  String get friendProfileLinkAction => 'Show my profile link';

  @override
  String get friendProfileLinkTitle => 'Your friend profile';

  @override
  String get friendProfileLinkBody =>
      'Friends can scan this code or open the link to send you a request.';

  @override
  String get friendProfileShareTitle => 'Add me on Glass Trail';

  @override
  String friendProfileShareText(String profileName, String link) {
    return 'Hey! $profileName has invited you to Glass Trail, the app to track drinks, analyze statistics, and toast with friends. Give it a try!\n\n$link';
  }

  @override
  String get friendProfileLinkCopied => 'Profile link copied.';

  @override
  String get friendIncomingRequest => 'Wants to be friends';

  @override
  String get friendAccepted => 'Friend';

  @override
  String get friendRequestPending => 'Waiting for response';

  @override
  String get friendAlreadyFriends => 'You are already friends.';

  @override
  String get friendIncomingRequestFromProfile =>
      'This user already sent you a request. Review it in your Friends section.';

  @override
  String get friendProfileSelf => 'This is your own friend profile link.';

  @override
  String friendProfileRequestPrompt(String name) {
    return '$name wants to be friends with you.';
  }

  @override
  String friendProfilePublicPrompt(String name) {
    return '$name wants to be your friend on Glass Trail.';
  }

  @override
  String get addAsFriend => 'Add as friend';

  @override
  String get goToFeed => 'Go to feed';

  @override
  String get withdrawFriendRequest => 'Withdraw';

  @override
  String get unfriend => 'Unfriend';

  @override
  String get friendProfileLinkInvalidTitle => 'Profile link unavailable';

  @override
  String get friendProfileLinkInvalidBody =>
      'This friend profile link is invalid or no longer available.';

  @override
  String get customDrinks => 'My custom drinks';

  @override
  String get addCustomDrinkAction => 'Add custom drink';

  @override
  String get customDrinksEmptyTitle => 'No custom drinks yet';

  @override
  String get customDrinksEmptyBody =>
      'Create your first custom drink and it will appear here.';

  @override
  String get statisticsHistoryEmptyTitle => 'No history yet';

  @override
  String get statisticsHistoryEmptyBody =>
      'Logged drinks will appear here as your personal history.';

  @override
  String get roadmap => 'Planned next';

  @override
  String get about => 'About';

  @override
  String get github => 'GitHub';

  @override
  String get roadmapBody =>
      'Friends, social feed, and achievements are part of the plan but intentionally not shipped in V1.';

  @override
  String get beerWithMeImport => 'Beer With Me Import';

  @override
  String get beerWithMeImportBody =>
      'Import a Beer With Me export into your GlassTrail history. Existing Beer With Me imports are detected and skipped automatically.';

  @override
  String get beerWithMeImportAction => 'Import Beer With Me export';

  @override
  String get beerWithMeImportEmpty =>
      'The selected Beer With Me export does not contain any entries.';

  @override
  String get beerWithMeImportInvalidFile =>
      'The selected file is not a valid Beer With Me export.';

  @override
  String get beerWithMeImportReadFailed =>
      'The Beer With Me export could not be read.';

  @override
  String get beerWithMeImportConfirmTitle => 'Import Beer With Me export?';

  @override
  String beerWithMeImportConfirmBody(int count) {
    return 'This will import $count entries into your GlassTrail history.';
  }

  @override
  String beerWithMeImportProgress(int processed, int total) {
    return 'Importing $processed of $total entries';
  }

  @override
  String beerWithMeImportProgressDetails(
    int imported,
    int skipped,
    int errors,
  ) {
    return '$imported imported, $skipped duplicates, $errors errors';
  }

  @override
  String get beerWithMeImportCancelAction => 'Cancel import';

  @override
  String get beerWithMeImportCancelling =>
      'Cancelling after the current entry...';

  @override
  String get beerWithMeImportResultTitle => 'Beer With Me import result';

  @override
  String beerWithMeImportResultCancelled(int processed, int total) {
    return 'Import cancelled after $processed of $total entries.';
  }

  @override
  String beerWithMeImportResultTotal(int count) {
    return 'Total entries: $count';
  }

  @override
  String beerWithMeImportResultImported(int count) {
    return 'Imported successfully: $count';
  }

  @override
  String beerWithMeImportResultSkipped(int count) {
    return 'Skipped as duplicates: $count';
  }

  @override
  String beerWithMeImportResultErrors(int count) {
    return 'Errors: $count';
  }

  @override
  String get beerWithMeImportErrorListTitle => 'Failed entries';

  @override
  String get beerWithMeImportInvalidEntry =>
      'The entry is not a valid JSON object.';

  @override
  String get beerWithMeImportMissingId => 'BeerWithMe ID missing';

  @override
  String get beerWithMeImportMissingGlassType =>
      'BeerWithMe drink type missing';

  @override
  String get beerWithMeImportMissingTimestamp => 'Timestamp missing';

  @override
  String get beerWithMeImportInvalidTimestamp => 'Invalid timestamp';

  @override
  String beerWithMeImportUnknownGlassType(String glassType) {
    return 'BeerWithMe type \"$glassType\" not supported.';
  }

  @override
  String beerWithMeImportMissingMappedDrink(String glassType) {
    return 'GlassTrail could not find the mapped drink for \"$glassType\".';
  }

  @override
  String get beerWithMeImportAlreadyImported =>
      'BeerWithMe entry was already imported.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get handednessRight => 'Right';

  @override
  String get handednessLeft => 'Left';

  @override
  String get invalidRequired => 'Please fill in all required fields.';

  @override
  String get emptyFilter => 'No drinks match the current filter.';

  @override
  String get launchingApp => 'Loading your drinks and settings.';

  @override
  String get welcomeToGlassTrail => 'Welcome to Glass Trail.';

  @override
  String get welcomeBack => 'Welcome back.';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get customDrinkSaved => 'Custom drink saved.';

  @override
  String get customDrinkDeleted => 'Custom drink deleted.';

  @override
  String drinkLogged(String drink) {
    return '$drink logged.';
  }

  @override
  String get entryUpdated => 'Entry updated.';

  @override
  String get entryDeleted => 'Entry deleted.';

  @override
  String get friendRequestSent => 'Friend request sent.';

  @override
  String get friendRequestAccepted => 'Friend request accepted.';

  @override
  String get friendRequestRejected => 'Friend request rejected.';

  @override
  String get friendRequestCanceled => 'Friend request withdrawn.';

  @override
  String get friendRemoved => 'Friend removed.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get accountAlreadyExists =>
      'An account with that email already exists.';

  @override
  String get invalidCredentials => 'The email or password is incorrect.';

  @override
  String get profileUpdateFailed => 'The profile could not be updated.';

  @override
  String get entryUpdateFailed => 'The drink entry could not be updated.';

  @override
  String get entryDeleteFailed => 'The drink entry could not be deleted.';

  @override
  String get friendProfileLinkInvalid => 'The profile link is invalid.';

  @override
  String get friendSelfRequestBlocked => 'You cannot add yourself as a friend.';

  @override
  String get friendRequestAcceptFailed =>
      'The friend request could not be accepted.';

  @override
  String get friendRequestRejectFailed =>
      'The friend request could not be rejected.';

  @override
  String get friendRequestCancelFailed =>
      'The friend request could not be withdrawn.';

  @override
  String get friendRemoveFailed => 'The friend could not be removed.';

  @override
  String get customDrinkDeleteFailed =>
      'The custom drink could not be deleted.';

  @override
  String get customDrinkAlreadyExists =>
      'You already have a custom drink with that name.';

  @override
  String get signUpMissingUser => 'Sign-up did not return a user.';

  @override
  String get signUpConfirmationRequired =>
      'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.';

  @override
  String get beer => 'Beer';

  @override
  String get wine => 'Wine';

  @override
  String get sparklingWines => 'Sparkling Wines';

  @override
  String get longdrinks => 'Longdrinks';

  @override
  String get spirits => 'Spirits';

  @override
  String get shots => 'Shots';

  @override
  String get cocktails => 'Cocktails';

  @override
  String get appleWines => 'Apple Wines';

  @override
  String get nonAlcoholic => 'Non-alcoholic';

  @override
  String dayLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }
}
