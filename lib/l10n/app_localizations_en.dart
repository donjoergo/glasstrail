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
  String get maybeLater => 'Maybe later';

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
  String get drinkType => 'Drink type';

  @override
  String get changeDrinkType => 'Change drink type';

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
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String deleteAccountBody(String phrase) {
    return 'This permanently deletes your account, profile, history, friends, and notifications. Type \"$phrase\" to enable account deletion.';
  }

  @override
  String deleteAccountVerificationLabel(String phrase) {
    return 'Type \"$phrase\" to confirm';
  }

  @override
  String get deleteAccountVerificationPhrase => 'DELETE ACCOUNT';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get drinkName => 'Drink name';

  @override
  String get category => 'Category';

  @override
  String get volume => 'Volume';

  @override
  String get alcoholFree => 'Alcohol-free';

  @override
  String get customDrinkAlcoholFreeSwitch => 'Alcohol-free';

  @override
  String get appUpdatedTitle => 'App updated';

  @override
  String appUpdatedBody(String appName, String version) {
    return '$appName was just updated to $version. Would you like to read the changelog?';
  }

  @override
  String get feedHeadline => 'Your activity feed';

  @override
  String get feedCheersAction => 'Cheers';

  @override
  String get noEntries => 'No drinks logged yet.';

  @override
  String get startLogging => 'Start by logging your first drink.';

  @override
  String get weeklyTotal => 'This Week';

  @override
  String get monthlyTotal => 'This Month';

  @override
  String get yearlyTotal => 'This Year';

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
  String get beerBreakdown => 'Beer breakdown';

  @override
  String get regularBeer => 'Normal beer';

  @override
  String get alcoholFreeBeer => 'Alcohol-free beer';

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
  String get shareStatsWithFriends => 'Share stats with friends';

  @override
  String get shareStatsWithFriendsBody =>
      'Accepted friends can open your shared statistics inside the app.';

  @override
  String get logout => 'Log out';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get accountSectionBody =>
      'Change your password or permanently delete this account.';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordBody =>
      'Confirm your current password and choose a new one.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get repeatNewPassword => 'Repeat new password';

  @override
  String get changePasswordAction => 'Update password';

  @override
  String get changePasswordConfirmationMismatch =>
      'The new passwords do not match.';

  @override
  String get changePasswordSameAsCurrent =>
      'The new password must be different from the current password.';

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
  String get friendStatsNotSharedTitle => 'Statistics not shared';

  @override
  String friendStatsNotSharedBody(String name) {
    return '$name is not sharing statistics with friends right now.';
  }

  @override
  String get friendStatsUnavailableTitle => 'Friend profile unavailable';

  @override
  String get friendStatsUnavailableBody =>
      'This friend\'s shared profile is unavailable or no longer shared with you.';

  @override
  String get addAsFriend => 'Add as friend';

  @override
  String get goToFeed => 'Go to feed';

  @override
  String get withdrawFriendRequest => 'Withdraw';

  @override
  String get unfriend => 'Unfriend';

  @override
  String unfriendConfirmTitle(String name) {
    return 'Unfriend $name?';
  }

  @override
  String unfriendConfirmBody(String name) {
    return 'You and $name will stop seeing each other\'s shared activity. You can send another friend request later.';
  }

  @override
  String get friendProfileLinkInvalidTitle => 'Profile link unavailable';

  @override
  String get friendProfileLinkInvalidBody =>
      'This friend profile link is invalid or no longer available.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications right now';

  @override
  String get notificationsEmptyBody =>
      'When friends log drinks or send you friend requests, you\'ll see them here. Read notifications are deleted after 30 days, unread notifications after 90 days.';

  @override
  String notificationFriendRequestSentTitle(String name) {
    return '$name sent you a friend request';
  }

  @override
  String get notificationFriendRequestSentBody =>
      'Review it in your Friends section.';

  @override
  String notificationFriendRequestAcceptedTitle(String name) {
    return '$name accepted your friend request';
  }

  @override
  String get notificationFriendRequestAcceptedBody =>
      'You can now see each other\'s shared activity.';

  @override
  String notificationFriendRequestRejectedTitle(String name) {
    return '$name declined your friend request';
  }

  @override
  String get notificationFriendRequestRejectedBody =>
      'You can send another request later.';

  @override
  String notificationFriendRemovedTitle(String name) {
    return '$name removed you as a friend';
  }

  @override
  String get notificationFriendRemovedBody =>
      'Open your Friends section to review your connections.';

  @override
  String notificationFriendDrinkCheeredTitle(String name) {
    return '$name sent you a cheers 🍻';
  }

  @override
  String get notificationFriendDrinkCheeredBody => '';

  @override
  String notificationFriendDrinkLoggedTitle(String name, String drink) {
    return '$name drinks $drink';
  }

  @override
  String notificationFriendDrinkLoggedBody(
    String commentLine,
    String locationAddressLine,
  ) {
    return '$commentLine\n$locationAddressLine';
  }

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

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
  String get roadmapBody => 'Achievements are planned next.';

  @override
  String get beerWithMeImport => 'Beer With Me Import';

  @override
  String get beerWithMeImportBody =>
      'Import a Beer With Me export into your GlassTrail history. Existing Beer With Me imports are detected and skipped automatically.';

  @override
  String get beerWithMePostSignUpTitle => 'Import your Beer With Me history?';

  @override
  String get beerWithMePostSignUpBody =>
      'If you already tracked drinks in Beer With Me, you can import that export now and keep your history in GlassTrail.';

  @override
  String get beerWithMePostSignUpHint =>
      'You can also import it later from the profile screen.';

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
  String get changePasswordSuccess => 'Password changed.';

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
  String get changePasswordCurrentPasswordIncorrect =>
      'The current password is incorrect.';

  @override
  String get profileUpdateFailed => 'The profile could not be updated.';

  @override
  String get changePasswordFailed => 'The password could not be changed.';

  @override
  String get deleteAccountSuccess => 'Account deleted.';

  @override
  String get deleteAccountFailed => 'The account could not be deleted.';

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

  @override
  String get achievementFamilyTotalDrinksTitle => 'Cheers Chase';

  @override
  String get achievementFamilyTotalDrinksLevel1Title => 'First Pour';

  @override
  String get achievementFamilyTotalDrinksLevel1Description =>
      'Log your first drink.';

  @override
  String get achievementFamilyTotalDrinksLevel10Title => 'Sip Starter';

  @override
  String get achievementFamilyTotalDrinksLevel10Description => 'Log 10 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel25Title => 'Glass Gatherer';

  @override
  String get achievementFamilyTotalDrinksLevel25Description => 'Log 25 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel50Title => 'Pour Pacer';

  @override
  String get achievementFamilyTotalDrinksLevel50Description => 'Log 50 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel100Title => 'Cheers Charger';

  @override
  String get achievementFamilyTotalDrinksLevel100Description =>
      'Log 100 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel200Title => 'Pour Pathfinder';

  @override
  String get achievementFamilyTotalDrinksLevel200Description =>
      'Log 200 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel300Title => 'Toast Tactician';

  @override
  String get achievementFamilyTotalDrinksLevel300Description =>
      'Log 300 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel400Title =>
      'Celebration Commander';

  @override
  String get achievementFamilyTotalDrinksLevel400Description =>
      'Log 400 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel500Title => 'Party Patron';

  @override
  String get achievementFamilyTotalDrinksLevel500Description =>
      'Log 500 drinks.';

  @override
  String get achievementFamilyTotalDrinksLevel1000Title => 'Cheers Champion';

  @override
  String get achievementFamilyTotalDrinksLevel1000Description =>
      'Log 1000 drinks.';

  @override
  String get achievementFamilyStreaksTitle => 'Daily Drive';

  @override
  String get achievementFamilyStreaksLevel3Title => 'Streak Starter';

  @override
  String get achievementFamilyStreaksLevel3Description =>
      'Reach a 3-day streak.';

  @override
  String get achievementFamilyStreaksLevel7Title => 'Week Warrior';

  @override
  String get achievementFamilyStreaksLevel7Description =>
      'Reach a 7-day streak.';

  @override
  String get achievementFamilyStreaksLevel14Title => 'Fortnight Flow';

  @override
  String get achievementFamilyStreaksLevel14Description =>
      'Reach a 14-day streak.';

  @override
  String get achievementFamilyStreaksLevel30Title => 'Thirty-Day Thunder';

  @override
  String get achievementFamilyStreaksLevel30Description =>
      'Reach a 30-day streak.';

  @override
  String get achievementFamilyStreaksLevel60Title => 'Stamina Sipper';

  @override
  String get achievementFamilyStreaksLevel60Description =>
      'Reach a 60-day streak.';

  @override
  String get achievementFamilyStreaksLevel90Title => 'Ninety Navigator';

  @override
  String get achievementFamilyStreaksLevel90Description =>
      'Reach a 90-day streak.';

  @override
  String get achievementFamilyStreaksLevel180Title => 'Endurance Elite';

  @override
  String get achievementFamilyStreaksLevel180Description =>
      'Reach a 180-day streak.';

  @override
  String get achievementFamilyStreaksLevel365Title => 'Daily Dynasty';

  @override
  String get achievementFamilyStreaksLevel365Description =>
      'Reach a 365-day streak.';

  @override
  String get achievementFamilyBeerTitle => 'Brew Quest';

  @override
  String get achievementFamilyBeerLevel10Title => 'Beer Rookie';

  @override
  String get achievementFamilyBeerLevel10Description => 'Log 10 beers.';

  @override
  String get achievementFamilyBeerLevel25Title => 'Foam Friend';

  @override
  String get achievementFamilyBeerLevel25Description => 'Log 25 beers.';

  @override
  String get achievementFamilyBeerLevel50Title => 'Brew Browser';

  @override
  String get achievementFamilyBeerLevel50Description => 'Log 50 beers.';

  @override
  String get achievementFamilyBeerLevel100Title => 'Hop Hero';

  @override
  String get achievementFamilyBeerLevel100Description => 'Log 100 beers.';

  @override
  String get achievementFamilyBeerLevel200Title => 'Brew Boss';

  @override
  String get achievementFamilyBeerLevel200Description => 'Log 200 beers.';

  @override
  String get achievementFamilyBeerLevel300Title => 'Hop Honcho';

  @override
  String get achievementFamilyBeerLevel300Description => 'Log 300 beers.';

  @override
  String get achievementFamilyBeerLevel400Title => 'Beer Baron';

  @override
  String get achievementFamilyBeerLevel400Description => 'Log 400 beers.';

  @override
  String get achievementFamilyBeerLevel500Title => 'Brew Legend';

  @override
  String get achievementFamilyBeerLevel500Description => 'Log 500 beers.';

  @override
  String get achievementFamilyBeerLevel1000Title => 'Beer Immortal';

  @override
  String get achievementFamilyBeerLevel1000Description => 'Log 1000 beers.';

  @override
  String get achievementFamilyWineTitle => 'Vintage Voyage';

  @override
  String get achievementFamilyWineLevel10Title => 'Grape Guest';

  @override
  String get achievementFamilyWineLevel10Description => 'Log 10 wines.';

  @override
  String get achievementFamilyWineLevel25Title => 'Vine Visitor';

  @override
  String get achievementFamilyWineLevel25Description => 'Log 25 wines.';

  @override
  String get achievementFamilyWineLevel50Title => 'Grape Gatherer';

  @override
  String get achievementFamilyWineLevel50Description => 'Log 50 wines.';

  @override
  String get achievementFamilyWineLevel100Title => 'Cork Commander';

  @override
  String get achievementFamilyWineLevel100Description => 'Log 100 wines.';

  @override
  String get achievementFamilyWineLevel200Title => 'Vine Virtuoso';

  @override
  String get achievementFamilyWineLevel200Description => 'Log 200 wines.';

  @override
  String get achievementFamilyWineLevel300Title => 'Grape Guru';

  @override
  String get achievementFamilyWineLevel300Description => 'Log 300 wines.';

  @override
  String get achievementFamilyWineLevel400Title => 'Wine Wizard';

  @override
  String get achievementFamilyWineLevel400Description => 'Log 400 wines.';

  @override
  String get achievementFamilyWineLevel500Title => 'Vine VIP';

  @override
  String get achievementFamilyWineLevel500Description => 'Log 500 wines.';

  @override
  String get achievementFamilyWineLevel1000Title => 'Wine Wonder';

  @override
  String get achievementFamilyWineLevel1000Description => 'Log 1000 wines.';

  @override
  String get achievementFamilySparklingWinesTitle => 'Spark Sprint';

  @override
  String get achievementFamilySparklingWinesLevel10Title => 'Spark Starter';

  @override
  String get achievementFamilySparklingWinesLevel10Description =>
      'Log 10 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel25Title => 'Fizz Friend';

  @override
  String get achievementFamilySparklingWinesLevel25Description =>
      'Log 25 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel50Title => 'Spark Seeker';

  @override
  String get achievementFamilySparklingWinesLevel50Description =>
      'Log 50 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel100Title => 'Fizz Foreman';

  @override
  String get achievementFamilySparklingWinesLevel100Description =>
      'Log 100 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel200Title => 'Cuvée Captain';

  @override
  String get achievementFamilySparklingWinesLevel200Description =>
      'Log 200 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel300Title => 'Spark Sovereign';

  @override
  String get achievementFamilySparklingWinesLevel300Description =>
      'Log 300 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel400Title => 'Cuvée Conqueror';

  @override
  String get achievementFamilySparklingWinesLevel400Description =>
      'Log 400 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel500Title => 'Fizz Fame';

  @override
  String get achievementFamilySparklingWinesLevel500Description =>
      'Log 500 sparkling wines.';

  @override
  String get achievementFamilySparklingWinesLevel1000Title => 'Spark Supreme';

  @override
  String get achievementFamilySparklingWinesLevel1000Description =>
      'Log 1000 sparkling wines.';

  @override
  String get achievementFamilyLongdrinksTitle => 'Mixer Marathon';

  @override
  String get achievementFamilyLongdrinksLevel10Title => 'Longdrink Learner';

  @override
  String get achievementFamilyLongdrinksLevel10Description =>
      'Log 10 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel25Title => 'Mixer Mate';

  @override
  String get achievementFamilyLongdrinksLevel25Description =>
      'Log 25 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel50Title => 'Longdrink Loyalist';

  @override
  String get achievementFamilyLongdrinksLevel50Description =>
      'Log 50 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel100Title => 'Mixer Master';

  @override
  String get achievementFamilyLongdrinksLevel100Description =>
      'Log 100 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel200Title => 'Longdrink Leader';

  @override
  String get achievementFamilyLongdrinksLevel200Description =>
      'Log 200 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel300Title => 'Mix Monarch';

  @override
  String get achievementFamilyLongdrinksLevel300Description =>
      'Log 300 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel400Title => 'Mixer Mogul';

  @override
  String get achievementFamilyLongdrinksLevel400Description =>
      'Log 400 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel500Title => 'Pour Prince';

  @override
  String get achievementFamilyLongdrinksLevel500Description =>
      'Log 500 longdrinks.';

  @override
  String get achievementFamilyLongdrinksLevel1000Title => 'Mixer Immortal';

  @override
  String get achievementFamilyLongdrinksLevel1000Description =>
      'Log 1000 longdrinks.';

  @override
  String get achievementFamilySpiritsTitle => 'Spirit Sprint';

  @override
  String get achievementFamilySpiritsLevel10Title => 'Spirit Starter';

  @override
  String get achievementFamilySpiritsLevel10Description => 'Log 10 spirits.';

  @override
  String get achievementFamilySpiritsLevel25Title => 'Dram Dabbler';

  @override
  String get achievementFamilySpiritsLevel25Description => 'Log 25 spirits.';

  @override
  String get achievementFamilySpiritsLevel50Title => 'Pour Pal';

  @override
  String get achievementFamilySpiritsLevel50Description => 'Log 50 spirits.';

  @override
  String get achievementFamilySpiritsLevel100Title => 'Spirit Specialist';

  @override
  String get achievementFamilySpiritsLevel100Description => 'Log 100 spirits.';

  @override
  String get achievementFamilySpiritsLevel200Title => 'Pour Pioneer';

  @override
  String get achievementFamilySpiritsLevel200Description => 'Log 200 spirits.';

  @override
  String get achievementFamilySpiritsLevel300Title => 'Neat Noble';

  @override
  String get achievementFamilySpiritsLevel300Description => 'Log 300 spirits.';

  @override
  String get achievementFamilySpiritsLevel400Title => 'Spirit Supremo';

  @override
  String get achievementFamilySpiritsLevel400Description => 'Log 400 spirits.';

  @override
  String get achievementFamilySpiritsLevel500Title => 'Pour Prestige';

  @override
  String get achievementFamilySpiritsLevel500Description => 'Log 500 spirits.';

  @override
  String get achievementFamilySpiritsLevel1000Title => 'Spirit Immortal';

  @override
  String get achievementFamilySpiritsLevel1000Description =>
      'Log 1000 spirits.';

  @override
  String get achievementFamilyShotsTitle => 'Quick Kick';

  @override
  String get achievementFamilyShotsLevel10Title => 'Quick Quencher';

  @override
  String get achievementFamilyShotsLevel10Description => 'Log 10 shots.';

  @override
  String get achievementFamilyShotsLevel25Title => 'Shot Scout';

  @override
  String get achievementFamilyShotsLevel25Description => 'Log 25 shots.';

  @override
  String get achievementFamilyShotsLevel50Title => 'Shot Sprinter';

  @override
  String get achievementFamilyShotsLevel50Description => 'Log 50 shots.';

  @override
  String get achievementFamilyShotsLevel100Title => 'Quick Commander';

  @override
  String get achievementFamilyShotsLevel100Description => 'Log 100 shots.';

  @override
  String get achievementFamilyShotsLevel200Title => 'Shot Sovereign';

  @override
  String get achievementFamilyShotsLevel200Description => 'Log 200 shots.';

  @override
  String get achievementFamilyShotsLevel300Title => 'Quick King';

  @override
  String get achievementFamilyShotsLevel300Description => 'Log 300 shots.';

  @override
  String get achievementFamilyShotsLevel400Title => 'Shot Supreme';

  @override
  String get achievementFamilyShotsLevel400Description => 'Log 400 shots.';

  @override
  String get achievementFamilyShotsLevel500Title => 'Tiny Tornado';

  @override
  String get achievementFamilyShotsLevel500Description => 'Log 500 shots.';

  @override
  String get achievementFamilyShotsLevel1000Title => 'Shot Immortal';

  @override
  String get achievementFamilyShotsLevel1000Description => 'Log 1000 shots.';

  @override
  String get achievementFamilyCocktailsTitle => 'Cocktail Craze';

  @override
  String get achievementFamilyCocktailsLevel10Title => 'Cocktail Cadet';

  @override
  String get achievementFamilyCocktailsLevel10Description =>
      'Log 10 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel25Title => 'Mixer Muse';

  @override
  String get achievementFamilyCocktailsLevel25Description =>
      'Log 25 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel50Title => 'Glass Glam';

  @override
  String get achievementFamilyCocktailsLevel50Description =>
      'Log 50 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel100Title => 'Shaker Specialist';

  @override
  String get achievementFamilyCocktailsLevel100Description =>
      'Log 100 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel200Title => 'Cocktail Charmer';

  @override
  String get achievementFamilyCocktailsLevel200Description =>
      'Log 200 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel300Title => 'Glass Guru';

  @override
  String get achievementFamilyCocktailsLevel300Description =>
      'Log 300 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel400Title => 'Mixer Majesty';

  @override
  String get achievementFamilyCocktailsLevel400Description =>
      'Log 400 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel500Title => 'Shaker Legend';

  @override
  String get achievementFamilyCocktailsLevel500Description =>
      'Log 500 cocktails.';

  @override
  String get achievementFamilyCocktailsLevel1000Title => 'Cocktail Icon';

  @override
  String get achievementFamilyCocktailsLevel1000Description =>
      'Log 1000 cocktails.';

  @override
  String get achievementFamilyAppleWinesTitle => 'Cider Circuit';

  @override
  String get achievementFamilyAppleWinesLevel10Title => 'Apple Apprentice';

  @override
  String get achievementFamilyAppleWinesLevel10Description =>
      'Log 10 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel25Title => 'Cider Scout';

  @override
  String get achievementFamilyAppleWinesLevel25Description =>
      'Log 25 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel50Title => 'Cider Chaser';

  @override
  String get achievementFamilyAppleWinesLevel50Description =>
      'Log 50 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel100Title => 'Apple Ace';

  @override
  String get achievementFamilyAppleWinesLevel100Description =>
      'Log 100 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel200Title => 'Cider Captain';

  @override
  String get achievementFamilyAppleWinesLevel200Description =>
      'Log 200 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel300Title => 'Apple Aristocrat';

  @override
  String get achievementFamilyAppleWinesLevel300Description =>
      'Log 300 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel400Title => 'Cider Crown';

  @override
  String get achievementFamilyAppleWinesLevel400Description =>
      'Log 400 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel500Title => 'Apple Authority';

  @override
  String get achievementFamilyAppleWinesLevel500Description =>
      'Log 500 apple wines.';

  @override
  String get achievementFamilyAppleWinesLevel1000Title => 'Cider Immortal';

  @override
  String get achievementFamilyAppleWinesLevel1000Description =>
      'Log 1000 apple wines.';

  @override
  String get achievementFamilyNonAlcoholicTitle => 'Zero Zest';

  @override
  String get achievementFamilyNonAlcoholicLevel10Title => 'Zero Starter';

  @override
  String get achievementFamilyNonAlcoholicLevel10Description =>
      'Log 10 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel25Title => 'Clear Cruiser';

  @override
  String get achievementFamilyNonAlcoholicLevel25Description =>
      'Log 25 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel50Title => 'Hydro Hero';

  @override
  String get achievementFamilyNonAlcoholicLevel50Description =>
      'Log 50 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel100Title => 'Zero Pro';

  @override
  String get achievementFamilyNonAlcoholicLevel100Description =>
      'Log 100 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel200Title => 'Clear Commander';

  @override
  String get achievementFamilyNonAlcoholicLevel200Description =>
      'Log 200 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel300Title => 'Zero Virtuoso';

  @override
  String get achievementFamilyNonAlcoholicLevel300Description =>
      'Log 300 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel400Title => 'Zero Maestro';

  @override
  String get achievementFamilyNonAlcoholicLevel400Description =>
      'Log 400 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel500Title => 'Zero Zenith';

  @override
  String get achievementFamilyNonAlcoholicLevel500Description =>
      'Log 500 non-alcoholic drinks.';

  @override
  String get achievementFamilyNonAlcoholicLevel1000Title => 'Zero Hero';

  @override
  String get achievementFamilyNonAlcoholicLevel1000Description =>
      'Log 1000 non-alcoholic drinks.';

  @override
  String get achievementFamilyHomeTitle => 'Home Harmony';

  @override
  String get achievementFamilyHomeLevel1Title => 'Home Hello';

  @override
  String get achievementFamilyHomeLevel1Description => 'Log a drink at home.';

  @override
  String get achievementFamilyHomeLevel10Title => 'Stay Starter';

  @override
  String get achievementFamilyHomeLevel10Description =>
      'Log 10 drinks at home.';

  @override
  String get achievementFamilyHomeLevel25Title => 'Couch Companion';

  @override
  String get achievementFamilyHomeLevel25Description =>
      'Log 25 drinks at home.';

  @override
  String get achievementFamilyHomeLevel50Title => 'Home Hero';

  @override
  String get achievementFamilyHomeLevel50Description =>
      'Log 50 drinks at home.';

  @override
  String get achievementFamilyHomeLevel100Title => 'Stay Sovereign';

  @override
  String get achievementFamilyHomeLevel100Description =>
      'Log 100 drinks at home.';

  @override
  String get achievementFamilyWorkTitle => 'Office Odyssey';

  @override
  String get achievementFamilyWorkLevel1Title => 'Work Welcome';

  @override
  String get achievementFamilyWorkLevel1Description => 'Log a drink at work.';

  @override
  String get achievementFamilyWorkLevel10Title => 'Office Operative';

  @override
  String get achievementFamilyWorkLevel10Description =>
      'Log 10 drinks at work.';

  @override
  String get achievementFamilyWorkLevel25Title => 'Office Officer';

  @override
  String get achievementFamilyWorkLevel25Description =>
      'Log 25 drinks at work.';

  @override
  String get achievementFamilyWorkLevel50Title => 'Work Warrior';

  @override
  String get achievementFamilyWorkLevel50Description =>
      'Log 50 drinks at work.';

  @override
  String get achievementFamilyWorkLevel100Title => 'Office Icon';

  @override
  String get achievementFamilyWorkLevel100Description =>
      'Log 100 drinks at work.';

  @override
  String get achievementFamilyTravelCountriesTitle => 'Passport Pursuit';

  @override
  String get achievementFamilyTravelCountriesLevel3Title => 'Passport Pioneer';

  @override
  String get achievementFamilyTravelCountriesLevel3Description =>
      'Log drinks in 3 countries.';

  @override
  String get achievementFamilyTravelCountriesLevel5Title => 'Border Buddy';

  @override
  String get achievementFamilyTravelCountriesLevel5Description =>
      'Log drinks in 5 countries.';

  @override
  String get achievementFamilyTravelCountriesLevel10Title => 'Country Cruiser';

  @override
  String get achievementFamilyTravelCountriesLevel10Description =>
      'Log drinks in 10 countries.';

  @override
  String get achievementFamilyTravelCountriesLevel15Title => 'Map Maverick';

  @override
  String get achievementFamilyTravelCountriesLevel15Description =>
      'Log drinks in 15 countries.';

  @override
  String get achievementFamilyTravelCountriesLevel20Title => 'Trailblazer';

  @override
  String get achievementFamilyTravelCountriesLevel20Description =>
      'Log drinks in 20 countries.';

  @override
  String get achievementFamilyTravelCountriesLevel30Title => 'Global Galloper';

  @override
  String get achievementFamilyTravelCountriesLevel30Description =>
      'Log drinks in 30 countries.';

  @override
  String get achievementFamilyTravelCountriesLevel50Title => 'World Whirl';

  @override
  String get achievementFamilyTravelCountriesLevel50Description =>
      'Log drinks in 50 countries.';

  @override
  String get achievementOccasionBirthdayTitle => 'Birthday Bash';

  @override
  String get achievementOccasionBirthdayDescription =>
      'Log any drink on your birthday.';

  @override
  String get achievementOccasionFirstSipAnniversaryTitle =>
      'First Sip Anniversary';

  @override
  String get achievementOccasionFirstSipAnniversaryDescription =>
      'Log any drink on the anniversary of your first known drink.';

  @override
  String get achievementOccasionNewYearTitle => 'New Year, New Cheers';

  @override
  String get achievementOccasionNewYearDescription =>
      'Log any drink on New Year\'s Eve or New Year\'s Day.';

  @override
  String get achievementOccasionChristmasTitle => 'Christmas Clink';

  @override
  String get achievementOccasionChristmasDescription =>
      'Log any drink between December 24 and 26.';

  @override
  String get achievementOccasionEasterTitle => 'Easter Cheers';

  @override
  String get achievementOccasionEasterDescription =>
      'Log any drink between Good Friday and Easter Monday.';

  @override
  String get achievementOccasionHalloweenTitle => 'Spooky Sip';

  @override
  String get achievementOccasionHalloweenDescription =>
      'Log any drink on Halloween.';

  @override
  String get achievementOccasionStPatricksDayTitle => 'Lucky Lager';

  @override
  String get achievementOccasionStPatricksDayDescription =>
      'Log a beer on March 17.';

  @override
  String get achievementOccasionOktoberfestTitle => 'Festbier Fever';

  @override
  String get achievementOccasionOktoberfestDescription =>
      'Log a beer during Oktoberfest.';

  @override
  String get achievementOccasionCarnivalTitle => 'Confetti Cheers';

  @override
  String get achievementOccasionCarnivalDescription =>
      'Log any drink during Carnival.';

  @override
  String get achievementCountryDeTitle => 'Beergarten Bound';

  @override
  String get achievementCountryDeLabel => 'Germany';

  @override
  String get achievementCountryDeDescription => 'Log any drink in Germany.';

  @override
  String get achievementCountryNlTitle => 'Canal Clink';

  @override
  String get achievementCountryNlLabel => 'Netherlands';

  @override
  String get achievementCountryNlDescription =>
      'Log any drink in the Netherlands.';

  @override
  String get achievementCountryBeTitle => 'Belgian Buzz';

  @override
  String get achievementCountryBeLabel => 'Belgium';

  @override
  String get achievementCountryBeDescription => 'Log any drink in Belgium.';

  @override
  String get achievementCountryLuTitle => 'Grand Duchy Glow';

  @override
  String get achievementCountryLuLabel => 'Luxembourg';

  @override
  String get achievementCountryLuDescription => 'Log any drink in Luxembourg.';

  @override
  String get achievementCountryFrTitle => 'French Fizz';

  @override
  String get achievementCountryFrLabel => 'France';

  @override
  String get achievementCountryFrDescription => 'Log any drink in France.';

  @override
  String get achievementCountryEsTitle => 'Fiesta Flow';

  @override
  String get achievementCountryEsLabel => 'Spain';

  @override
  String get achievementCountryEsDescription => 'Log any drink in Spain.';

  @override
  String get achievementCountryPtTitle => 'Portuguese Pour';

  @override
  String get achievementCountryPtLabel => 'Portugal';

  @override
  String get achievementCountryPtDescription => 'Log any drink in Portugal.';

  @override
  String get achievementCountryItTitle => 'Aperitivo Arrival';

  @override
  String get achievementCountryItLabel => 'Italy';

  @override
  String get achievementCountryItDescription => 'Log any drink in Italy.';

  @override
  String get achievementCountryAtTitle => 'Alpine Cheers';

  @override
  String get achievementCountryAtLabel => 'Austria';

  @override
  String get achievementCountryAtDescription => 'Log any drink in Austria.';

  @override
  String get achievementCountryChTitle => 'Peak Pour';

  @override
  String get achievementCountryChLabel => 'Switzerland';

  @override
  String get achievementCountryChDescription => 'Log any drink in Switzerland.';

  @override
  String get achievementCountryPlTitle => 'Polish Pour';

  @override
  String get achievementCountryPlLabel => 'Poland';

  @override
  String get achievementCountryPlDescription => 'Log any drink in Poland.';

  @override
  String get achievementCountryCzTitle => 'Czech Cheers';

  @override
  String get achievementCountryCzLabel => 'Czech Republic';

  @override
  String get achievementCountryCzDescription =>
      'Log any drink in the Czech Republic.';

  @override
  String get achievementCountryIeTitle => 'Emerald Cheers';

  @override
  String get achievementCountryIeLabel => 'Ireland';

  @override
  String get achievementCountryIeDescription => 'Log any drink in Ireland.';

  @override
  String get achievementCountryGbTitle => 'Kingdom Clink';

  @override
  String get achievementCountryGbLabel => 'United Kingdom';

  @override
  String get achievementCountryGbDescription =>
      'Log any drink in the United Kingdom.';

  @override
  String get achievementCountryDkTitle => 'Danish Draft';

  @override
  String get achievementCountryDkLabel => 'Denmark';

  @override
  String get achievementCountryDkDescription => 'Log any drink in Denmark.';

  @override
  String get achievementCountrySeTitle => 'Scandi Spark';

  @override
  String get achievementCountrySeLabel => 'Sweden';

  @override
  String get achievementCountrySeDescription => 'Log any drink in Sweden.';

  @override
  String get achievementCountryNoTitle => 'Fjord Flow';

  @override
  String get achievementCountryNoLabel => 'Norway';

  @override
  String get achievementCountryNoDescription => 'Log any drink in Norway.';

  @override
  String get achievementCountryFiTitle => 'Sauna Sip';

  @override
  String get achievementCountryFiLabel => 'Finland';

  @override
  String get achievementCountryFiDescription => 'Log any drink in Finland.';

  @override
  String get achievementCountryGrTitle => 'Aegean Cheers';

  @override
  String get achievementCountryGrLabel => 'Greece';

  @override
  String get achievementCountryGrDescription => 'Log any drink in Greece.';

  @override
  String get achievementCountryHrTitle => 'Adriatic Uplift';

  @override
  String get achievementCountryHrLabel => 'Croatia';

  @override
  String get achievementCountryHrDescription => 'Log any drink in Croatia.';

  @override
  String get achievementCountryHuTitle => 'Danube Draft';

  @override
  String get achievementCountryHuLabel => 'Hungary';

  @override
  String get achievementCountryHuDescription => 'Log any drink in Hungary.';

  @override
  String get achievementCountryRoTitle => 'Carpathian Clink';

  @override
  String get achievementCountryRoLabel => 'Romania';

  @override
  String get achievementCountryRoDescription => 'Log any drink in Romania.';

  @override
  String get achievementCountryTrTitle => 'Bosphorus Buzz';

  @override
  String get achievementCountryTrLabel => 'Turkey';

  @override
  String get achievementCountryTrDescription => 'Log any drink in Turkey.';

  @override
  String get achievementCountryUsTitle => 'Stars & Sips';

  @override
  String get achievementCountryUsLabel => 'United States';

  @override
  String get achievementCountryUsDescription =>
      'Log any drink in the United States.';

  @override
  String get achievementCountryJpTitle => 'Sakura Sip';

  @override
  String get achievementCountryJpLabel => 'Japan';

  @override
  String get achievementCountryJpDescription => 'Log any drink in Japan.';

  @override
  String get achievementCountrySiTitle => 'Dragon Draft';

  @override
  String get achievementCountrySiLabel => 'Slovenia';

  @override
  String get achievementCountrySiDescription => 'Log any drink in Slovenia.';

  @override
  String get achievementCountryMcTitle => 'Monaco Mood';

  @override
  String get achievementCountryMcLabel => 'Monaco';

  @override
  String get achievementCountryMcDescription => 'Log any drink in Monaco.';

  @override
  String get achievementsTab => 'Achievements';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementsBadgesEarned => 'Badges earned';

  @override
  String get achievementsFilterAll => 'All';

  @override
  String get achievementsFilterUnlocked => 'Unlocked';

  @override
  String get achievementsFilterLocked => 'Locked';

  @override
  String get achievementsRecentlyUnlocked => 'Recently unlocked';

  @override
  String get achievementsViewAll => 'View all';

  @override
  String get achievementsSetupRequired => 'Setup required';

  @override
  String get achievementsSetUpNow => 'Set up now';

  @override
  String get achievementsEarnableToday => 'Earnable today';

  @override
  String get achievementsNextEligible => 'Next eligible';

  @override
  String get achievementsUnlocked => 'Unlocked';

  @override
  String get achievementsLocked => 'Locked';

  @override
  String get achievementsCompleted => 'Completed';

  @override
  String get achievementsSummaryBackfillTitle => 'Achievements unlocked';

  @override
  String get shareAchievements => 'Share achievements with friends';

  @override
  String get shareAchievementsBody =>
      'Accepted friends can see your earned badges inside the app.';

  @override
  String get achievementReminders => 'Achievement reminders';

  @override
  String get achievementRemindersBody =>
      'Get push reminders for annual and occasion-based badges.';

  @override
  String get savedPlacesTitle => 'Places';

  @override
  String get savedPlacesHome => 'Home';

  @override
  String get savedPlacesWork => 'Work';

  @override
  String get savedPlacesArchived => 'Previous places';

  @override
  String achievementsSummaryBackfillBody(int count) {
    return 'You unlocked $count badges from your history.';
  }

  @override
  String achievementsOverflowUnlocked(int count) {
    return '+$count more unlocked';
  }
}
