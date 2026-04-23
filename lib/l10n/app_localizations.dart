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

  /// No description provided for @feedBody.
  ///
  /// In en, this message translates to:
  /// **'This V1 shows your personal history. Friends, comments, and cheers arrive later.'**
  String get feedBody;

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
  /// **'Weekly'**
  String get weeklyTotal;

  /// No description provided for @monthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyTotal;

  /// No description provided for @yearlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
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
  /// **'Friends, social feed, and achievements are part of the plan but intentionally not shipped in V1.'**
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

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be updated.'**
  String get profileUpdateFailed;

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
