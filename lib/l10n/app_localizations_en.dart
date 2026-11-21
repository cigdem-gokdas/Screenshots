// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Unuttuğum Screenshotlar';

  @override
  String get home => 'Collections';

  @override
  String get library => 'Library';

  @override
  String get review => 'Daily review';

  @override
  String get settings => 'Settings';

  @override
  String get homeEyebrow => 'A LITTLE LESS FORGOTTEN';

  @override
  String get homeTitle => 'Save a little.\nLive a little more.';

  @override
  String get homeSubtitle => 'Good finds deserve more than a screenshot.';

  @override
  String get yourCollections => 'Your collections';

  @override
  String get allEntries => 'All entries';

  @override
  String get addEntry => 'New entry';

  @override
  String get watchlist => 'Watchlist';

  @override
  String get recipes => 'Recipes';

  @override
  String get reading => 'Reading list';

  @override
  String get gaming => 'Gaming';

  @override
  String get places => 'Places to visit';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get ideas => 'Ideas';

  @override
  String get other => 'Other';

  @override
  String get watchHint => 'For your next quiet night';

  @override
  String get recipesHint => 'Something worth making';

  @override
  String get readingHint => 'Your next chapter';

  @override
  String get gamingHint => 'A new world awaits';

  @override
  String get placesHint => 'A little further afield';

  @override
  String get wishlistHint => 'Thoughtful little wants';

  @override
  String get ideasHint => 'Make room for a spark';

  @override
  String get otherHint => 'A place for everything else';

  @override
  String get reviewTeaser => 'From saved to someday soon';

  @override
  String get reviewTeaserBody => 'A small look at what caught your eye.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries yet',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Search your finds';

  @override
  String get allCategories => 'All categories';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get filter => 'Filter';

  @override
  String get todo => 'To do';

  @override
  String get completed => 'Completed';

  @override
  String get archived => 'Archived';

  @override
  String get noEntries => 'A little space for possibility';

  @override
  String get noEntriesBody =>
      'Add something you want to watch, try, read or explore.';

  @override
  String get noResults => 'No matching entries';

  @override
  String get noResultsBody => 'Try another search or clear your filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get newEntry => 'A good find';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get editorSubtitle => 'Give that someday a place to start.';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'What caught your eye?';

  @override
  String get categoryLabel => 'Collection';

  @override
  String get descriptionLabel => 'Notes (optional)';

  @override
  String get descriptionHint => 'A detail you want to remember…';

  @override
  String get urlLabel => 'Link (optional)';

  @override
  String get urlHint => 'https://…';

  @override
  String get statusLabel => 'Status';

  @override
  String get save => 'Save entry';

  @override
  String get cancel => 'Cancel';

  @override
  String get titleError => 'Enter a title between 1 and 120 characters.';

  @override
  String get descriptionError => 'Keep notes under 5,000 characters.';

  @override
  String get urlError => 'Enter a public https link without login details.';

  @override
  String get saveError =>
      'Could not save. Your changes are still here. Try again.';

  @override
  String get details => 'Your find';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete entry';

  @override
  String get deleteTitle => 'Let this one go?';

  @override
  String get deleteBody =>
      'This entry will be permanently deleted from this device.';

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get actionError => 'That didn’t work. Please try again.';

  @override
  String get openLink => 'Open link';

  @override
  String get linkError => 'This link could not be opened.';

  @override
  String savedOn(String date) {
    return 'Saved $date';
  }

  @override
  String updatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get notes => 'A note to remember';

  @override
  String get entryGone => 'This entry is no longer available.';

  @override
  String get reviewEyebrow => 'A MOMENT TO RECONNECT';

  @override
  String get reviewTitle => 'Make room\nfor a little doing.';

  @override
  String get reviewSubtitle => 'Your collections, with a little perspective.';

  @override
  String get savedToday => 'Saved today';

  @override
  String get uncompleted => 'Still to do';

  @override
  String get completedItems => 'Completed entries';

  @override
  String get distribution => 'Where curiosity takes you';

  @override
  String get revisit => 'Worth another look';

  @override
  String get revisitHint => 'Unfinished finds untouched for at least 7 days.';

  @override
  String get noRevisit => 'You’re all caught up for now.';

  @override
  String get suggestionLabel => 'ONE SMALL SUGGESTION';

  @override
  String suggestion(String title, String category) {
    return 'Start with “$title” in $category. One good find is enough for today.';
  }

  @override
  String get emptySuggestion =>
      'Your next good find starts here. Save something you’re curious about.';

  @override
  String doneSuggestion(int count) {
    return 'You’ve completed $count entries. Make a little room for your next discovery.';
  }

  @override
  String get archivedSuggestion =>
      'Your finds are in the archive. Reopen an entry whenever you feel curious.';

  @override
  String get viewEntry => 'Take a look';

  @override
  String get reviewEmpty => 'Your story starts with a find';

  @override
  String get reviewEmptyBody =>
      'Your real activity will appear here as you add entries.';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose what feels like home.';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get privacyTitle => 'Just you and your finds';

  @override
  String get privacyBody =>
      'Screenshot analysis uses Apple Vision and local rules on this device. Images and OCR text are not sent to a server. Optional account sign-in shares identity information with Firebase and your chosen provider; Pro billing shares purchase information with RevenueCat and the store.';

  @override
  String get storageTitle => 'On this device';

  @override
  String get storageBody =>
      'Uninstalling or clearing app storage can remove entries. On iOS, the app requests backup exclusion for its local database and imported copies. Backups made earlier are not changed.';

  @override
  String get loadError => 'Your collection couldn’t be loaded.';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get discardTitle => 'Discard your changes?';

  @override
  String get discardBody => 'Your unsaved changes will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get autoSync => 'Automatic Screenshot Sync';

  @override
  String get syncIntroTitle => 'Your screenshots.\nA little more organized.';

  @override
  String get syncIntroBody =>
      'Enable automatic sync once. New screenshots become entries without selecting, confirming or categorizing them. You can still edit anything later.';

  @override
  String get syncAccessTitle => 'You choose photo access';

  @override
  String get syncAccessBody =>
      'iOS may grant access to your full photo library, or only selected photos. Access is not scoped to Screenshots by the operating system. This app checks screenshot types and processes screenshots only. Limited access can miss screenshots. You can change or revoke access later in iOS Settings.';

  @override
  String get syncLocalTitle => 'Organized on this device';

  @override
  String get syncLocalBody =>
      'Screenshots and recognized text stay in app-local storage. Likely passwords, banking details and recovery codes are skipped after a minimal local check. Detection and categorization can make mistakes. Text recognition uses Apple Vision and local classification rules, not cloud AI.';

  @override
  String get syncForegroundTitle => 'Catches up when you return';

  @override
  String get syncForegroundBody =>
      'Sync runs while the app is active and catches up when you open it again. iOS can suspend or terminate the app; continuous background monitoring is not available. iCloud-only screenshots wait until available on this device.';

  @override
  String get syncEnable => 'Enable automatic sync';

  @override
  String get notNow => 'Not now';

  @override
  String get newOnly => 'Your archive first, then new screenshots';

  @override
  String get newOnlyBody =>
      'Available screenshots are discovered after you grant access. New screenshots are then added while the app is active. Duplicate content is not saved again.';

  @override
  String get importExisting => 'Import Existing Screenshots';

  @override
  String get importExistingTitle => 'Include older screenshots?';

  @override
  String get importExistingBody =>
      'Automatically organize accessible screenshots captured before sync was enabled. Sensitive screenshots are still skipped. Your original Photos library will not be changed.';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get lastSync => 'Last Successful Sync';

  @override
  String get neverSynced => 'Not yet';

  @override
  String get photoPermission => 'Photo access';

  @override
  String get accessNotDetermined => 'Not requested';

  @override
  String get accessAuthorized => 'Full Access';

  @override
  String get accessLimited => 'Limited Access';

  @override
  String get accessDenied => 'Not Allowed';

  @override
  String get accessRestricted => 'Access restricted by device controls';

  @override
  String get syncOff => 'Automatic sync is off';

  @override
  String get syncChecking => 'Checking photo access…';

  @override
  String get syncScanning => 'Finding screenshots…';

  @override
  String get syncProcessing => 'Organizing on this device…';

  @override
  String get syncIdle => 'Up to date';

  @override
  String get syncWaiting =>
      'Some screenshots are waiting — cloud assets retry when locally available';

  @override
  String get syncPaused => 'Paused while the app is inactive';

  @override
  String get syncError => 'Sync could not finish. Your entries are still here.';

  @override
  String get syncIOSOnly =>
      'Automatic library sync is available on iOS. Use selected imports and manual organization on Android.';

  @override
  String get openPhotoSettings => 'Open iOS Settings';

  @override
  String get deleteImported => 'Delete Imported Screenshot Data';

  @override
  String get deleteImportedTitle => 'Delete imported data from this app?';

  @override
  String get deleteImportedBody =>
      'Turns sync off and deletes imported entries, local image copies, extracted text and import history. Manual entries and original screenshots in Photos stay unchanged. Re-enabling starts with new screenshots only.';

  @override
  String screenshotFallback(String date) {
    return 'Screenshot · $date';
  }

  @override
  String get importedScreenshot => 'Imported screenshot';

  @override
  String capturedOn(String date) {
    return 'Captured $date';
  }

  @override
  String get imageUnavailable => 'The local screenshot copy is unavailable.';

  @override
  String get syncHistoryPending =>
      'Existing screenshots will be included when access is available.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get readPublishedPolicy => 'Read the published document';

  @override
  String get legalDraftNotice =>
      'This summary is a draft. The developer must publish and approve the complete legal documents before subscriptions are available.';

  @override
  String get privacyPolicyBody =>
      'Your selected screenshots, extracted text and collections are processed on this device and stored in app-private storage. No screenshot or OCR content is sent to a backend or AI provider. Automatic sync is optional and requires separate Photos access; you can change access in device Settings.\n\nOptional Pro subscriptions use Apple/Google and RevenueCat. After you choose to connect, a purchase identifier and purchase history are shared to validate subscriptions. SDK diagnostics and automatic attribution-identifier collection are disabled. RevenueCat provides purchase reporting for the developer. We add no advertising, tracking or app analytics SDK.\n\nDelete individual entries or use Delete Imported Screenshot Data in Settings to remove imported entries, copies and import history. Manual entries remain until you delete them. Original Photos are never deleted. Temporary processing copies are removed after each attempt or swept on the next launch after interruption. Purchase records are retained separately by the store and RevenueCat; deleting local screenshots does not cancel a subscription or erase records they must retain.\n\nUninstalling can remove local data. The app requests iOS file protection and backup exclusion for its database and imported copies; previous backups and filesystem snapshots may retain data. Sensitive-screen checks can miss content and deletion is not certified secure erasure. External saved links open only when you choose. No user account is required. If you choose Google or Apple sign-in, Firebase Authentication and the selected provider process your sign-in identity (UID, optional name/email or Apple relay email, credentials and connection metadata). We do not send screenshots or OCR text to them. SDKs manage session credentials; they are not saved in the app database. Firebase UID is used for RevenueCat identity after billing consent. Delete Account requires reauthentication, deletes the Firebase account and clears this device’s session while keeping its local collections. Store and RevenueCat purchase records are separate; subscriptions are not cancelled by account deletion. No screenshot cloud backup or cross-device collection sync exists.\n\nGoogle Sign-In and Firebase Auth may process diagnostics, device/user identifiers and usage information for their services. Their SDK privacy declarations include broader categories as well. The app does not request a phone-number or location permission; provider metadata is separate from screenshot content. No separate advertising or app-analytics service was added; we do not claim all provider operational measurements are disabled.';

  @override
  String get termsBody =>
      'Free features include selected imports, local organization, viewing, editing and deletion. On iOS, Apple Vision and local rules analyze screenshots without paid cloud AI. Android selected imports keep the image for manual organization; text recognition is currently iOS-only.\n\nAutomatic screenshot discovery is free on iOS while the app is active. Pro increases manual selection batches from 10 to 50 photos on iOS. It does not provide continuous background monitoring or unlimited cloud AI. Monthly and yearly subscriptions renew automatically unless cancelled through the store at least 24 hours before renewal. The store displays the exact local price and confirms each purchase. Payment is handled by the store. Manage or cancel in your store subscription settings; deleting this app or its content does not cancel billing.\n\nExisting saved data remains accessible if Pro expires or verification is temporarily unavailable. Recently verified subscription access may continue offline for up to 72 hours, never beyond its known expiry. A refund, revocation or expiry removes the larger Pro batch allowance after verification.\n\nClassification and sensitive-content checks may be wrong. Review and edit results when needed. This draft requires developer legal approval and complete publisher/contact details before release.';

  @override
  String get proTitle => 'Unuttuğum Screenshotlar Pro';

  @override
  String get proBadge => 'Pro';

  @override
  String get proHeadline => 'Organize a bigger pile.';

  @override
  String get proBenefits =>
      'Import up to 50 photos in one selection. Analysis happens on your device. Automatic screenshot discovery and basic features are available to everyone.';

  @override
  String get freeAlways =>
      'Selected imports (10 photos), automatic discovery, viewing, editing, deleting, search and Daily Review remain free.';

  @override
  String get proActive => 'Pro is active';

  @override
  String get freePlan => 'Free plan';

  @override
  String get upgradePro => 'Explore Pro';

  @override
  String get billingDisclosure =>
      'To view plans or restore, connect to RevenueCat and your store. Purchase identifiers (linked to your Firebase UID if you sign in) and purchase history are used to verify subscriptions. Your screenshots and recognized text are not shared. No account is needed.';

  @override
  String get viewPlans => 'Connect and view plans';

  @override
  String monthlyPrice(String price) {
    return '$price / month';
  }

  @override
  String yearlyPrice(String price) {
    return '$price / year';
  }

  @override
  String get subscriptionTerms =>
      'Auto-renewing subscription. The store confirms price and payment. Cancel in store subscription settings at least 24 hours before renewal. Your saved data remains accessible after cancellation.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get purchaseSuccess => 'Pro is ready. Enjoy a little less organizing.';

  @override
  String get restoreSuccess => 'Your Pro subscription has been restored.';

  @override
  String get restoreEmpty =>
      'No active Pro subscription was found for this store account.';

  @override
  String get purchaseCancelled =>
      'Purchase cancelled. You can continue using the free features.';

  @override
  String get purchasePending =>
      'Waiting for store approval. Please do not purchase again; access updates after confirmation.';

  @override
  String get purchaseFailed =>
      'The purchase could not be completed. Check your connection and store account, then try again.';

  @override
  String get billingUnavailable =>
      'Subscription options are unavailable right now. Your saved data and free features are still available.';

  @override
  String get autoSyncPro =>
      'Automatic library organization is a Pro feature. Existing entries stay available on every plan.';

  @override
  String get importScreenshots => 'Import screenshots';

  @override
  String get pickerHeadline => 'Choose a few\ngood finds.';

  @override
  String get pickerExplanation =>
      'Select screenshots or photos with the system picker. The app receives only what you choose; full photo-library access is not required. On iOS, text is recognized and categorized on this device. Nothing is uploaded to an AI service. You can edit or delete every result.';

  @override
  String get pickerLimits =>
      'Up to 10 photos per selection, or 50 with Pro. Images are resized on your device and original location metadata is discarded.';

  @override
  String get chooseScreenshots => 'Choose images';

  @override
  String get importWorking =>
      'Organizing on this device… You can cancel safely.';

  @override
  String importSummary(int imported, int duplicates, int skipped, int failed) {
    return '$imported saved · $duplicates already saved · $skipped skipped for privacy · $failed could not be processed.';
  }

  @override
  String get photoAccessSection => 'Photo Access';

  @override
  String get photoPromptTitle => 'Find your screenshots?';

  @override
  String get photoPromptBody =>
      'With full access we find and sort your screenshots automatically, or you can add only the ones you pick.';

  @override
  String get localAnalysis => 'Analysis happens on your device.';

  @override
  String get findScreenshots => 'Find My Screenshots';

  @override
  String get pickMyself => 'I’ll Choose';

  @override
  String get selectPhotos => 'Select Photos';

  @override
  String get manageAccess => 'Manage Access';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get allowInSettings => 'Allow in Settings';

  @override
  String get photoLimitedBody => 'We can only see the photos you selected.';

  @override
  String get photoDeniedBody =>
      'Photo access is off. You can still choose screenshots yourself.';

  @override
  String get photoRestrictedBody =>
      'Photo access is restricted on this device and cannot be changed from the app. You can still try selecting photos.';

  @override
  String get photoFullBody =>
      'Screenshots are discovered while the app is active. Other photos are not analyzed.';

  @override
  String get onboardingSaved => 'You saved it.';

  @override
  String get onboardingLost => 'Then it disappeared.';

  @override
  String get onboardingRecognition =>
      'Your screenshots are really a to-do list.';

  @override
  String get onboardingResolution =>
      'Saving isn’t enough.\nYou need to find it again.';

  @override
  String get onboardingNext => 'Continue';

  @override
  String get organizeHell => 'Organize the Chaos';

  @override
  String get onboardingGuest => 'Start without an account.';

  @override
  String get semanticWatch => 'Watch';

  @override
  String get semanticRead => 'Read';

  @override
  String get semanticGo => 'Go';

  @override
  String get semanticEat => 'Eat';

  @override
  String get semanticDo => 'Do';

  @override
  String get accountTitle => 'Account';

  @override
  String get guestMode => 'Yours, on this device.';

  @override
  String get accountConnected => 'Account connected';

  @override
  String get accountExplanation =>
      'Signing in is optional. It keeps your subscription identity; screenshots are never uploaded.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get linkGoogle => 'Link Google account';

  @override
  String get linkApple => 'Link Apple account';

  @override
  String get linkAccountExplanation =>
      'Linking another provider first verifies your current account. Matching email addresses never merge accounts automatically.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountBody =>
      'Your account and this device’s sign-in credentials will be deleted. Local screenshots and collections will remain. Your subscription will not automatically cancel; manage it in Apple subscription settings. You will be asked to verify your account again.';

  @override
  String get authDisabled =>
      'Account sign-in is off in this version. Everything works without an account.';

  @override
  String get authUnavailable =>
      'Account sign-in is not configured yet. You can use all basic features without an account.';

  @override
  String get authCancelled =>
      'Sign-in cancelled. Your collections are still here.';

  @override
  String get authFailed =>
      'Could not finish signing in. Please try again later.';

  @override
  String get authNetwork =>
      'Your account cannot be reached right now. Check your connection; your local collections remain available.';

  @override
  String get authConflict =>
      'This sign-in belongs to another account. Sign in using your original method, then link the other provider here. Accounts were not automatically merged.';

  @override
  String get authRevoked =>
      'Your account access ended. You can keep using your collections and sign in again whenever you choose.';

  @override
  String get authDeleted =>
      'Account deleted. This device’s collections are preserved.';

  @override
  String get authSignedOut =>
      'Signed out. Your collections remain on this device.';

  @override
  String get authBillingSync =>
      'You are signed in, but subscription status is unavailable. We will check again when connected.';

  @override
  String get photoAccessUnavailable =>
      'Photo access status is unavailable right now. You can select photos or try again.';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortTitle => 'A to Z';

  @override
  String get starterImport => 'Import screenshots';

  @override
  String get addManually => 'Add manually';

  @override
  String get undo => 'Undo';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get markDone => 'Done';

  @override
  String get markTodo => 'Reopen';

  @override
  String get share => 'Share';

  @override
  String get linkConfirmTitle => 'Open this link?';

  @override
  String get linkConfirmBody =>
      'This link was read from a screenshot. Check the address before you open it.';

  @override
  String get open => 'Open';

  @override
  String get bestValue => 'Best value';

  @override
  String get privacyNote =>
      'Your data isn\'t included in device backups, so entries don\'t move to a new device.';

  @override
  String onboardingProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get moreActions => 'More actions';
}
