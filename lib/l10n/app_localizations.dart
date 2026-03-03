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
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GlassTrail'**
  String get appTitle;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStats;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Timeline'**
  String get feedTitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Log your first drink to start your feed.'**
  String get feedEmptyBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cheer.
  ///
  /// In en, this message translates to:
  /// **'Cheers'**
  String get cheer;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Badge unlocked'**
  String get badgeUnlocked;

  /// No description provided for @withFriends.
  ///
  /// In en, this message translates to:
  /// **'With friends'**
  String get withFriends;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Drink Map'**
  String get mapTitle;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get recenter;

  /// No description provided for @noMapSelection.
  ///
  /// In en, this message translates to:
  /// **'No marker selected'**
  String get noMapSelection;

  /// No description provided for @mapSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a marker to view details.'**
  String get mapSelectionHint;

  /// No description provided for @addDrinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Drink'**
  String get addDrinkTitle;

  /// No description provided for @stepDrink.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get stepDrink;

  /// No description provided for @stepMedia.
  ///
  /// In en, this message translates to:
  /// **'Photo & comment'**
  String get stepMedia;

  /// No description provided for @stepFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get stepFriends;

  /// No description provided for @stepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stepConfirm;

  /// No description provided for @searchDrinkHint.
  ///
  /// In en, this message translates to:
  /// **'Search drinks'**
  String get searchDrinkHint;

  /// No description provided for @recentDrinks.
  ///
  /// In en, this message translates to:
  /// **'Recent drinks'**
  String get recentDrinks;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Optional comment'**
  String get commentHint;

  /// No description provided for @pickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick photo'**
  String get pickPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @taggedFriends.
  ///
  /// In en, this message translates to:
  /// **'Tag friends'**
  String get taggedFriends;

  /// No description provided for @submitDrink.
  ///
  /// In en, this message translates to:
  /// **'Log drink'**
  String get submitDrink;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @requiredDrinkError.
  ///
  /// In en, this message translates to:
  /// **'Please choose a drink.'**
  String get requiredDrinkError;

  /// No description provided for @drinkSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Drink logged.'**
  String get drinkSavedSnack;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverview;

  /// No description provided for @statsMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get statsMap;

  /// No description provided for @statsList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get statsList;

  /// No description provided for @dailyTotal.
  ///
  /// In en, this message translates to:
  /// **'Daily total'**
  String get dailyTotal;

  /// No description provided for @weeklyTotal.
  ///
  /// In en, this message translates to:
  /// **'Weekly total'**
  String get weeklyTotal;

  /// No description provided for @monthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get monthlyTotal;

  /// No description provided for @categoryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category distribution'**
  String get categoryDistribution;

  /// No description provided for @trend7Days.
  ///
  /// In en, this message translates to:
  /// **'7-day trend'**
  String get trend7Days;

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

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history available.'**
  String get noHistory;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @pendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Pending request'**
  String get pendingRequest;

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

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import BeeerWithMe data'**
  String get importData;

  /// No description provided for @pickJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Pick JSON file'**
  String get pickJsonFile;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Import preview'**
  String get importPreview;

  /// No description provided for @importNow.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importNow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @validationErrors.
  ///
  /// In en, this message translates to:
  /// **'Validation errors'**
  String get validationErrors;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed.'**
  String get importSuccess;

  /// No description provided for @notificationPrefs.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPrefs;

  /// No description provided for @friendDrinkNotifications.
  ///
  /// In en, this message translates to:
  /// **'Friend drink notifications'**
  String get friendDrinkNotifications;

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

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langGerman;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GlassTrail'**
  String get onboardingTitle;

  /// No description provided for @onboardingAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get onboardingAccount;

  /// No description provided for @onboardingProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile setup'**
  String get onboardingProfile;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready'**
  String get onboardingDone;

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

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @chooseDateRange.
  ///
  /// In en, this message translates to:
  /// **'Choose date range'**
  String get chooseDateRange;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @totals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totals;

  /// No description provided for @streakProgress.
  ///
  /// In en, this message translates to:
  /// **'Streak progress'**
  String get streakProgress;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Import summary'**
  String get importSummary;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @validEntries.
  ///
  /// In en, this message translates to:
  /// **'Valid entries'**
  String get validEntries;

  /// No description provided for @legacyType.
  ///
  /// In en, this message translates to:
  /// **'Legacy type'**
  String get legacyType;

  /// No description provided for @mappedTo.
  ///
  /// In en, this message translates to:
  /// **'Mapped to'**
  String get mappedTo;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get addCommentHint;

  /// No description provided for @postComment.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postComment;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;
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
      'that was used.');
}
