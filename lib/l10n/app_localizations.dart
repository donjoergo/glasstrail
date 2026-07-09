import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Glass Trail'**
  String get appTitle;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statisticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statisticsOverview;

  /// No description provided for @statisticsMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get statisticsMap;

  /// No description provided for @statisticsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get statisticsGallery;

  /// No description provided for @bar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get bar;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Track every glass'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Log drinks, spot streaks, and build a better picture of your habits.'**
  String get welcomeBody;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @removeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Remove birthday'**
  String get removeBirthday;

  /// No description provided for @pickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick photo'**
  String get pickPhoto;

  /// No description provided for @pickPhotoSource.
  ///
  /// In en, this message translates to:
  /// **'Choose photo source'**
  String get pickPhotoSource;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @addDrink.
  ///
  /// In en, this message translates to:
  /// **'Add drink'**
  String get addDrink;

  /// No description provided for @searchDrinks.
  ///
  /// In en, this message translates to:
  /// **'Search drinks'**
  String get searchDrinks;

  /// No description provided for @recentDrinks.
  ///
  /// In en, this message translates to:
  /// **'Recent drinks'**
  String get recentDrinks;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Drink catalog'**
  String get catalog;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @saveLocationForEntry.
  ///
  /// In en, this message translates to:
  /// **'Save location for this entry'**
  String get saveLocationForEntry;

  /// No description provided for @locationLoading.
  ///
  /// In en, this message translates to:
  /// **'Looking up your current location…'**
  String get locationLoading;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. The entry can still be saved.'**
  String get locationUnavailable;

  /// No description provided for @locationAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable. Coordinates will still be saved.'**
  String get locationAddressUnavailable;

  /// No description provided for @locationDisabledForEntry.
  ///
  /// In en, this message translates to:
  /// **'Location disabled for this entry.'**
  String get locationDisabledForEntry;

  /// No description provided for @locationApproximateWarning.
  ///
  /// In en, this message translates to:
  /// **'Android is only providing approximate location. Enable precise location in app settings for better accuracy.'**
  String get locationApproximateWarning;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @confirmDrink.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get confirmDrink;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @drinkType.
  ///
  /// In en, this message translates to:
  /// **'Drink type'**
  String get drinkType;

  /// No description provided for @changeDrinkType.
  ///
  /// In en, this message translates to:
  /// **'Change drink type'**
  String get changeDrinkType;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete this drink entry? The saved comment and photo will be removed too.'**
  String get deleteEntryPrompt;

  /// No description provided for @createCustomDrink.
  ///
  /// In en, this message translates to:
  /// **'Create custom drink'**
  String get createCustomDrink;

  /// No description provided for @editCustomDrink.
  ///
  /// In en, this message translates to:
  /// **'Edit custom drink'**
  String get editCustomDrink;

  /// No description provided for @deleteCustomDrink.
  ///
  /// In en, this message translates to:
  /// **'Delete custom drink'**
  String get deleteCustomDrink;

  /// No description provided for @deleteCustomDrinkPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete this custom drink? Existing history entries will remain available.'**
  String get deleteCustomDrinkPrompt;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, profile, history, friends, and notifications. Type \"{phrase}\" to enable account deletion.'**
  String deleteAccountBody(String phrase);

  /// No description provided for @deleteAccountVerificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Type \"{phrase}\" to confirm'**
  String deleteAccountVerificationLabel(String phrase);

  /// No description provided for @deleteAccountVerificationPhrase.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get deleteAccountVerificationPhrase;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountAction;

  /// No description provided for @drinkName.
  ///
  /// In en, this message translates to:
  /// **'Drink name'**
  String get drinkName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @alcoholFree.
  ///
  /// In en, this message translates to:
  /// **'Alcohol-free'**
  String get alcoholFree;

  /// No description provided for @customDrinkAlcoholFreeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Alcohol-free'**
  String get customDrinkAlcoholFreeSwitch;

  /// No description provided for @appUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'App updated'**
  String get appUpdatedTitle;

  /// Body text for the feed changelog card shown after an app update
  ///
  /// In en, this message translates to:
  /// **'{appName} was just updated to {version}. Would you like to read the changelog?'**
  String appUpdatedBody(String appName, String version);

  /// No description provided for @feedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your activity feed'**
  String get feedHeadline;

  /// No description provided for @feedCheersAction.
  ///
  /// In en, this message translates to:
  /// **'Cheers'**
  String get feedCheersAction;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No drinks logged yet.'**
  String get noEntries;

  /// No description provided for @startLogging.
  ///
  /// In en, this message translates to:
  /// **'Start by logging your first drink.'**
  String get startLogging;

  /// No description provided for @weeklyTotal.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get weeklyTotal;

  /// No description provided for @monthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get monthlyTotal;

  /// No description provided for @yearlyTotal.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get yearlyTotal;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @streakPromptStart.
  ///
  /// In en, this message translates to:
  /// **'Log a drink now to start your streak.'**
  String get streakPromptStart;

  /// No description provided for @streakPromptKeepAlive.
  ///
  /// In en, this message translates to:
  /// **'Log a drink now to keep your streak alive.'**
  String get streakPromptKeepAlive;

  /// No description provided for @streakPromptStartedToday.
  ///
  /// In en, this message translates to:
  /// **'Very good! You started your streak today.'**
  String get streakPromptStartedToday;

  /// No description provided for @streakPromptContinuedToday.
  ///
  /// In en, this message translates to:
  /// **'Very good! You continued your streak today.'**
  String get streakPromptContinuedToday;

  /// No description provided for @weekdayMondayShort.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get weekdayMondayShort;

  /// No description provided for @weekdayTuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayTuesdayShort;

  /// No description provided for @weekdayWednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get weekdayWednesdayShort;

  /// No description provided for @weekdayThursdayShort.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayThursdayShort;

  /// No description provided for @weekdayFridayShort.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get weekdayFridayShort;

  /// No description provided for @weekdaySaturdayShort.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdaySaturdayShort;

  /// No description provided for @weekdaySundayShort.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdaySundayShort;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown'**
  String get categoryBreakdown;

  /// No description provided for @beerBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Beer breakdown'**
  String get beerBreakdown;

  /// No description provided for @regularBeer.
  ///
  /// In en, this message translates to:
  /// **'Normal beer'**
  String get regularBeer;

  /// No description provided for @alcoholFreeBeer.
  ///
  /// In en, this message translates to:
  /// **'Alcohol-free beer'**
  String get alcoholFreeBeer;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @statisticsMapEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No drinks with location yet'**
  String get statisticsMapEmptyTitle;

  /// No description provided for @statisticsMapEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Enable location while logging drinks so they can appear here on the map.'**
  String get statisticsMapEmptyBody;

  /// No description provided for @statisticsGalleryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No drink photos yet'**
  String get statisticsGalleryEmptyTitle;

  /// No description provided for @statisticsGalleryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Photos from logged drinks will appear here automatically.'**
  String get statisticsGalleryEmptyBody;

  /// No description provided for @totalDrinks.
  ///
  /// In en, this message translates to:
  /// **'Total drinks'**
  String get totalDrinks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @globalDrinks.
  ///
  /// In en, this message translates to:
  /// **'Global drinks'**
  String get globalDrinks;

  /// No description provided for @barDrinkSortingTab.
  ///
  /// In en, this message translates to:
  /// **'Drink sorting'**
  String get barDrinkSortingTab;

  /// No description provided for @barCustomDrinksTab.
  ///
  /// In en, this message translates to:
  /// **'My drinks'**
  String get barCustomDrinksTab;

  /// No description provided for @barGlobalDrinksBody.
  ///
  /// In en, this message translates to:
  /// **'Reorder global and custom drinks inside each category and hide global entries you do not want in selectors.'**
  String get barGlobalDrinksBody;

  /// No description provided for @barCustomDrinksBody.
  ///
  /// In en, this message translates to:
  /// **'Create and edit your own drinks.'**
  String get barCustomDrinksBody;

  /// No description provided for @hiddenDrinks.
  ///
  /// In en, this message translates to:
  /// **'Hidden drinks'**
  String get hiddenDrinks;

  /// No description provided for @hideCategory.
  ///
  /// In en, this message translates to:
  /// **'Hide category'**
  String get hideCategory;

  /// No description provided for @showCategory.
  ///
  /// In en, this message translates to:
  /// **'Show category'**
  String get showCategory;

  /// No description provided for @hideDrink.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideDrink;

  /// No description provided for @showDrink.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showDrink;

  /// No description provided for @allGlobalDrinksHidden.
  ///
  /// In en, this message translates to:
  /// **'All global drinks in this category are hidden.'**
  String get allGlobalDrinksHidden;

  /// No description provided for @backend.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backend;

  /// No description provided for @backendRemoteBody.
  ///
  /// In en, this message translates to:
  /// **'Supabase is configured and remote sync is active.'**
  String get backendRemoteBody;

  /// No description provided for @backendLocalBody.
  ///
  /// In en, this message translates to:
  /// **'No Supabase configuration was provided, so the app is using the local fallback backend.'**
  String get backendLocalBody;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @handedness.
  ///
  /// In en, this message translates to:
  /// **'Handedness'**
  String get handedness;

  /// No description provided for @shareStatsWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share stats with friends'**
  String get shareStatsWithFriends;

  /// No description provided for @shareStatsWithFriendsBody.
  ///
  /// In en, this message translates to:
  /// **'Accepted friends can open your shared statistics inside the app.'**
  String get shareStatsWithFriendsBody;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @accountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionTitle;

  /// No description provided for @accountSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Change your password or permanently delete this account.'**
  String get accountSectionBody;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current password and choose a new one.'**
  String get changePasswordBody;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @repeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get repeatNewPassword;

  /// No description provided for @changePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordAction;

  /// No description provided for @changePasswordConfirmationMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords do not match.'**
  String get changePasswordConfirmationMismatch;

  /// No description provided for @changePasswordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current password.'**
  String get changePasswordSameAsCurrent;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @friendsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Share your profile link so others can send you a friend request.'**
  String get friendsSectionBody;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends or pending requests yet.'**
  String get friendsEmpty;

  /// No description provided for @friendProfile.
  ///
  /// In en, this message translates to:
  /// **'Friend profile'**
  String get friendProfile;

  /// No description provided for @friendProfileLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Show my profile link'**
  String get friendProfileLinkAction;

  /// No description provided for @friendProfileLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Your friend profile'**
  String get friendProfileLinkTitle;

  /// No description provided for @friendProfileLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Friends can scan this code or open the link to send you a request.'**
  String get friendProfileLinkBody;

  /// No description provided for @friendProfileShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Add me on Glass Trail'**
  String get friendProfileShareTitle;

  /// No description provided for @friendProfileShareText.
  ///
  /// In en, this message translates to:
  /// **'Hey! {profileName} has invited you to Glass Trail, the app to track drinks, analyze statistics, and toast with friends. Give it a try!\n\n{link}'**
  String friendProfileShareText(String profileName, String link);

  /// No description provided for @friendProfileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied.'**
  String get friendProfileLinkCopied;

  /// No description provided for @friendIncomingRequest.
  ///
  /// In en, this message translates to:
  /// **'Wants to be friends'**
  String get friendIncomingRequest;

  /// No description provided for @friendAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friendAccepted;

  /// No description provided for @friendRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response'**
  String get friendRequestPending;

  /// No description provided for @friendAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'You are already friends.'**
  String get friendAlreadyFriends;

  /// No description provided for @friendIncomingRequestFromProfile.
  ///
  /// In en, this message translates to:
  /// **'This user already sent you a request. Review it in your Friends section.'**
  String get friendIncomingRequestFromProfile;

  /// No description provided for @friendProfileSelf.
  ///
  /// In en, this message translates to:
  /// **'This is your own friend profile link.'**
  String get friendProfileSelf;

  /// No description provided for @friendProfileRequestPrompt.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to be friends with you.'**
  String friendProfileRequestPrompt(String name);

  /// No description provided for @friendProfilePublicPrompt.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to be your friend on Glass Trail.'**
  String friendProfilePublicPrompt(String name);

  /// No description provided for @friendStatsNotSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics not shared'**
  String get friendStatsNotSharedTitle;

  /// No description provided for @friendStatsNotSharedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is not sharing statistics with friends right now.'**
  String friendStatsNotSharedBody(String name);

  /// No description provided for @friendStatsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend profile unavailable'**
  String get friendStatsUnavailableTitle;

  /// No description provided for @friendStatsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This friend\'s shared profile is unavailable or no longer shared with you.'**
  String get friendStatsUnavailableBody;

  /// No description provided for @addAsFriend.
  ///
  /// In en, this message translates to:
  /// **'Add as friend'**
  String get addAsFriend;

  /// No description provided for @goToFeed.
  ///
  /// In en, this message translates to:
  /// **'Go to feed'**
  String get goToFeed;

  /// No description provided for @withdrawFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawFriendRequest;

  /// No description provided for @unfriend.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get unfriend;

  /// No description provided for @unfriendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfriend {name}?'**
  String unfriendConfirmTitle(String name);

  /// No description provided for @unfriendConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You and {name} will stop seeing each other\'s shared activity. You can send another friend request later.'**
  String unfriendConfirmBody(String name);

  /// No description provided for @friendProfileLinkInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile link unavailable'**
  String get friendProfileLinkInvalidTitle;

  /// No description provided for @friendProfileLinkInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'This friend profile link is invalid or no longer available.'**
  String get friendProfileLinkInvalidBody;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications right now'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When friends log drinks or send you friend requests, you\'ll see them here. Read notifications are deleted after 30 days, unread notifications after 90 days.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationFriendRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a friend request'**
  String notificationFriendRequestSentTitle(String name);

  /// No description provided for @notificationFriendRequestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Review it in your Friends section.'**
  String get notificationFriendRequestSentBody;

  /// No description provided for @notificationFriendRequestAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your friend request'**
  String notificationFriendRequestAcceptedTitle(String name);

  /// No description provided for @notificationFriendRequestAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'You can now see each other\'s shared activity.'**
  String get notificationFriendRequestAcceptedBody;

  /// No description provided for @notificationFriendRequestRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} declined your friend request'**
  String notificationFriendRequestRejectedTitle(String name);

  /// No description provided for @notificationFriendRequestRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'You can send another request later.'**
  String get notificationFriendRequestRejectedBody;

  /// No description provided for @notificationFriendRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} removed you as a friend'**
  String notificationFriendRemovedTitle(String name);

  /// No description provided for @notificationFriendRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'Open your Friends section to review your connections.'**
  String get notificationFriendRemovedBody;

  /// No description provided for @notificationFriendDrinkCheeredTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a cheers 🍻'**
  String notificationFriendDrinkCheeredTitle(String name);

  /// No description provided for @notificationFriendDrinkCheeredBody.
  ///
  /// In en, this message translates to:
  /// **''**
  String get notificationFriendDrinkCheeredBody;

  /// No description provided for @notificationFriendDrinkLoggedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} drinks {drink}'**
  String notificationFriendDrinkLoggedTitle(String name, String drink);

  /// No description provided for @notificationFriendDrinkLoggedBody.
  ///
  /// In en, this message translates to:
  /// **'{commentLine}\n{locationAddressLine}'**
  String notificationFriendDrinkLoggedBody(
    String commentLine,
    String locationAddressLine,
  );

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @customDrinks.
  ///
  /// In en, this message translates to:
  /// **'My custom drinks'**
  String get customDrinks;

  /// No description provided for @addCustomDrinkAction.
  ///
  /// In en, this message translates to:
  /// **'Add custom drink'**
  String get addCustomDrinkAction;

  /// No description provided for @customDrinksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No custom drinks yet'**
  String get customDrinksEmptyTitle;

  /// No description provided for @customDrinksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first custom drink and it will appear here.'**
  String get customDrinksEmptyBody;

  /// No description provided for @statisticsHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get statisticsHistoryEmptyTitle;

  /// No description provided for @statisticsHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Logged drinks will appear here as your personal history.'**
  String get statisticsHistoryEmptyBody;

  /// No description provided for @roadmap.
  ///
  /// In en, this message translates to:
  /// **'Planned next'**
  String get roadmap;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @roadmapBody.
  ///
  /// In en, this message translates to:
  /// **'Achievements are planned next.'**
  String get roadmapBody;

  /// No description provided for @beerWithMeImport.
  ///
  /// In en, this message translates to:
  /// **'Beer With Me Import'**
  String get beerWithMeImport;

  /// No description provided for @beerWithMeImportBody.
  ///
  /// In en, this message translates to:
  /// **'Import a Beer With Me export into your GlassTrail history. Existing Beer With Me imports are detected and skipped automatically.'**
  String get beerWithMeImportBody;

  /// No description provided for @beerWithMePostSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Import your Beer With Me history?'**
  String get beerWithMePostSignUpTitle;

  /// No description provided for @beerWithMePostSignUpBody.
  ///
  /// In en, this message translates to:
  /// **'If you already tracked drinks in Beer With Me, you can import that export now and keep your history in GlassTrail.'**
  String get beerWithMePostSignUpBody;

  /// No description provided for @beerWithMePostSignUpHint.
  ///
  /// In en, this message translates to:
  /// **'You can also import it later from the profile screen.'**
  String get beerWithMePostSignUpHint;

  /// No description provided for @beerWithMeImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import Beer With Me export'**
  String get beerWithMeImportAction;

  /// No description provided for @beerWithMeImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected Beer With Me export does not contain any entries.'**
  String get beerWithMeImportEmpty;

  /// No description provided for @beerWithMeImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid Beer With Me export.'**
  String get beerWithMeImportInvalidFile;

  /// No description provided for @beerWithMeImportReadFailed.
  ///
  /// In en, this message translates to:
  /// **'The Beer With Me export could not be read.'**
  String get beerWithMeImportReadFailed;

  /// No description provided for @beerWithMeImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Beer With Me export?'**
  String get beerWithMeImportConfirmTitle;

  /// No description provided for @beerWithMeImportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will import {count} entries into your GlassTrail history.'**
  String beerWithMeImportConfirmBody(int count);

  /// No description provided for @beerWithMeImportProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing {processed} of {total} entries'**
  String beerWithMeImportProgress(int processed, int total);

  /// No description provided for @beerWithMeImportProgressDetails.
  ///
  /// In en, this message translates to:
  /// **'{imported} imported, {skipped} duplicates, {errors} errors'**
  String beerWithMeImportProgressDetails(int imported, int skipped, int errors);

  /// No description provided for @beerWithMeImportCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel import'**
  String get beerWithMeImportCancelAction;

  /// No description provided for @beerWithMeImportCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling after the current entry...'**
  String get beerWithMeImportCancelling;

  /// No description provided for @beerWithMeImportResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Beer With Me import result'**
  String get beerWithMeImportResultTitle;

  /// No description provided for @beerWithMeImportResultCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled after {processed} of {total} entries.'**
  String beerWithMeImportResultCancelled(int processed, int total);

  /// No description provided for @beerWithMeImportResultTotal.
  ///
  /// In en, this message translates to:
  /// **'Total entries: {count}'**
  String beerWithMeImportResultTotal(int count);

  /// No description provided for @beerWithMeImportResultImported.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully: {count}'**
  String beerWithMeImportResultImported(int count);

  /// No description provided for @beerWithMeImportResultSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped as duplicates: {count}'**
  String beerWithMeImportResultSkipped(int count);

  /// No description provided for @beerWithMeImportResultErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors: {count}'**
  String beerWithMeImportResultErrors(int count);

  /// No description provided for @beerWithMeImportErrorListTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed entries'**
  String get beerWithMeImportErrorListTitle;

  /// No description provided for @beerWithMeImportInvalidEntry.
  ///
  /// In en, this message translates to:
  /// **'The entry is not a valid JSON object.'**
  String get beerWithMeImportInvalidEntry;

  /// No description provided for @beerWithMeImportMissingId.
  ///
  /// In en, this message translates to:
  /// **'BeerWithMe ID missing'**
  String get beerWithMeImportMissingId;

  /// No description provided for @beerWithMeImportMissingGlassType.
  ///
  /// In en, this message translates to:
  /// **'BeerWithMe drink type missing'**
  String get beerWithMeImportMissingGlassType;

  /// No description provided for @beerWithMeImportMissingTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp missing'**
  String get beerWithMeImportMissingTimestamp;

  /// No description provided for @beerWithMeImportInvalidTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Invalid timestamp'**
  String get beerWithMeImportInvalidTimestamp;

  /// No description provided for @beerWithMeImportUnknownGlassType.
  ///
  /// In en, this message translates to:
  /// **'BeerWithMe type \"{glassType}\" not supported.'**
  String beerWithMeImportUnknownGlassType(String glassType);

  /// No description provided for @beerWithMeImportMissingMappedDrink.
  ///
  /// In en, this message translates to:
  /// **'GlassTrail could not find the mapped drink for \"{glassType}\".'**
  String beerWithMeImportMissingMappedDrink(String glassType);

  /// No description provided for @beerWithMeImportAlreadyImported.
  ///
  /// In en, this message translates to:
  /// **'BeerWithMe entry was already imported.'**
  String get beerWithMeImportAlreadyImported;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @handednessRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get handednessRight;

  /// No description provided for @handednessLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get handednessLeft;

  /// No description provided for @invalidRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get invalidRequired;

  /// No description provided for @emptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No drinks match the current filter.'**
  String get emptyFilter;

  /// No description provided for @launchingApp.
  ///
  /// In en, this message translates to:
  /// **'Loading your drinks and settings.'**
  String get launchingApp;

  /// No description provided for @welcomeToGlassTrail.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Glass Trail.'**
  String get welcomeToGlassTrail;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get welcomeBack;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get changePasswordSuccess;

  /// No description provided for @customDrinkSaved.
  ///
  /// In en, this message translates to:
  /// **'Custom drink saved.'**
  String get customDrinkSaved;

  /// No description provided for @customDrinkDeleted.
  ///
  /// In en, this message translates to:
  /// **'Custom drink deleted.'**
  String get customDrinkDeleted;

  /// Shown after logging a drink entry
  ///
  /// In en, this message translates to:
  /// **'{drink} logged.'**
  String drinkLogged(String drink);

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated.'**
  String get entryUpdated;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted.'**
  String get entryDeleted;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent.'**
  String get friendRequestSent;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted.'**
  String get friendRequestAccepted;

  /// No description provided for @friendRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Friend request rejected.'**
  String get friendRequestRejected;

  /// No description provided for @friendRequestCanceled.
  ///
  /// In en, this message translates to:
  /// **'Friend request withdrawn.'**
  String get friendRequestCanceled;

  /// No description provided for @friendRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend removed.'**
  String get friendRemoved;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with that email already exists.'**
  String get accountAlreadyExists;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get invalidCredentials;

  /// No description provided for @changePasswordCurrentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get changePasswordCurrentPasswordIncorrect;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be updated.'**
  String get profileUpdateFailed;

  /// No description provided for @changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'The password could not be changed.'**
  String get changePasswordFailed;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'The account could not be deleted.'**
  String get deleteAccountFailed;

  /// No description provided for @entryUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The drink entry could not be updated.'**
  String get entryUpdateFailed;

  /// No description provided for @entryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The drink entry could not be deleted.'**
  String get entryDeleteFailed;

  /// No description provided for @friendProfileLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'The profile link is invalid.'**
  String get friendProfileLinkInvalid;

  /// No description provided for @friendSelfRequestBlocked.
  ///
  /// In en, this message translates to:
  /// **'You cannot add yourself as a friend.'**
  String get friendSelfRequestBlocked;

  /// No description provided for @friendRequestAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'The friend request could not be accepted.'**
  String get friendRequestAcceptFailed;

  /// No description provided for @friendRequestRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'The friend request could not be rejected.'**
  String get friendRequestRejectFailed;

  /// No description provided for @friendRequestCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'The friend request could not be withdrawn.'**
  String get friendRequestCancelFailed;

  /// No description provided for @friendRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'The friend could not be removed.'**
  String get friendRemoveFailed;

  /// No description provided for @customDrinkDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The custom drink could not be deleted.'**
  String get customDrinkDeleteFailed;

  /// No description provided for @customDrinkAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a custom drink with that name.'**
  String get customDrinkAlreadyExists;

  /// No description provided for @signUpMissingUser.
  ///
  /// In en, this message translates to:
  /// **'Sign-up did not return a user.'**
  String get signUpMissingUser;

  /// No description provided for @signUpConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.'**
  String get signUpConfirmationRequired;

  /// No description provided for @beer.
  ///
  /// In en, this message translates to:
  /// **'Beer'**
  String get beer;

  /// No description provided for @wine.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get wine;

  /// No description provided for @sparklingWines.
  ///
  /// In en, this message translates to:
  /// **'Sparkling Wines'**
  String get sparklingWines;

  /// No description provided for @longdrinks.
  ///
  /// In en, this message translates to:
  /// **'Longdrinks'**
  String get longdrinks;

  /// No description provided for @spirits.
  ///
  /// In en, this message translates to:
  /// **'Spirits'**
  String get spirits;

  /// No description provided for @shots.
  ///
  /// In en, this message translates to:
  /// **'Shots'**
  String get shots;

  /// No description provided for @cocktails.
  ///
  /// In en, this message translates to:
  /// **'Cocktails'**
  String get cocktails;

  /// No description provided for @appleWines.
  ///
  /// In en, this message translates to:
  /// **'Apple Wines'**
  String get appleWines;

  /// No description provided for @nonAlcoholic.
  ///
  /// In en, this message translates to:
  /// **'Non-alcoholic'**
  String get nonAlcoholic;

  /// Unit label for streak length
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String dayLabel(num count);

  /// No description provided for @achievementFamilyTotalDrinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Cheers Chase'**
  String get achievementFamilyTotalDrinksTitle;

  /// No description provided for @achievementFamilyTotalDrinksLevel1Title.
  ///
  /// In en, this message translates to:
  /// **'First Pour'**
  String get achievementFamilyTotalDrinksLevel1Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel1Description.
  ///
  /// In en, this message translates to:
  /// **'Log your first drink.'**
  String get achievementFamilyTotalDrinksLevel1Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Sip Starter'**
  String get achievementFamilyTotalDrinksLevel10Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 drinks.'**
  String get achievementFamilyTotalDrinksLevel10Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Glass Gatherer'**
  String get achievementFamilyTotalDrinksLevel25Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 drinks.'**
  String get achievementFamilyTotalDrinksLevel25Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Pour Pacer'**
  String get achievementFamilyTotalDrinksLevel50Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 drinks.'**
  String get achievementFamilyTotalDrinksLevel50Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Cheers Charger'**
  String get achievementFamilyTotalDrinksLevel100Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 drinks.'**
  String get achievementFamilyTotalDrinksLevel100Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Pour Pathfinder'**
  String get achievementFamilyTotalDrinksLevel200Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 drinks.'**
  String get achievementFamilyTotalDrinksLevel200Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Toast Tactician'**
  String get achievementFamilyTotalDrinksLevel300Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 drinks.'**
  String get achievementFamilyTotalDrinksLevel300Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Celebration Commander'**
  String get achievementFamilyTotalDrinksLevel400Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 drinks.'**
  String get achievementFamilyTotalDrinksLevel400Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Party Patron'**
  String get achievementFamilyTotalDrinksLevel500Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 drinks.'**
  String get achievementFamilyTotalDrinksLevel500Description;

  /// No description provided for @achievementFamilyTotalDrinksLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Cheers Champion'**
  String get achievementFamilyTotalDrinksLevel1000Title;

  /// No description provided for @achievementFamilyTotalDrinksLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 drinks.'**
  String get achievementFamilyTotalDrinksLevel1000Description;

  /// No description provided for @achievementFamilyStreaksTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Drive'**
  String get achievementFamilyStreaksTitle;

  /// No description provided for @achievementFamilyStreaksLevel3Title.
  ///
  /// In en, this message translates to:
  /// **'Streak Starter'**
  String get achievementFamilyStreaksLevel3Title;

  /// No description provided for @achievementFamilyStreaksLevel3Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 3-day streak.'**
  String get achievementFamilyStreaksLevel3Description;

  /// No description provided for @achievementFamilyStreaksLevel7Title.
  ///
  /// In en, this message translates to:
  /// **'Week Warrior'**
  String get achievementFamilyStreaksLevel7Title;

  /// No description provided for @achievementFamilyStreaksLevel7Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 7-day streak.'**
  String get achievementFamilyStreaksLevel7Description;

  /// No description provided for @achievementFamilyStreaksLevel14Title.
  ///
  /// In en, this message translates to:
  /// **'Fortnight Flow'**
  String get achievementFamilyStreaksLevel14Title;

  /// No description provided for @achievementFamilyStreaksLevel14Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 14-day streak.'**
  String get achievementFamilyStreaksLevel14Description;

  /// No description provided for @achievementFamilyStreaksLevel30Title.
  ///
  /// In en, this message translates to:
  /// **'Thirty-Day Thunder'**
  String get achievementFamilyStreaksLevel30Title;

  /// No description provided for @achievementFamilyStreaksLevel30Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 30-day streak.'**
  String get achievementFamilyStreaksLevel30Description;

  /// No description provided for @achievementFamilyStreaksLevel60Title.
  ///
  /// In en, this message translates to:
  /// **'Stamina Sipper'**
  String get achievementFamilyStreaksLevel60Title;

  /// No description provided for @achievementFamilyStreaksLevel60Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 60-day streak.'**
  String get achievementFamilyStreaksLevel60Description;

  /// No description provided for @achievementFamilyStreaksLevel90Title.
  ///
  /// In en, this message translates to:
  /// **'Ninety Navigator'**
  String get achievementFamilyStreaksLevel90Title;

  /// No description provided for @achievementFamilyStreaksLevel90Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 90-day streak.'**
  String get achievementFamilyStreaksLevel90Description;

  /// No description provided for @achievementFamilyStreaksLevel180Title.
  ///
  /// In en, this message translates to:
  /// **'Endurance Elite'**
  String get achievementFamilyStreaksLevel180Title;

  /// No description provided for @achievementFamilyStreaksLevel180Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 180-day streak.'**
  String get achievementFamilyStreaksLevel180Description;

  /// No description provided for @achievementFamilyStreaksLevel365Title.
  ///
  /// In en, this message translates to:
  /// **'Daily Dynasty'**
  String get achievementFamilyStreaksLevel365Title;

  /// No description provided for @achievementFamilyStreaksLevel365Description.
  ///
  /// In en, this message translates to:
  /// **'Reach a 365-day streak.'**
  String get achievementFamilyStreaksLevel365Description;

  /// No description provided for @achievementFamilyBeerTitle.
  ///
  /// In en, this message translates to:
  /// **'Brew Quest'**
  String get achievementFamilyBeerTitle;

  /// No description provided for @achievementFamilyBeerLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Beer Rookie'**
  String get achievementFamilyBeerLevel10Title;

  /// No description provided for @achievementFamilyBeerLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 beers.'**
  String get achievementFamilyBeerLevel10Description;

  /// No description provided for @achievementFamilyBeerLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Foam Friend'**
  String get achievementFamilyBeerLevel25Title;

  /// No description provided for @achievementFamilyBeerLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 beers.'**
  String get achievementFamilyBeerLevel25Description;

  /// No description provided for @achievementFamilyBeerLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Brew Browser'**
  String get achievementFamilyBeerLevel50Title;

  /// No description provided for @achievementFamilyBeerLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 beers.'**
  String get achievementFamilyBeerLevel50Description;

  /// No description provided for @achievementFamilyBeerLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Hop Hero'**
  String get achievementFamilyBeerLevel100Title;

  /// No description provided for @achievementFamilyBeerLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 beers.'**
  String get achievementFamilyBeerLevel100Description;

  /// No description provided for @achievementFamilyBeerLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Brew Boss'**
  String get achievementFamilyBeerLevel200Title;

  /// No description provided for @achievementFamilyBeerLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 beers.'**
  String get achievementFamilyBeerLevel200Description;

  /// No description provided for @achievementFamilyBeerLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Hop Honcho'**
  String get achievementFamilyBeerLevel300Title;

  /// No description provided for @achievementFamilyBeerLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 beers.'**
  String get achievementFamilyBeerLevel300Description;

  /// No description provided for @achievementFamilyBeerLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Beer Baron'**
  String get achievementFamilyBeerLevel400Title;

  /// No description provided for @achievementFamilyBeerLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 beers.'**
  String get achievementFamilyBeerLevel400Description;

  /// No description provided for @achievementFamilyBeerLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Brew Legend'**
  String get achievementFamilyBeerLevel500Title;

  /// No description provided for @achievementFamilyBeerLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 beers.'**
  String get achievementFamilyBeerLevel500Description;

  /// No description provided for @achievementFamilyBeerLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Beer Immortal'**
  String get achievementFamilyBeerLevel1000Title;

  /// No description provided for @achievementFamilyBeerLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 beers.'**
  String get achievementFamilyBeerLevel1000Description;

  /// No description provided for @achievementFamilyWineTitle.
  ///
  /// In en, this message translates to:
  /// **'Vintage Voyage'**
  String get achievementFamilyWineTitle;

  /// No description provided for @achievementFamilyWineLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Grape Guest'**
  String get achievementFamilyWineLevel10Title;

  /// No description provided for @achievementFamilyWineLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 wines.'**
  String get achievementFamilyWineLevel10Description;

  /// No description provided for @achievementFamilyWineLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Vine Visitor'**
  String get achievementFamilyWineLevel25Title;

  /// No description provided for @achievementFamilyWineLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 wines.'**
  String get achievementFamilyWineLevel25Description;

  /// No description provided for @achievementFamilyWineLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Grape Gatherer'**
  String get achievementFamilyWineLevel50Title;

  /// No description provided for @achievementFamilyWineLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 wines.'**
  String get achievementFamilyWineLevel50Description;

  /// No description provided for @achievementFamilyWineLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Cork Commander'**
  String get achievementFamilyWineLevel100Title;

  /// No description provided for @achievementFamilyWineLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 wines.'**
  String get achievementFamilyWineLevel100Description;

  /// No description provided for @achievementFamilyWineLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Vine Virtuoso'**
  String get achievementFamilyWineLevel200Title;

  /// No description provided for @achievementFamilyWineLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 wines.'**
  String get achievementFamilyWineLevel200Description;

  /// No description provided for @achievementFamilyWineLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Grape Guru'**
  String get achievementFamilyWineLevel300Title;

  /// No description provided for @achievementFamilyWineLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 wines.'**
  String get achievementFamilyWineLevel300Description;

  /// No description provided for @achievementFamilyWineLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Wine Wizard'**
  String get achievementFamilyWineLevel400Title;

  /// No description provided for @achievementFamilyWineLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 wines.'**
  String get achievementFamilyWineLevel400Description;

  /// No description provided for @achievementFamilyWineLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Vine VIP'**
  String get achievementFamilyWineLevel500Title;

  /// No description provided for @achievementFamilyWineLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 wines.'**
  String get achievementFamilyWineLevel500Description;

  /// No description provided for @achievementFamilyWineLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Wine Wonder'**
  String get achievementFamilyWineLevel1000Title;

  /// No description provided for @achievementFamilyWineLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 wines.'**
  String get achievementFamilyWineLevel1000Description;

  /// No description provided for @achievementFamilySparklingWinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Spark Sprint'**
  String get achievementFamilySparklingWinesTitle;

  /// No description provided for @achievementFamilySparklingWinesLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Spark Starter'**
  String get achievementFamilySparklingWinesLevel10Title;

  /// No description provided for @achievementFamilySparklingWinesLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel10Description;

  /// No description provided for @achievementFamilySparklingWinesLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Fizz Friend'**
  String get achievementFamilySparklingWinesLevel25Title;

  /// No description provided for @achievementFamilySparklingWinesLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel25Description;

  /// No description provided for @achievementFamilySparklingWinesLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Spark Seeker'**
  String get achievementFamilySparklingWinesLevel50Title;

  /// No description provided for @achievementFamilySparklingWinesLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel50Description;

  /// No description provided for @achievementFamilySparklingWinesLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Fizz Foreman'**
  String get achievementFamilySparklingWinesLevel100Title;

  /// No description provided for @achievementFamilySparklingWinesLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel100Description;

  /// No description provided for @achievementFamilySparklingWinesLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Cuvée Captain'**
  String get achievementFamilySparklingWinesLevel200Title;

  /// No description provided for @achievementFamilySparklingWinesLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel200Description;

  /// No description provided for @achievementFamilySparklingWinesLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Spark Sovereign'**
  String get achievementFamilySparklingWinesLevel300Title;

  /// No description provided for @achievementFamilySparklingWinesLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel300Description;

  /// No description provided for @achievementFamilySparklingWinesLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Cuvée Conqueror'**
  String get achievementFamilySparklingWinesLevel400Title;

  /// No description provided for @achievementFamilySparklingWinesLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel400Description;

  /// No description provided for @achievementFamilySparklingWinesLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Fizz Fame'**
  String get achievementFamilySparklingWinesLevel500Title;

  /// No description provided for @achievementFamilySparklingWinesLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel500Description;

  /// No description provided for @achievementFamilySparklingWinesLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Spark Supreme'**
  String get achievementFamilySparklingWinesLevel1000Title;

  /// No description provided for @achievementFamilySparklingWinesLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 sparkling wines.'**
  String get achievementFamilySparklingWinesLevel1000Description;

  /// No description provided for @achievementFamilyLongdrinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Mixer Marathon'**
  String get achievementFamilyLongdrinksTitle;

  /// No description provided for @achievementFamilyLongdrinksLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Longdrink Learner'**
  String get achievementFamilyLongdrinksLevel10Title;

  /// No description provided for @achievementFamilyLongdrinksLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 longdrinks.'**
  String get achievementFamilyLongdrinksLevel10Description;

  /// No description provided for @achievementFamilyLongdrinksLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Mixer Mate'**
  String get achievementFamilyLongdrinksLevel25Title;

  /// No description provided for @achievementFamilyLongdrinksLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 longdrinks.'**
  String get achievementFamilyLongdrinksLevel25Description;

  /// No description provided for @achievementFamilyLongdrinksLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Longdrink Loyalist'**
  String get achievementFamilyLongdrinksLevel50Title;

  /// No description provided for @achievementFamilyLongdrinksLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 longdrinks.'**
  String get achievementFamilyLongdrinksLevel50Description;

  /// No description provided for @achievementFamilyLongdrinksLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Mixer Master'**
  String get achievementFamilyLongdrinksLevel100Title;

  /// No description provided for @achievementFamilyLongdrinksLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 longdrinks.'**
  String get achievementFamilyLongdrinksLevel100Description;

  /// No description provided for @achievementFamilyLongdrinksLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Longdrink Leader'**
  String get achievementFamilyLongdrinksLevel200Title;

  /// No description provided for @achievementFamilyLongdrinksLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 longdrinks.'**
  String get achievementFamilyLongdrinksLevel200Description;

  /// No description provided for @achievementFamilyLongdrinksLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Mix Monarch'**
  String get achievementFamilyLongdrinksLevel300Title;

  /// No description provided for @achievementFamilyLongdrinksLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 longdrinks.'**
  String get achievementFamilyLongdrinksLevel300Description;

  /// No description provided for @achievementFamilyLongdrinksLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Mixer Mogul'**
  String get achievementFamilyLongdrinksLevel400Title;

  /// No description provided for @achievementFamilyLongdrinksLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 longdrinks.'**
  String get achievementFamilyLongdrinksLevel400Description;

  /// No description provided for @achievementFamilyLongdrinksLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Pour Prince'**
  String get achievementFamilyLongdrinksLevel500Title;

  /// No description provided for @achievementFamilyLongdrinksLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 longdrinks.'**
  String get achievementFamilyLongdrinksLevel500Description;

  /// No description provided for @achievementFamilyLongdrinksLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Mixer Immortal'**
  String get achievementFamilyLongdrinksLevel1000Title;

  /// No description provided for @achievementFamilyLongdrinksLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 longdrinks.'**
  String get achievementFamilyLongdrinksLevel1000Description;

  /// No description provided for @achievementFamilySpiritsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spirit Sprint'**
  String get achievementFamilySpiritsTitle;

  /// No description provided for @achievementFamilySpiritsLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Spirit Starter'**
  String get achievementFamilySpiritsLevel10Title;

  /// No description provided for @achievementFamilySpiritsLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 spirits.'**
  String get achievementFamilySpiritsLevel10Description;

  /// No description provided for @achievementFamilySpiritsLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Dram Dabbler'**
  String get achievementFamilySpiritsLevel25Title;

  /// No description provided for @achievementFamilySpiritsLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 spirits.'**
  String get achievementFamilySpiritsLevel25Description;

  /// No description provided for @achievementFamilySpiritsLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Pour Pal'**
  String get achievementFamilySpiritsLevel50Title;

  /// No description provided for @achievementFamilySpiritsLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 spirits.'**
  String get achievementFamilySpiritsLevel50Description;

  /// No description provided for @achievementFamilySpiritsLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Spirit Specialist'**
  String get achievementFamilySpiritsLevel100Title;

  /// No description provided for @achievementFamilySpiritsLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 spirits.'**
  String get achievementFamilySpiritsLevel100Description;

  /// No description provided for @achievementFamilySpiritsLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Pour Pioneer'**
  String get achievementFamilySpiritsLevel200Title;

  /// No description provided for @achievementFamilySpiritsLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 spirits.'**
  String get achievementFamilySpiritsLevel200Description;

  /// No description provided for @achievementFamilySpiritsLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Neat Noble'**
  String get achievementFamilySpiritsLevel300Title;

  /// No description provided for @achievementFamilySpiritsLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 spirits.'**
  String get achievementFamilySpiritsLevel300Description;

  /// No description provided for @achievementFamilySpiritsLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Spirit Supremo'**
  String get achievementFamilySpiritsLevel400Title;

  /// No description provided for @achievementFamilySpiritsLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 spirits.'**
  String get achievementFamilySpiritsLevel400Description;

  /// No description provided for @achievementFamilySpiritsLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Pour Prestige'**
  String get achievementFamilySpiritsLevel500Title;

  /// No description provided for @achievementFamilySpiritsLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 spirits.'**
  String get achievementFamilySpiritsLevel500Description;

  /// No description provided for @achievementFamilySpiritsLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Spirit Immortal'**
  String get achievementFamilySpiritsLevel1000Title;

  /// No description provided for @achievementFamilySpiritsLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 spirits.'**
  String get achievementFamilySpiritsLevel1000Description;

  /// No description provided for @achievementFamilyShotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Kick'**
  String get achievementFamilyShotsTitle;

  /// No description provided for @achievementFamilyShotsLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Quick Quencher'**
  String get achievementFamilyShotsLevel10Title;

  /// No description provided for @achievementFamilyShotsLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 shots.'**
  String get achievementFamilyShotsLevel10Description;

  /// No description provided for @achievementFamilyShotsLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Shot Scout'**
  String get achievementFamilyShotsLevel25Title;

  /// No description provided for @achievementFamilyShotsLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 shots.'**
  String get achievementFamilyShotsLevel25Description;

  /// No description provided for @achievementFamilyShotsLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Shot Sprinter'**
  String get achievementFamilyShotsLevel50Title;

  /// No description provided for @achievementFamilyShotsLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 shots.'**
  String get achievementFamilyShotsLevel50Description;

  /// No description provided for @achievementFamilyShotsLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Quick Commander'**
  String get achievementFamilyShotsLevel100Title;

  /// No description provided for @achievementFamilyShotsLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 shots.'**
  String get achievementFamilyShotsLevel100Description;

  /// No description provided for @achievementFamilyShotsLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Shot Sovereign'**
  String get achievementFamilyShotsLevel200Title;

  /// No description provided for @achievementFamilyShotsLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 shots.'**
  String get achievementFamilyShotsLevel200Description;

  /// No description provided for @achievementFamilyShotsLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Quick King'**
  String get achievementFamilyShotsLevel300Title;

  /// No description provided for @achievementFamilyShotsLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 shots.'**
  String get achievementFamilyShotsLevel300Description;

  /// No description provided for @achievementFamilyShotsLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Shot Supreme'**
  String get achievementFamilyShotsLevel400Title;

  /// No description provided for @achievementFamilyShotsLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 shots.'**
  String get achievementFamilyShotsLevel400Description;

  /// No description provided for @achievementFamilyShotsLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Tiny Tornado'**
  String get achievementFamilyShotsLevel500Title;

  /// No description provided for @achievementFamilyShotsLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 shots.'**
  String get achievementFamilyShotsLevel500Description;

  /// No description provided for @achievementFamilyShotsLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Shot Immortal'**
  String get achievementFamilyShotsLevel1000Title;

  /// No description provided for @achievementFamilyShotsLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 shots.'**
  String get achievementFamilyShotsLevel1000Description;

  /// No description provided for @achievementFamilyCocktailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cocktail Craze'**
  String get achievementFamilyCocktailsTitle;

  /// No description provided for @achievementFamilyCocktailsLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Cocktail Cadet'**
  String get achievementFamilyCocktailsLevel10Title;

  /// No description provided for @achievementFamilyCocktailsLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 cocktails.'**
  String get achievementFamilyCocktailsLevel10Description;

  /// No description provided for @achievementFamilyCocktailsLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Mixer Muse'**
  String get achievementFamilyCocktailsLevel25Title;

  /// No description provided for @achievementFamilyCocktailsLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 cocktails.'**
  String get achievementFamilyCocktailsLevel25Description;

  /// No description provided for @achievementFamilyCocktailsLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Glass Glam'**
  String get achievementFamilyCocktailsLevel50Title;

  /// No description provided for @achievementFamilyCocktailsLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 cocktails.'**
  String get achievementFamilyCocktailsLevel50Description;

  /// No description provided for @achievementFamilyCocktailsLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Shaker Specialist'**
  String get achievementFamilyCocktailsLevel100Title;

  /// No description provided for @achievementFamilyCocktailsLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 cocktails.'**
  String get achievementFamilyCocktailsLevel100Description;

  /// No description provided for @achievementFamilyCocktailsLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Cocktail Charmer'**
  String get achievementFamilyCocktailsLevel200Title;

  /// No description provided for @achievementFamilyCocktailsLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 cocktails.'**
  String get achievementFamilyCocktailsLevel200Description;

  /// No description provided for @achievementFamilyCocktailsLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Glass Guru'**
  String get achievementFamilyCocktailsLevel300Title;

  /// No description provided for @achievementFamilyCocktailsLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 cocktails.'**
  String get achievementFamilyCocktailsLevel300Description;

  /// No description provided for @achievementFamilyCocktailsLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Mixer Majesty'**
  String get achievementFamilyCocktailsLevel400Title;

  /// No description provided for @achievementFamilyCocktailsLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 cocktails.'**
  String get achievementFamilyCocktailsLevel400Description;

  /// No description provided for @achievementFamilyCocktailsLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Shaker Legend'**
  String get achievementFamilyCocktailsLevel500Title;

  /// No description provided for @achievementFamilyCocktailsLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 cocktails.'**
  String get achievementFamilyCocktailsLevel500Description;

  /// No description provided for @achievementFamilyCocktailsLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Cocktail Icon'**
  String get achievementFamilyCocktailsLevel1000Title;

  /// No description provided for @achievementFamilyCocktailsLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 cocktails.'**
  String get achievementFamilyCocktailsLevel1000Description;

  /// No description provided for @achievementFamilyAppleWinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cider Circuit'**
  String get achievementFamilyAppleWinesTitle;

  /// No description provided for @achievementFamilyAppleWinesLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Apple Apprentice'**
  String get achievementFamilyAppleWinesLevel10Title;

  /// No description provided for @achievementFamilyAppleWinesLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 apple wines.'**
  String get achievementFamilyAppleWinesLevel10Description;

  /// No description provided for @achievementFamilyAppleWinesLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Cider Scout'**
  String get achievementFamilyAppleWinesLevel25Title;

  /// No description provided for @achievementFamilyAppleWinesLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 apple wines.'**
  String get achievementFamilyAppleWinesLevel25Description;

  /// No description provided for @achievementFamilyAppleWinesLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Cider Chaser'**
  String get achievementFamilyAppleWinesLevel50Title;

  /// No description provided for @achievementFamilyAppleWinesLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 apple wines.'**
  String get achievementFamilyAppleWinesLevel50Description;

  /// No description provided for @achievementFamilyAppleWinesLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Apple Ace'**
  String get achievementFamilyAppleWinesLevel100Title;

  /// No description provided for @achievementFamilyAppleWinesLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 apple wines.'**
  String get achievementFamilyAppleWinesLevel100Description;

  /// No description provided for @achievementFamilyAppleWinesLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Cider Captain'**
  String get achievementFamilyAppleWinesLevel200Title;

  /// No description provided for @achievementFamilyAppleWinesLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 apple wines.'**
  String get achievementFamilyAppleWinesLevel200Description;

  /// No description provided for @achievementFamilyAppleWinesLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Apple Aristocrat'**
  String get achievementFamilyAppleWinesLevel300Title;

  /// No description provided for @achievementFamilyAppleWinesLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 apple wines.'**
  String get achievementFamilyAppleWinesLevel300Description;

  /// No description provided for @achievementFamilyAppleWinesLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Cider Crown'**
  String get achievementFamilyAppleWinesLevel400Title;

  /// No description provided for @achievementFamilyAppleWinesLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 apple wines.'**
  String get achievementFamilyAppleWinesLevel400Description;

  /// No description provided for @achievementFamilyAppleWinesLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Apple Authority'**
  String get achievementFamilyAppleWinesLevel500Title;

  /// No description provided for @achievementFamilyAppleWinesLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 apple wines.'**
  String get achievementFamilyAppleWinesLevel500Description;

  /// No description provided for @achievementFamilyAppleWinesLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Cider Immortal'**
  String get achievementFamilyAppleWinesLevel1000Title;

  /// No description provided for @achievementFamilyAppleWinesLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 apple wines.'**
  String get achievementFamilyAppleWinesLevel1000Description;

  /// No description provided for @achievementFamilyNonAlcoholicTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero Zest'**
  String get achievementFamilyNonAlcoholicTitle;

  /// No description provided for @achievementFamilyNonAlcoholicLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Starter'**
  String get achievementFamilyNonAlcoholicLevel10Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel10Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Clear Cruiser'**
  String get achievementFamilyNonAlcoholicLevel25Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel25Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Hydro Hero'**
  String get achievementFamilyNonAlcoholicLevel50Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel50Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Pro'**
  String get achievementFamilyNonAlcoholicLevel100Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel100Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel200Title.
  ///
  /// In en, this message translates to:
  /// **'Clear Commander'**
  String get achievementFamilyNonAlcoholicLevel200Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel200Description.
  ///
  /// In en, this message translates to:
  /// **'Log 200 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel200Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel300Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Virtuoso'**
  String get achievementFamilyNonAlcoholicLevel300Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel300Description.
  ///
  /// In en, this message translates to:
  /// **'Log 300 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel300Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel400Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Maestro'**
  String get achievementFamilyNonAlcoholicLevel400Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel400Description.
  ///
  /// In en, this message translates to:
  /// **'Log 400 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel400Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel500Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Zenith'**
  String get achievementFamilyNonAlcoholicLevel500Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel500Description.
  ///
  /// In en, this message translates to:
  /// **'Log 500 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel500Description;

  /// No description provided for @achievementFamilyNonAlcoholicLevel1000Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Hero'**
  String get achievementFamilyNonAlcoholicLevel1000Title;

  /// No description provided for @achievementFamilyNonAlcoholicLevel1000Description.
  ///
  /// In en, this message translates to:
  /// **'Log 1000 non-alcoholic drinks.'**
  String get achievementFamilyNonAlcoholicLevel1000Description;

  /// No description provided for @achievementFamilyHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Harmony'**
  String get achievementFamilyHomeTitle;

  /// No description provided for @achievementFamilyHomeLevel1Title.
  ///
  /// In en, this message translates to:
  /// **'Home Hello'**
  String get achievementFamilyHomeLevel1Title;

  /// No description provided for @achievementFamilyHomeLevel1Description.
  ///
  /// In en, this message translates to:
  /// **'Log a drink at home.'**
  String get achievementFamilyHomeLevel1Description;

  /// No description provided for @achievementFamilyHomeLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Stay Starter'**
  String get achievementFamilyHomeLevel10Title;

  /// No description provided for @achievementFamilyHomeLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 drinks at home.'**
  String get achievementFamilyHomeLevel10Description;

  /// No description provided for @achievementFamilyHomeLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Couch Companion'**
  String get achievementFamilyHomeLevel25Title;

  /// No description provided for @achievementFamilyHomeLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 drinks at home.'**
  String get achievementFamilyHomeLevel25Description;

  /// No description provided for @achievementFamilyHomeLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Home Hero'**
  String get achievementFamilyHomeLevel50Title;

  /// No description provided for @achievementFamilyHomeLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 drinks at home.'**
  String get achievementFamilyHomeLevel50Description;

  /// No description provided for @achievementFamilyHomeLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Stay Sovereign'**
  String get achievementFamilyHomeLevel100Title;

  /// No description provided for @achievementFamilyHomeLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 drinks at home.'**
  String get achievementFamilyHomeLevel100Description;

  /// No description provided for @achievementFamilyWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Office Odyssey'**
  String get achievementFamilyWorkTitle;

  /// No description provided for @achievementFamilyWorkLevel1Title.
  ///
  /// In en, this message translates to:
  /// **'Work Welcome'**
  String get achievementFamilyWorkLevel1Title;

  /// No description provided for @achievementFamilyWorkLevel1Description.
  ///
  /// In en, this message translates to:
  /// **'Log a drink at work.'**
  String get achievementFamilyWorkLevel1Description;

  /// No description provided for @achievementFamilyWorkLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Office Operative'**
  String get achievementFamilyWorkLevel10Title;

  /// No description provided for @achievementFamilyWorkLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log 10 drinks at work.'**
  String get achievementFamilyWorkLevel10Description;

  /// No description provided for @achievementFamilyWorkLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Office Officer'**
  String get achievementFamilyWorkLevel25Title;

  /// No description provided for @achievementFamilyWorkLevel25Description.
  ///
  /// In en, this message translates to:
  /// **'Log 25 drinks at work.'**
  String get achievementFamilyWorkLevel25Description;

  /// No description provided for @achievementFamilyWorkLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Work Warrior'**
  String get achievementFamilyWorkLevel50Title;

  /// No description provided for @achievementFamilyWorkLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log 50 drinks at work.'**
  String get achievementFamilyWorkLevel50Description;

  /// No description provided for @achievementFamilyWorkLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Office Icon'**
  String get achievementFamilyWorkLevel100Title;

  /// No description provided for @achievementFamilyWorkLevel100Description.
  ///
  /// In en, this message translates to:
  /// **'Log 100 drinks at work.'**
  String get achievementFamilyWorkLevel100Description;

  /// No description provided for @achievementFamilyTravelCountriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport Pursuit'**
  String get achievementFamilyTravelCountriesTitle;

  /// No description provided for @achievementFamilyTravelCountriesLevel3Title.
  ///
  /// In en, this message translates to:
  /// **'Passport Pioneer'**
  String get achievementFamilyTravelCountriesLevel3Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel3Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 3 countries.'**
  String get achievementFamilyTravelCountriesLevel3Description;

  /// No description provided for @achievementFamilyTravelCountriesLevel5Title.
  ///
  /// In en, this message translates to:
  /// **'Border Buddy'**
  String get achievementFamilyTravelCountriesLevel5Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel5Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 5 countries.'**
  String get achievementFamilyTravelCountriesLevel5Description;

  /// No description provided for @achievementFamilyTravelCountriesLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Country Cruiser'**
  String get achievementFamilyTravelCountriesLevel10Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel10Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 10 countries.'**
  String get achievementFamilyTravelCountriesLevel10Description;

  /// No description provided for @achievementFamilyTravelCountriesLevel15Title.
  ///
  /// In en, this message translates to:
  /// **'Map Maverick'**
  String get achievementFamilyTravelCountriesLevel15Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel15Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 15 countries.'**
  String get achievementFamilyTravelCountriesLevel15Description;

  /// No description provided for @achievementFamilyTravelCountriesLevel20Title.
  ///
  /// In en, this message translates to:
  /// **'Trailblazer'**
  String get achievementFamilyTravelCountriesLevel20Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel20Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 20 countries.'**
  String get achievementFamilyTravelCountriesLevel20Description;

  /// No description provided for @achievementFamilyTravelCountriesLevel30Title.
  ///
  /// In en, this message translates to:
  /// **'Global Galloper'**
  String get achievementFamilyTravelCountriesLevel30Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel30Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 30 countries.'**
  String get achievementFamilyTravelCountriesLevel30Description;

  /// No description provided for @achievementFamilyTravelCountriesLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'World Whirl'**
  String get achievementFamilyTravelCountriesLevel50Title;

  /// No description provided for @achievementFamilyTravelCountriesLevel50Description.
  ///
  /// In en, this message translates to:
  /// **'Log drinks in 50 countries.'**
  String get achievementFamilyTravelCountriesLevel50Description;

  /// No description provided for @achievementOccasionBirthdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthday Bash'**
  String get achievementOccasionBirthdayTitle;

  /// No description provided for @achievementOccasionBirthdayDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink on your birthday.'**
  String get achievementOccasionBirthdayDescription;

  /// No description provided for @achievementOccasionFirstSipAnniversaryTitle.
  ///
  /// In en, this message translates to:
  /// **'First Sip Anniversary'**
  String get achievementOccasionFirstSipAnniversaryTitle;

  /// No description provided for @achievementOccasionFirstSipAnniversaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink on the anniversary of your first known drink.'**
  String get achievementOccasionFirstSipAnniversaryDescription;

  /// No description provided for @achievementOccasionNewYearTitle.
  ///
  /// In en, this message translates to:
  /// **'New Year, New Cheers'**
  String get achievementOccasionNewYearTitle;

  /// No description provided for @achievementOccasionNewYearDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink on New Year\'s Eve or New Year\'s Day.'**
  String get achievementOccasionNewYearDescription;

  /// No description provided for @achievementOccasionChristmasTitle.
  ///
  /// In en, this message translates to:
  /// **'Christmas Clink'**
  String get achievementOccasionChristmasTitle;

  /// No description provided for @achievementOccasionChristmasDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink between December 24 and 26.'**
  String get achievementOccasionChristmasDescription;

  /// No description provided for @achievementOccasionEasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Easter Cheers'**
  String get achievementOccasionEasterTitle;

  /// No description provided for @achievementOccasionEasterDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink between Good Friday and Easter Monday.'**
  String get achievementOccasionEasterDescription;

  /// No description provided for @achievementOccasionHalloweenTitle.
  ///
  /// In en, this message translates to:
  /// **'Spooky Sip'**
  String get achievementOccasionHalloweenTitle;

  /// No description provided for @achievementOccasionHalloweenDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink on Halloween.'**
  String get achievementOccasionHalloweenDescription;

  /// No description provided for @achievementOccasionStPatricksDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Lucky Lager'**
  String get achievementOccasionStPatricksDayTitle;

  /// No description provided for @achievementOccasionStPatricksDayDescription.
  ///
  /// In en, this message translates to:
  /// **'Log a beer on March 17.'**
  String get achievementOccasionStPatricksDayDescription;

  /// No description provided for @achievementOccasionOktoberfestTitle.
  ///
  /// In en, this message translates to:
  /// **'Festbier Fever'**
  String get achievementOccasionOktoberfestTitle;

  /// No description provided for @achievementOccasionOktoberfestDescription.
  ///
  /// In en, this message translates to:
  /// **'Log a beer during Oktoberfest.'**
  String get achievementOccasionOktoberfestDescription;

  /// No description provided for @achievementOccasionCarnivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Confetti Cheers'**
  String get achievementOccasionCarnivalTitle;

  /// No description provided for @achievementOccasionCarnivalDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink during Carnival.'**
  String get achievementOccasionCarnivalDescription;

  /// No description provided for @achievementCountryDeTitle.
  ///
  /// In en, this message translates to:
  /// **'Beergarten Bound'**
  String get achievementCountryDeTitle;

  /// No description provided for @achievementCountryDeLabel.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get achievementCountryDeLabel;

  /// No description provided for @achievementCountryDeDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Germany.'**
  String get achievementCountryDeDescription;

  /// No description provided for @achievementCountryNlTitle.
  ///
  /// In en, this message translates to:
  /// **'Canal Clink'**
  String get achievementCountryNlTitle;

  /// No description provided for @achievementCountryNlLabel.
  ///
  /// In en, this message translates to:
  /// **'Netherlands'**
  String get achievementCountryNlLabel;

  /// No description provided for @achievementCountryNlDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in the Netherlands.'**
  String get achievementCountryNlDescription;

  /// No description provided for @achievementCountryBeTitle.
  ///
  /// In en, this message translates to:
  /// **'Belgian Buzz'**
  String get achievementCountryBeTitle;

  /// No description provided for @achievementCountryBeLabel.
  ///
  /// In en, this message translates to:
  /// **'Belgium'**
  String get achievementCountryBeLabel;

  /// No description provided for @achievementCountryBeDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Belgium.'**
  String get achievementCountryBeDescription;

  /// No description provided for @achievementCountryLuTitle.
  ///
  /// In en, this message translates to:
  /// **'Grand Duchy Glow'**
  String get achievementCountryLuTitle;

  /// No description provided for @achievementCountryLuLabel.
  ///
  /// In en, this message translates to:
  /// **'Luxembourg'**
  String get achievementCountryLuLabel;

  /// No description provided for @achievementCountryLuDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Luxembourg.'**
  String get achievementCountryLuDescription;

  /// No description provided for @achievementCountryFrTitle.
  ///
  /// In en, this message translates to:
  /// **'French Fizz'**
  String get achievementCountryFrTitle;

  /// No description provided for @achievementCountryFrLabel.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get achievementCountryFrLabel;

  /// No description provided for @achievementCountryFrDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in France.'**
  String get achievementCountryFrDescription;

  /// No description provided for @achievementCountryEsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fiesta Flow'**
  String get achievementCountryEsTitle;

  /// No description provided for @achievementCountryEsLabel.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get achievementCountryEsLabel;

  /// No description provided for @achievementCountryEsDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Spain.'**
  String get achievementCountryEsDescription;

  /// No description provided for @achievementCountryPtTitle.
  ///
  /// In en, this message translates to:
  /// **'Portuguese Pour'**
  String get achievementCountryPtTitle;

  /// No description provided for @achievementCountryPtLabel.
  ///
  /// In en, this message translates to:
  /// **'Portugal'**
  String get achievementCountryPtLabel;

  /// No description provided for @achievementCountryPtDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Portugal.'**
  String get achievementCountryPtDescription;

  /// No description provided for @achievementCountryItTitle.
  ///
  /// In en, this message translates to:
  /// **'Aperitivo Arrival'**
  String get achievementCountryItTitle;

  /// No description provided for @achievementCountryItLabel.
  ///
  /// In en, this message translates to:
  /// **'Italy'**
  String get achievementCountryItLabel;

  /// No description provided for @achievementCountryItDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Italy.'**
  String get achievementCountryItDescription;

  /// No description provided for @achievementCountryAtTitle.
  ///
  /// In en, this message translates to:
  /// **'Alpine Cheers'**
  String get achievementCountryAtTitle;

  /// No description provided for @achievementCountryAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get achievementCountryAtLabel;

  /// No description provided for @achievementCountryAtDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Austria.'**
  String get achievementCountryAtDescription;

  /// No description provided for @achievementCountryChTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Pour'**
  String get achievementCountryChTitle;

  /// No description provided for @achievementCountryChLabel.
  ///
  /// In en, this message translates to:
  /// **'Switzerland'**
  String get achievementCountryChLabel;

  /// No description provided for @achievementCountryChDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Switzerland.'**
  String get achievementCountryChDescription;

  /// No description provided for @achievementCountryPlTitle.
  ///
  /// In en, this message translates to:
  /// **'Polish Pour'**
  String get achievementCountryPlTitle;

  /// No description provided for @achievementCountryPlLabel.
  ///
  /// In en, this message translates to:
  /// **'Poland'**
  String get achievementCountryPlLabel;

  /// No description provided for @achievementCountryPlDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Poland.'**
  String get achievementCountryPlDescription;

  /// No description provided for @achievementCountryCzTitle.
  ///
  /// In en, this message translates to:
  /// **'Czech Cheers'**
  String get achievementCountryCzTitle;

  /// No description provided for @achievementCountryCzLabel.
  ///
  /// In en, this message translates to:
  /// **'Czech Republic'**
  String get achievementCountryCzLabel;

  /// No description provided for @achievementCountryCzDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in the Czech Republic.'**
  String get achievementCountryCzDescription;

  /// No description provided for @achievementCountryIeTitle.
  ///
  /// In en, this message translates to:
  /// **'Emerald Cheers'**
  String get achievementCountryIeTitle;

  /// No description provided for @achievementCountryIeLabel.
  ///
  /// In en, this message translates to:
  /// **'Ireland'**
  String get achievementCountryIeLabel;

  /// No description provided for @achievementCountryIeDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Ireland.'**
  String get achievementCountryIeDescription;

  /// No description provided for @achievementCountryGbTitle.
  ///
  /// In en, this message translates to:
  /// **'Kingdom Clink'**
  String get achievementCountryGbTitle;

  /// No description provided for @achievementCountryGbLabel.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get achievementCountryGbLabel;

  /// No description provided for @achievementCountryGbDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in the United Kingdom.'**
  String get achievementCountryGbDescription;

  /// No description provided for @achievementCountryDkTitle.
  ///
  /// In en, this message translates to:
  /// **'Danish Draft'**
  String get achievementCountryDkTitle;

  /// No description provided for @achievementCountryDkLabel.
  ///
  /// In en, this message translates to:
  /// **'Denmark'**
  String get achievementCountryDkLabel;

  /// No description provided for @achievementCountryDkDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Denmark.'**
  String get achievementCountryDkDescription;

  /// No description provided for @achievementCountrySeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scandi Spark'**
  String get achievementCountrySeTitle;

  /// No description provided for @achievementCountrySeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sweden'**
  String get achievementCountrySeLabel;

  /// No description provided for @achievementCountrySeDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Sweden.'**
  String get achievementCountrySeDescription;

  /// No description provided for @achievementCountryNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Fjord Flow'**
  String get achievementCountryNoTitle;

  /// No description provided for @achievementCountryNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Norway'**
  String get achievementCountryNoLabel;

  /// No description provided for @achievementCountryNoDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Norway.'**
  String get achievementCountryNoDescription;

  /// No description provided for @achievementCountryFiTitle.
  ///
  /// In en, this message translates to:
  /// **'Sauna Sip'**
  String get achievementCountryFiTitle;

  /// No description provided for @achievementCountryFiLabel.
  ///
  /// In en, this message translates to:
  /// **'Finland'**
  String get achievementCountryFiLabel;

  /// No description provided for @achievementCountryFiDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Finland.'**
  String get achievementCountryFiDescription;

  /// No description provided for @achievementCountryGrTitle.
  ///
  /// In en, this message translates to:
  /// **'Aegean Cheers'**
  String get achievementCountryGrTitle;

  /// No description provided for @achievementCountryGrLabel.
  ///
  /// In en, this message translates to:
  /// **'Greece'**
  String get achievementCountryGrLabel;

  /// No description provided for @achievementCountryGrDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Greece.'**
  String get achievementCountryGrDescription;

  /// No description provided for @achievementCountryHrTitle.
  ///
  /// In en, this message translates to:
  /// **'Adriatic Uplift'**
  String get achievementCountryHrTitle;

  /// No description provided for @achievementCountryHrLabel.
  ///
  /// In en, this message translates to:
  /// **'Croatia'**
  String get achievementCountryHrLabel;

  /// No description provided for @achievementCountryHrDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Croatia.'**
  String get achievementCountryHrDescription;

  /// No description provided for @achievementCountryHuTitle.
  ///
  /// In en, this message translates to:
  /// **'Danube Draft'**
  String get achievementCountryHuTitle;

  /// No description provided for @achievementCountryHuLabel.
  ///
  /// In en, this message translates to:
  /// **'Hungary'**
  String get achievementCountryHuLabel;

  /// No description provided for @achievementCountryHuDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Hungary.'**
  String get achievementCountryHuDescription;

  /// No description provided for @achievementCountryRoTitle.
  ///
  /// In en, this message translates to:
  /// **'Carpathian Clink'**
  String get achievementCountryRoTitle;

  /// No description provided for @achievementCountryRoLabel.
  ///
  /// In en, this message translates to:
  /// **'Romania'**
  String get achievementCountryRoLabel;

  /// No description provided for @achievementCountryRoDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Romania.'**
  String get achievementCountryRoDescription;

  /// No description provided for @achievementCountryTrTitle.
  ///
  /// In en, this message translates to:
  /// **'Bosphorus Buzz'**
  String get achievementCountryTrTitle;

  /// No description provided for @achievementCountryTrLabel.
  ///
  /// In en, this message translates to:
  /// **'Turkey'**
  String get achievementCountryTrLabel;

  /// No description provided for @achievementCountryTrDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Turkey.'**
  String get achievementCountryTrDescription;

  /// No description provided for @achievementCountryUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stars & Sips'**
  String get achievementCountryUsTitle;

  /// No description provided for @achievementCountryUsLabel.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get achievementCountryUsLabel;

  /// No description provided for @achievementCountryUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in the United States.'**
  String get achievementCountryUsDescription;

  /// No description provided for @achievementCountryJpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sakura Sip'**
  String get achievementCountryJpTitle;

  /// No description provided for @achievementCountryJpLabel.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get achievementCountryJpLabel;

  /// No description provided for @achievementCountryJpDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Japan.'**
  String get achievementCountryJpDescription;

  /// No description provided for @achievementCountrySiTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragon Draft'**
  String get achievementCountrySiTitle;

  /// No description provided for @achievementCountrySiLabel.
  ///
  /// In en, this message translates to:
  /// **'Slovenia'**
  String get achievementCountrySiLabel;

  /// No description provided for @achievementCountrySiDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Slovenia.'**
  String get achievementCountrySiDescription;

  /// No description provided for @achievementCountryMcTitle.
  ///
  /// In en, this message translates to:
  /// **'Monaco Mood'**
  String get achievementCountryMcTitle;

  /// No description provided for @achievementCountryMcLabel.
  ///
  /// In en, this message translates to:
  /// **'Monaco'**
  String get achievementCountryMcLabel;

  /// No description provided for @achievementCountryMcDescription.
  ///
  /// In en, this message translates to:
  /// **'Log any drink in Monaco.'**
  String get achievementCountryMcDescription;

  /// No description provided for @achievementsTab.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTab;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementsBadgesEarned.
  ///
  /// In en, this message translates to:
  /// **'Badges earned'**
  String get achievementsBadgesEarned;

  /// No description provided for @achievementsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get achievementsFilterAll;

  /// No description provided for @achievementsFilterUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementsFilterUnlocked;

  /// No description provided for @achievementsFilterLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementsFilterLocked;

  /// No description provided for @achievementsRecentlyUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Recently unlocked'**
  String get achievementsRecentlyUnlocked;

  /// No description provided for @achievementsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get achievementsViewAll;

  /// No description provided for @achievementsSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Setup required'**
  String get achievementsSetupRequired;

  /// No description provided for @achievementsSetUpNow.
  ///
  /// In en, this message translates to:
  /// **'Set up now'**
  String get achievementsSetUpNow;

  /// No description provided for @achievementsEarnableToday.
  ///
  /// In en, this message translates to:
  /// **'Earnable today'**
  String get achievementsEarnableToday;

  /// No description provided for @achievementsNextEligible.
  ///
  /// In en, this message translates to:
  /// **'Next eligible'**
  String get achievementsNextEligible;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementsUnlocked;

  /// No description provided for @achievementsLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementsLocked;

  /// No description provided for @achievementsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get achievementsCompleted;

  /// No description provided for @achievementsSummaryBackfillTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements unlocked'**
  String get achievementsSummaryBackfillTitle;

  /// No description provided for @shareAchievements.
  ///
  /// In en, this message translates to:
  /// **'Share achievements with friends'**
  String get shareAchievements;

  /// No description provided for @shareAchievementsBody.
  ///
  /// In en, this message translates to:
  /// **'Accepted friends can see your earned badges inside the app.'**
  String get shareAchievementsBody;

  /// No description provided for @achievementReminders.
  ///
  /// In en, this message translates to:
  /// **'Achievement reminders'**
  String get achievementReminders;

  /// No description provided for @achievementRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'Get push reminders for annual and occasion-based badges.'**
  String get achievementRemindersBody;

  /// No description provided for @savedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get savedPlacesTitle;

  /// No description provided for @savedPlacesHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get savedPlacesHome;

  /// No description provided for @savedPlacesWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get savedPlacesWork;

  /// No description provided for @savedPlacesArchived.
  ///
  /// In en, this message translates to:
  /// **'Previous places'**
  String get savedPlacesArchived;

  /// No description provided for @achievementsSummaryBackfillBody.
  ///
  /// In en, this message translates to:
  /// **'You unlocked {count} badges from your history.'**
  String achievementsSummaryBackfillBody(int count);

  /// No description provided for @achievementsOverflowUnlocked.
  ///
  /// In en, this message translates to:
  /// **'+{count} more unlocked'**
  String achievementsOverflowUnlocked(int count);

  /// No description provided for @achievementsCategoryTotals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get achievementsCategoryTotals;

  /// No description provided for @achievementsCategoryStreaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get achievementsCategoryStreaks;

  /// No description provided for @achievementsCategoryDrinkTypes.
  ///
  /// In en, this message translates to:
  /// **'Drink Types'**
  String get achievementsCategoryDrinkTypes;

  /// No description provided for @achievementsCategoryOccasions.
  ///
  /// In en, this message translates to:
  /// **'Occasions'**
  String get achievementsCategoryOccasions;

  /// No description provided for @achievementsCategoryPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get achievementsCategoryPlaces;

  /// No description provided for @achievementsCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get achievementsCategoryTravel;

  /// No description provided for @achievementsCategoryCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get achievementsCategoryCountries;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
