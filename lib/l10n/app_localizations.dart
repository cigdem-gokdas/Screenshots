import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Unuttuğum Screenshotlar'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Daily review'**
  String get review;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @homeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A LITTLE LESS FORGOTTEN'**
  String get homeEyebrow;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Save a little.\nLive a little more.'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Good finds deserve more than a screenshot.'**
  String get homeSubtitle;

  /// No description provided for @yourCollections.
  ///
  /// In en, this message translates to:
  /// **'Your collections'**
  String get yourCollections;

  /// No description provided for @allEntries.
  ///
  /// In en, this message translates to:
  /// **'All entries'**
  String get allEntries;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get addEntry;

  /// No description provided for @watchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlist;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading list'**
  String get reading;

  /// No description provided for @gaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get gaming;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places to visit'**
  String get places;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @ideas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get ideas;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @watchHint.
  ///
  /// In en, this message translates to:
  /// **'For your next quiet night'**
  String get watchHint;

  /// No description provided for @recipesHint.
  ///
  /// In en, this message translates to:
  /// **'Something worth making'**
  String get recipesHint;

  /// No description provided for @readingHint.
  ///
  /// In en, this message translates to:
  /// **'Your next chapter'**
  String get readingHint;

  /// No description provided for @gamingHint.
  ///
  /// In en, this message translates to:
  /// **'A new world awaits'**
  String get gamingHint;

  /// No description provided for @placesHint.
  ///
  /// In en, this message translates to:
  /// **'A little further afield'**
  String get placesHint;

  /// No description provided for @wishlistHint.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful little wants'**
  String get wishlistHint;

  /// No description provided for @ideasHint.
  ///
  /// In en, this message translates to:
  /// **'Make room for a spark'**
  String get ideasHint;

  /// No description provided for @otherHint.
  ///
  /// In en, this message translates to:
  /// **'A place for everything else'**
  String get otherHint;

  /// No description provided for @reviewTeaser.
  ///
  /// In en, this message translates to:
  /// **'From saved to someday soon'**
  String get reviewTeaser;

  /// No description provided for @reviewTeaserBody.
  ///
  /// In en, this message translates to:
  /// **'A small look at what caught your eye.'**
  String get reviewTeaserBody;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries yet} =1{1 entry} other{{count} entries}}'**
  String itemCount(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your finds'**
  String get searchHint;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @todo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get todo;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'A little space for possibility'**
  String get noEntries;

  /// No description provided for @noEntriesBody.
  ///
  /// In en, this message translates to:
  /// **'Add something you want to watch, try, read or explore.'**
  String get noEntriesBody;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get noResults;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try another search or clear your filters.'**
  String get noResultsBody;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'A good find'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @editorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give that someday a place to start.'**
  String get editorSubtitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'What caught your eye?'**
  String get titleHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get categoryLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'A detail you want to remember…'**
  String get descriptionHint;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'Link (optional)'**
  String get urlLabel;

  /// No description provided for @urlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get urlHint;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @titleError.
  ///
  /// In en, this message translates to:
  /// **'Enter a title between 1 and 120 characters.'**
  String get titleError;

  /// No description provided for @descriptionError.
  ///
  /// In en, this message translates to:
  /// **'Keep notes under 5,000 characters.'**
  String get descriptionError;

  /// No description provided for @urlError.
  ///
  /// In en, this message translates to:
  /// **'Enter a public https link without login details.'**
  String get urlError;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your changes are still here. Try again.'**
  String get saveError;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Your find'**
  String get details;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get delete;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Let this one go?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'This entry will be permanently deleted from this device.'**
  String get deleteBody;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// No description provided for @actionError.
  ///
  /// In en, this message translates to:
  /// **'That didn’t work. Please try again.'**
  String get actionError;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @linkError.
  ///
  /// In en, this message translates to:
  /// **'This link could not be opened.'**
  String get linkError;

  /// No description provided for @savedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String savedOn(String date);

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOn(String date);

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'A note to remember'**
  String get notes;

  /// No description provided for @entryGone.
  ///
  /// In en, this message translates to:
  /// **'This entry is no longer available.'**
  String get entryGone;

  /// No description provided for @reviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A MOMENT TO RECONNECT'**
  String get reviewEyebrow;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Make room\nfor a little doing.'**
  String get reviewTitle;

  /// No description provided for @reviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your collections, with a little perspective.'**
  String get reviewSubtitle;

  /// No description provided for @savedToday.
  ///
  /// In en, this message translates to:
  /// **'Saved today'**
  String get savedToday;

  /// No description provided for @uncompleted.
  ///
  /// In en, this message translates to:
  /// **'Still to do'**
  String get uncompleted;

  /// No description provided for @completedItems.
  ///
  /// In en, this message translates to:
  /// **'Completed entries'**
  String get completedItems;

  /// No description provided for @distribution.
  ///
  /// In en, this message translates to:
  /// **'Where curiosity takes you'**
  String get distribution;

  /// No description provided for @revisit.
  ///
  /// In en, this message translates to:
  /// **'Worth another look'**
  String get revisit;

  /// No description provided for @revisitHint.
  ///
  /// In en, this message translates to:
  /// **'Unfinished finds untouched for at least 7 days.'**
  String get revisitHint;

  /// No description provided for @noRevisit.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up for now.'**
  String get noRevisit;

  /// No description provided for @suggestionLabel.
  ///
  /// In en, this message translates to:
  /// **'ONE SMALL SUGGESTION'**
  String get suggestionLabel;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Start with “{title}” in {category}. One good find is enough for today.'**
  String suggestion(String title, String category);

  /// No description provided for @emptySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Your next good find starts here. Save something you’re curious about.'**
  String get emptySuggestion;

  /// No description provided for @doneSuggestion.
  ///
  /// In en, this message translates to:
  /// **'You’ve completed {count} entries. Make a little room for your next discovery.'**
  String doneSuggestion(int count);

  /// No description provided for @archivedSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Your finds are in the archive. Reopen an entry whenever you feel curious.'**
  String get archivedSuggestion;

  /// No description provided for @viewEntry.
  ///
  /// In en, this message translates to:
  /// **'Take a look'**
  String get viewEntry;

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your story starts with a find'**
  String get reviewEmpty;

  /// No description provided for @reviewEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your real activity will appear here as you add entries.'**
  String get reviewEmptyBody;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what feels like home.'**
  String get languageSubtitle;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get systemLanguage;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Just you and your finds'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshot analysis uses Apple Vision and local rules on this device. Images and OCR text are not sent to a server. Optional account sign-in shares identity information with Firebase and your chosen provider; Pro billing shares purchase information with RevenueCat and the store.'**
  String get privacyBody;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get storageTitle;

  /// No description provided for @storageBody.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling or clearing app storage can remove entries. On iOS, the app requests backup exclusion for its local database and imported copies. Backups made earlier are not changed.'**
  String get storageBody;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Your collection couldn’t be loaded.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Automatic Screenshot Sync'**
  String get autoSync;

  /// No description provided for @syncIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots.\nA little more organized.'**
  String get syncIntroTitle;

  /// No description provided for @syncIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic sync once. New screenshots become entries without selecting, confirming or categorizing them. You can still edit anything later.'**
  String get syncIntroBody;

  /// No description provided for @syncAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You choose photo access'**
  String get syncAccessTitle;

  /// No description provided for @syncAccessBody.
  ///
  /// In en, this message translates to:
  /// **'iOS may grant access to your full photo library, or only selected photos. Access is not scoped to Screenshots by the operating system. This app checks screenshot types and processes screenshots only. Limited access can miss screenshots. You can change or revoke access later in iOS Settings.'**
  String get syncAccessBody;

  /// No description provided for @syncLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Organized on this device'**
  String get syncLocalTitle;

  /// No description provided for @syncLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshots and recognized text stay in app-local storage. Likely passwords, banking details and recovery codes are skipped after a minimal local check. Detection and categorization can make mistakes. Text recognition uses Apple Vision and local classification rules, not cloud AI.'**
  String get syncLocalBody;

  /// No description provided for @syncForegroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Catches up when you return'**
  String get syncForegroundTitle;

  /// No description provided for @syncForegroundBody.
  ///
  /// In en, this message translates to:
  /// **'Sync runs while the app is active and catches up when you open it again. iOS can suspend or terminate the app; continuous background monitoring is not available. iCloud-only screenshots wait until available on this device.'**
  String get syncForegroundBody;

  /// No description provided for @syncEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic sync'**
  String get syncEnable;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @newOnly.
  ///
  /// In en, this message translates to:
  /// **'Your archive first, then new screenshots'**
  String get newOnly;

  /// No description provided for @newOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Available screenshots are discovered after you grant access. New screenshots are then added while the app is active. Duplicate content is not saved again.'**
  String get newOnlyBody;

  /// No description provided for @importExisting.
  ///
  /// In en, this message translates to:
  /// **'Import Existing Screenshots'**
  String get importExisting;

  /// No description provided for @importExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Include older screenshots?'**
  String get importExistingTitle;

  /// No description provided for @importExistingBody.
  ///
  /// In en, this message translates to:
  /// **'Automatically organize accessible screenshots captured before sync was enabled. Sensitive screenshots are still skipped. Your original Photos library will not be changed.'**
  String get importExistingBody;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Successful Sync'**
  String get lastSync;

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get neverSynced;

  /// No description provided for @photoPermission.
  ///
  /// In en, this message translates to:
  /// **'Photo access'**
  String get photoPermission;

  /// No description provided for @accessNotDetermined.
  ///
  /// In en, this message translates to:
  /// **'Not requested'**
  String get accessNotDetermined;

  /// No description provided for @accessAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get accessAuthorized;

  /// No description provided for @accessLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited Access'**
  String get accessLimited;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Not Allowed'**
  String get accessDenied;

  /// No description provided for @accessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Access restricted by device controls'**
  String get accessRestricted;

  /// No description provided for @syncOff.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync is off'**
  String get syncOff;

  /// No description provided for @syncChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking photo access…'**
  String get syncChecking;

  /// No description provided for @syncScanning.
  ///
  /// In en, this message translates to:
  /// **'Finding screenshots…'**
  String get syncScanning;

  /// No description provided for @syncProcessing.
  ///
  /// In en, this message translates to:
  /// **'Organizing on this device…'**
  String get syncProcessing;

  /// No description provided for @syncIdle.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncIdle;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'Some screenshots are waiting — cloud assets retry when locally available'**
  String get syncWaiting;

  /// No description provided for @syncPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused while the app is inactive'**
  String get syncPaused;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync could not finish. Your entries are still here.'**
  String get syncError;

  /// No description provided for @syncIOSOnly.
  ///
  /// In en, this message translates to:
  /// **'Automatic library sync is available on iOS. Use selected imports and manual organization on Android.'**
  String get syncIOSOnly;

  /// No description provided for @openPhotoSettings.
  ///
  /// In en, this message translates to:
  /// **'Open iOS Settings'**
  String get openPhotoSettings;

  /// No description provided for @deleteImported.
  ///
  /// In en, this message translates to:
  /// **'Delete Imported Screenshot Data'**
  String get deleteImported;

  /// No description provided for @deleteImportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete imported data from this app?'**
  String get deleteImportedTitle;

  /// No description provided for @deleteImportedBody.
  ///
  /// In en, this message translates to:
  /// **'Turns sync off and deletes imported entries, local image copies, extracted text and import history. Manual entries and original screenshots in Photos stay unchanged. Re-enabling starts with new screenshots only.'**
  String get deleteImportedBody;

  /// No description provided for @screenshotFallback.
  ///
  /// In en, this message translates to:
  /// **'Screenshot · {date}'**
  String screenshotFallback(String date);

  /// No description provided for @importedScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Imported screenshot'**
  String get importedScreenshot;

  /// No description provided for @capturedOn.
  ///
  /// In en, this message translates to:
  /// **'Captured {date}'**
  String capturedOn(String date);

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The local screenshot copy is unavailable.'**
  String get imageUnavailable;

  /// No description provided for @syncHistoryPending.
  ///
  /// In en, this message translates to:
  /// **'Existing screenshots will be included when access is available.'**
  String get syncHistoryPending;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @readPublishedPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read the published document'**
  String get readPublishedPolicy;

  /// No description provided for @legalDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'This summary is a draft. The developer must publish and approve the complete legal documents before subscriptions are available.'**
  String get legalDraftNotice;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Your selected screenshots, extracted text and collections are processed on this device and stored in app-private storage. No screenshot or OCR content is sent to a backend or AI provider. Automatic sync is optional and requires separate Photos access; you can change access in device Settings.\n\nOptional Pro subscriptions use Apple/Google and RevenueCat. After you choose to connect, a purchase identifier and purchase history are shared to validate subscriptions. SDK diagnostics and automatic attribution-identifier collection are disabled. RevenueCat provides purchase reporting for the developer. We add no advertising, tracking or app analytics SDK.\n\nDelete individual entries or use Delete Imported Screenshot Data in Settings to remove imported entries, copies and import history. Manual entries remain until you delete them. Original Photos are never deleted. Temporary processing copies are removed after each attempt or swept on the next launch after interruption. Purchase records are retained separately by the store and RevenueCat; deleting local screenshots does not cancel a subscription or erase records they must retain.\n\nUninstalling can remove local data. The app requests iOS file protection and backup exclusion for its database and imported copies; previous backups and filesystem snapshots may retain data. Sensitive-screen checks can miss content and deletion is not certified secure erasure. External saved links open only when you choose. No user account is required. If you choose Google or Apple sign-in, Firebase Authentication and the selected provider process your sign-in identity (UID, optional name/email or Apple relay email, credentials and connection metadata). We do not send screenshots or OCR text to them. SDKs manage session credentials; they are not saved in the app database. Firebase UID is used for RevenueCat identity after billing consent. Delete Account requires reauthentication, deletes the Firebase account and clears this device’s session while keeping its local collections. Store and RevenueCat purchase records are separate; subscriptions are not cancelled by account deletion. No screenshot cloud backup or cross-device collection sync exists.\n\nGoogle Sign-In and Firebase Auth may process diagnostics, device/user identifiers and usage information for their services. Their SDK privacy declarations include broader categories as well. The app does not request a phone-number or location permission; provider metadata is separate from screenshot content. No separate advertising or app-analytics service was added; we do not claim all provider operational measurements are disabled.'**
  String get privacyPolicyBody;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'Free features include selected imports, local organization, viewing, editing and deletion. On iOS, Apple Vision and local rules analyze screenshots without paid cloud AI. Android selected imports keep the image for manual organization; text recognition is currently iOS-only.\n\nAutomatic screenshot discovery is free on iOS while the app is active. Pro increases manual selection batches from 10 to 50 photos on iOS. It does not provide continuous background monitoring or unlimited cloud AI. Monthly and yearly subscriptions renew automatically unless cancelled through the store at least 24 hours before renewal. The store displays the exact local price and confirms each purchase. Payment is handled by the store. Manage or cancel in your store subscription settings; deleting this app or its content does not cancel billing.\n\nExisting saved data remains accessible if Pro expires or verification is temporarily unavailable. Recently verified subscription access may continue offline for up to 72 hours, never beyond its known expiry. A refund, revocation or expiry removes the larger Pro batch allowance after verification.\n\nClassification and sensitive-content checks may be wrong. Review and edit results when needed. This draft requires developer legal approval and complete publisher/contact details before release.'**
  String get termsBody;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'Unuttuğum Screenshotlar Pro'**
  String get proTitle;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proBadge;

  /// No description provided for @proHeadline.
  ///
  /// In en, this message translates to:
  /// **'Organize a bigger pile.'**
  String get proHeadline;

  /// No description provided for @proBenefits.
  ///
  /// In en, this message translates to:
  /// **'Import up to 50 photos in one selection. Analysis happens on your device. Automatic screenshot discovery and basic features are available to everyone.'**
  String get proBenefits;

  /// No description provided for @freeAlways.
  ///
  /// In en, this message translates to:
  /// **'Selected imports (10 photos), automatic discovery, viewing, editing, deleting, search and Daily Review remain free.'**
  String get freeAlways;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro is active'**
  String get proActive;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @upgradePro.
  ///
  /// In en, this message translates to:
  /// **'Explore Pro'**
  String get upgradePro;

  /// No description provided for @billingDisclosure.
  ///
  /// In en, this message translates to:
  /// **'To view plans or restore, connect to RevenueCat and your store. Purchase identifiers (linked to your Firebase UID if you sign in) and purchase history are used to verify subscriptions. Your screenshots and recognized text are not shared. No account is needed.'**
  String get billingDisclosure;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'Connect and view plans'**
  String get viewPlans;

  /// No description provided for @monthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String monthlyPrice(String price);

  /// No description provided for @yearlyPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} / year'**
  String yearlyPrice(String price);

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewing subscription. The store confirms price and payment. Cancel in store subscription settings at least 24 hours before renewal. Your saved data remains accessible after cancellation.'**
  String get subscriptionTerms;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pro is ready. Enjoy a little less organizing.'**
  String get purchaseSuccess;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your Pro subscription has been restored.'**
  String get restoreSuccess;

  /// No description provided for @restoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active Pro subscription was found for this store account.'**
  String get restoreEmpty;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled. You can continue using the free features.'**
  String get purchaseCancelled;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for store approval. Please do not purchase again; access updates after confirmation.'**
  String get purchasePending;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed. Check your connection and store account, then try again.'**
  String get purchaseFailed;

  /// No description provided for @billingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription options are unavailable right now. Your saved data and free features are still available.'**
  String get billingUnavailable;

  /// No description provided for @autoSyncPro.
  ///
  /// In en, this message translates to:
  /// **'Automatic library organization is a Pro feature. Existing entries stay available on every plan.'**
  String get autoSyncPro;

  /// No description provided for @importScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Import screenshots'**
  String get importScreenshots;

  /// No description provided for @pickerHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a few\ngood finds.'**
  String get pickerHeadline;

  /// No description provided for @pickerExplanation.
  ///
  /// In en, this message translates to:
  /// **'Select screenshots or photos with the system picker. The app receives only what you choose; full photo-library access is not required. On iOS, text is recognized and categorized on this device. Nothing is uploaded to an AI service. You can edit or delete every result.'**
  String get pickerExplanation;

  /// No description provided for @pickerLimits.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 photos per selection, or 50 with Pro. Images are resized on your device and original location metadata is discarded.'**
  String get pickerLimits;

  /// No description provided for @chooseScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Choose images'**
  String get chooseScreenshots;

  /// No description provided for @importWorking.
  ///
  /// In en, this message translates to:
  /// **'Organizing on this device… You can cancel safely.'**
  String get importWorking;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{imported} saved · {duplicates} already saved · {skipped} skipped for privacy · {failed} could not be processed.'**
  String importSummary(int imported, int duplicates, int skipped, int failed);

  /// No description provided for @photoAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Photo Access'**
  String get photoAccessSection;

  /// No description provided for @photoPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your screenshots?'**
  String get photoPromptTitle;

  /// No description provided for @photoPromptBody.
  ///
  /// In en, this message translates to:
  /// **'With full access we find and sort your screenshots automatically, or you can add only the ones you pick.'**
  String get photoPromptBody;

  /// No description provided for @localAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis happens on your device.'**
  String get localAnalysis;

  /// No description provided for @findScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Find My Screenshots'**
  String get findScreenshots;

  /// No description provided for @pickMyself.
  ///
  /// In en, this message translates to:
  /// **'I’ll Choose'**
  String get pickMyself;

  /// No description provided for @selectPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select Photos'**
  String get selectPhotos;

  /// No description provided for @manageAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage Access'**
  String get manageAccess;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @allowInSettings.
  ///
  /// In en, this message translates to:
  /// **'Allow in Settings'**
  String get allowInSettings;

  /// No description provided for @photoLimitedBody.
  ///
  /// In en, this message translates to:
  /// **'We can only see the photos you selected.'**
  String get photoLimitedBody;

  /// No description provided for @photoDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off. You can still choose screenshots yourself.'**
  String get photoDeniedBody;

  /// No description provided for @photoRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'Photo access is restricted on this device and cannot be changed from the app. You can still try selecting photos.'**
  String get photoRestrictedBody;

  /// No description provided for @photoFullBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are discovered while the app is active. Other photos are not analyzed.'**
  String get photoFullBody;

  /// No description provided for @onboardingSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved it.'**
  String get onboardingSaved;

  /// No description provided for @onboardingLost.
  ///
  /// In en, this message translates to:
  /// **'Then it disappeared.'**
  String get onboardingLost;

  /// No description provided for @onboardingRecognition.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots are really a to-do list.'**
  String get onboardingRecognition;

  /// No description provided for @onboardingResolution.
  ///
  /// In en, this message translates to:
  /// **'Saving isn’t enough.\nYou need to find it again.'**
  String get onboardingResolution;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingNext;

  /// No description provided for @organizeHell.
  ///
  /// In en, this message translates to:
  /// **'Organize the Chaos'**
  String get organizeHell;

  /// No description provided for @onboardingGuest.
  ///
  /// In en, this message translates to:
  /// **'Start without an account.'**
  String get onboardingGuest;

  /// No description provided for @semanticWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get semanticWatch;

  /// No description provided for @semanticRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get semanticRead;

  /// No description provided for @semanticGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get semanticGo;

  /// No description provided for @semanticEat.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get semanticEat;

  /// No description provided for @semanticDo.
  ///
  /// In en, this message translates to:
  /// **'Do'**
  String get semanticDo;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Yours, on this device.'**
  String get guestMode;

  /// No description provided for @accountConnected.
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get accountConnected;

  /// No description provided for @accountExplanation.
  ///
  /// In en, this message translates to:
  /// **'Signing in is optional. It keeps your subscription identity; screenshots are never uploaded.'**
  String get accountExplanation;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @linkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Link Google account'**
  String get linkGoogle;

  /// No description provided for @linkApple.
  ///
  /// In en, this message translates to:
  /// **'Link Apple account'**
  String get linkApple;

  /// No description provided for @linkAccountExplanation.
  ///
  /// In en, this message translates to:
  /// **'Linking another provider first verifies your current account. Matching email addresses never merge accounts automatically.'**
  String get linkAccountExplanation;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and this device’s sign-in credentials will be deleted. Local screenshots and collections will remain. Your subscription will not automatically cancel; manage it in Apple subscription settings. You will be asked to verify your account again.'**
  String get deleteAccountBody;

  /// No description provided for @authDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is off in this version. Everything works without an account.'**
  String get authDisabled;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is not configured yet. You can use all basic features without an account.'**
  String get authUnavailable;

  /// No description provided for @authCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled. Your collections are still here.'**
  String get authCancelled;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish signing in. Please try again later.'**
  String get authFailed;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Your account cannot be reached right now. Check your connection; your local collections remain available.'**
  String get authNetwork;

  /// No description provided for @authConflict.
  ///
  /// In en, this message translates to:
  /// **'This sign-in belongs to another account. Sign in using your original method, then link the other provider here. Accounts were not automatically merged.'**
  String get authConflict;

  /// No description provided for @authRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your account access ended. You can keep using your collections and sign in again whenever you choose.'**
  String get authRevoked;

  /// No description provided for @authDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted. This device’s collections are preserved.'**
  String get authDeleted;

  /// No description provided for @authSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out. Your collections remain on this device.'**
  String get authSignedOut;

  /// No description provided for @authBillingSync.
  ///
  /// In en, this message translates to:
  /// **'You are signed in, but subscription status is unavailable. We will check again when connected.'**
  String get authBillingSync;

  /// No description provided for @photoAccessUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo access status is unavailable right now. You can select photos or try again.'**
  String get photoAccessUnavailable;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get sortTitle;

  /// No description provided for @starterImport.
  ///
  /// In en, this message translates to:
  /// **'Import screenshots'**
  String get starterImport;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get entryDeleted;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get markDone;

  /// No description provided for @markTodo.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get markTodo;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @linkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Open this link?'**
  String get linkConfirmTitle;

  /// No description provided for @linkConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This link was read from a screenshot. Check the address before you open it.'**
  String get linkConfirmBody;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your data isn\'t included in device backups, so entries don\'t move to a new device.'**
  String get privacyNote;

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String onboardingProgress(int current, int total);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
