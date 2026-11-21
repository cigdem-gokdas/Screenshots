import 'dart:io';

import 'auth/auth_controller.dart';
import 'auth/auth_config.dart';
import 'auth/firebase_auth_gateway.dart';
import 'onboarding/onboarding_controller.dart';
import 'data/product_preferences.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'application/app_controller.dart';
import 'data/database.dart';
import 'data/entry_repository.dart';
import 'data/sync/import_media_store.dart';
import 'data/sync/photo_manager_library.dart';
import 'data/sync/private_storage.dart';
import 'data/sync/sync_repository.dart';
import 'data/sync/vision_recognizer.dart';
import 'l10n/app_localizations.dart';
import 'sync/screenshot_sync.dart';
import 'ui/app.dart';
import 'billing/billing_consent_store.dart';
import 'billing/revenuecat_gateway.dart';
import 'billing/subscription_controller.dart';
import 'config/release_config.dart';
import 'importing/selected_import.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // File protection + backup exclusion BEFORE the database file is created.
  await protectStorageAtLaunch();
  final databaseExisted = await defaultDatabaseFileExists();
  final database = AppDatabase();
  final media = ImportMediaStore();
  late final AppController controller;
  late final SelectedImportService importer;
  const release = ReleaseConfig();
  final consent = BillingConsentStore(database);
  final billing = SubscriptionController(
    gateway: RevenueCatGateway(release),
    readConsent: consent.read,
    writeConsent: consent.accept,
    config: release,
  );
  String fallback(DateTime date) {
    final locale = controller.language == null
        ? resolveLocale(WidgetsBinding.instance.platformDispatcher.locales)
        : Locale(controller.language!);
    final l = lookupAppLocalizations(locale);
    return l.screenshotFallback(
      DateFormat.yMMMd(l.localeName).add_Hm().format(date),
    );
  }

  final sync = ScreenshotSync(
    repository: SyncRepository(database),
    initialAutomationAccess: true,
    beforeDelete: () => importer.cancelAndDrain(),
    initiallyForeground:
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    library: PhotoManagerScreenshotLibrary(),
    recognizer: VisionLocalTextRecognizer(),
    media: media,
    prepareStorage: preparePrivateSyncStorage,
    fallbackTitle: fallback,
  );
  importer = SelectedImportService(
    picker: SystemImagePicker(
      limit: () => billing.hasPro
          ? ReleaseConfig.proImportBatch
          : ReleaseConfig.freeImportBatch,
    ),
    batchLimit: () => billing.hasPro
        ? ReleaseConfig.proImportBatch
        : ReleaseConfig.freeImportBatch,
    normalize: normalizeSelectedImage,
    repository: SyncRepository(database),
    media: media,
    fallbackTitle: fallback,
    prepare: () async {
      await sync.initialize();
      await preparePrivateSyncStorage();
    },
    recognizer: Platform.isIOS ? VisionLocalTextRecognizer() : null,
  );
  final preferences = ProductPreferences(database);
  final auth = AuthController(
    gateway: FirebaseAuthGateway(const AuthConfig()),
    readEnabled: () => preferences.read('auth_enabled.v1'),
    writeEnabled: (value) => preferences.write('auth_enabled.v1', value),
    identifyBilling: billing.setAccountIdentity,
  );
  await reconcileInstallMarker(
    databaseExisted: databaseExisted,
    readMarker: () => preferences.read(installMarkerKey),
    writeMarker: () => preferences.write(installMarkerKey, true),
    signOutStale: () =>
        auth.discardStaleSession().timeout(const Duration(seconds: 10)),
  );
  final onboarding = OnboardingController(
    readCompleted: () => preferences.read('editorial_onboarding.v1'),
    writeCompleted: () => preferences.write('editorial_onboarding.v1', true),
  );
  controller = AppController(
    LocalEntryRepository(database, media: media),
    sync: sync,
    billing: billing,
    importer: importer,
    auth: auth,
    onboarding: onboarding,
  );
  runApp(ScreenshotApp(controller: controller));
  controller.initialize();
}
