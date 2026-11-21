# Unuttuğum Screenshotlar — rebrand verification

Date: 15 October 2026. Flutter 3.47.7, Dart 3.13.5, Xcode 26.3; iPhone 17 simulator / iOS 26.3. Version 1.1.0+2 and Drift schema 2 are unchanged.

## Critical verification incident — data preservation failed

The native integration test was executed with Flutter's default uninstall behavior. Despite its isolated fixture database, the runner used the installed application's bundle ID and **uninstalled the app at teardown**, deleting the original simulator data container. This violated the explicit no-uninstall/data-preservation instruction. The initial pre-test inventory contained **zero saved entries, zero screenshot jobs, zero owned image files and two preference rows**. After rebuilding/launching the normal app, the database contained zero preference rows. No saved content was present to lose, but the original preferences were lost. Prior OS permission-state preservation cannot be asserted.

The pre-test snapshot saved only table counts/content hashes, not a restorable SQLite copy. The original container no longer exists and no local backup was found. Limited candidate recovery did not match the pre-test hash; no guessed values were written. The two preferences remain unrecovered unless a real prior backup is supplied. The final state must **not** be described as a passed data-preservation check or a fully completed rebranding task.

The installed Flutter source confirms `flutter test` defaults `--uninstall` to true, and native test teardown invokes uninstall when enabled. README commands now explicitly include `--no-uninstall` and require a full app-data backup, preferably using a dedicated test simulator. No further native test was run against the installed app after discovering the incident. A nonempty data-preserving upgrade check should be repeated safely before release.

## Commands actually executed for this rebrand

| Check | Observed result |
| --- | --- |
| `dart format .` | Passed; 43 Dart files, final run changed 0. |
| `flutter analyze` | Passed; final run no issues. Two initially introduced test null-assertion warnings were fixed. |
| `flutter test` | Passed; all 43 tests. Initial new assertions incorrectly assumed lazy Settings footer/headline widgets were built while scrolled offscreen; corrected and rerun. |
| `flutter build ios --simulator --debug` | Passed; built `build/ios/iphonesimulator/Runner.app`. |
| `flutter test integration_test/sync_test.dart -d <SIMULATOR_ID>` | Final run passed, 1 integration test. First run failed because a tap occurred before a scroll settled; corrected with hit testing/settling. **This command omitted `--no-uninstall` and caused the incident above. Do not reuse it as written.** |
| `flutter run -d <SIMULATOR_ID> --no-resident` | Passed; normal app launched, left on home screen. This was a fresh simulator data container after test-runner uninstall. |
| Native plist validation | iOS Info.plist, TR/EN InfoPlist.strings and macOS Info.plist passed `plutil -lint`. |
| Compiled iOS metadata | Exact brand in base/TR/EN names and Photos descriptions; existing bundle ID/executable, version/build, iOS 15.5 and AppIcon selection verified. |
| Localization / Android source metadata | Exact same brand and ARB key parity for TR/EN; default/TR/EN Android string resources and application-label reference parse correctly. |
| iOS icons | All 19 referenced dimensions verified, including opaque RGB 1024px marketing icon. |
| Identity/storage source fingerprints | 15 critical files unchanged, including pubspec/lockfile, database/model/repositories, sync/bridge implementation, iOS project and Android build configuration. |
| Data snapshot comparison | **Failed**: preference table changed from 2 rows to 0 after test-runner uninstall. Saved-entry/job tables remained empty; owned-file counts remained 0. |
| Scoped source secret scan | No credential files or recognized key patterns found. No Git history exists here to inspect; this is not a security guarantee. |

The existing `integration_test/app_test.dart` was not rerun in this rebrand. Its earlier results below are historical only.

## What the passing native fixture verifies

The isolated test exercised real Apple Vision OCR for English and Turkish synthetic screenshots, the automatic classification/import pipeline, SQLite reopen/persistence, deduplication without repeated OCR, imported-data deletion preserving its manual fixture entry, and the native Photos permission-state read bridge. It also switched Turkish → English in Settings, verified each override persisted in the isolated test database and asserted the exact brand in both languages. Test fixture cleanup removed only its own temporary data; the harmful installation teardown was performed separately by Flutter tooling.

Real screenshot capture/Photos notifications, actual authorization dialogs and iCloud/native lifecycle edge cases were not exercised end to end. They remain physical-device QA, not passed checks.

## Visual verification

Captured and inspected `rebranded-home-iphone17.png` (removed from the repo) from the running normal app. The full **Unuttuğum Screenshotlar** header fits on iPhone 17 and `ğ` renders correctly with bundled Manrope. White surfaces, pastel cards and existing icons/layout remain. Both native localized names were also inspected in the compiled bundle; SpringBoard may apply its own long-name truncation beneath an icon.

The source declares only Photos usage. Flutter debug tooling injects local-network usage/Bonjour VM-service entries into the simulator bundle; its installed build script skips this insertion for Release. The actual signed Release payload remains unverified. No archive, upload or App Store Connect record was created. See RELEASE_CHECKLIST.md for remaining signing, identifier ownership, privacy and physical-device work.

---

# Earlier automatic-sync verification — 15 October 2026

**Historical correction:** the earlier statements that integration tests preserved the installed app data assumed fixture isolation also protected installation state. The rebrand run disproved that assumption because this Flutter runner uninstalls by default. Do not treat the historical preservation statements below as verified evidence.

Environment: Flutter 3.47.7, Dart 3.13.5, Xcode 26.3, iPhone 17 simulator / iOS 26.3. App version 1.1.0+2; Drift schema version 2.

## Automated results
- `dart format .`: completed.
- `flutter analyze`: no issues.
- `flutter test`: **43 tests passed**.
- `flutter build ios --simulator --debug`: succeeded, producing `build/ios/iphonesimulator/Runner.app`.
- Existing `integration_test/app_test.dart` on iPhone 17: passed (native manual CRUD, completion, SQLite reopen, language persistence, cleanup).
- New `integration_test/sync_test.dart` on iPhone 17: passed (native Apple Vision OCR and automatic imports using an isolated synthetic source/database, English and Turkish fixture recognition, automatic recipe classification, persisted image/text/entry across database reopen, deduplication without repeated OCR, local import-data wipe preserving manual entries, and real photo_manager permission-state bridge).
- English and Turkish localization key parity: verified. Both native InfoPlist.strings files and Info.plist pass `plutil -lint`, and both native localizations are included in the simulator bundle.
- ML Kit/GoogleDataTransport are absent from pubspec.lock and the built app's dependency artifacts. All native plugin dependencies use Swift Package Manager.

The normal app has also been built and launched successfully on the existing iPhone 17 simulator. Sync remains off by default; tests do not change the original Photos library. The native sync fixture test creates an isolated temporary database and removes its own test files. The existing integration test preserves real entries and restores the previous language setting.

## Unit/widget coverage
Actual SQLite CRUD/disk reopen, v1→v2 preservation of IDs/content/status/timestamps/language, atomic cancellation, opt-in permission gating, exact smart-album/subtype channel arguments, limited-access global metadata filtering, full/denied/restricted/limited state changes, permission revocation during OCR, permission expansion recovering inaccessible jobs, duplicate IDs/content, excluded sensitive content cleanup, fallback Other/title, bounded one-image processing over paginated galleries, retries/backoff/cloud deferral, interrupted jobs, off/foreground cancellation, inactive cold startup, manual-data preservation during wipe, locale fallback, search/filtering, Daily Review drill-down, failed-draft retention and large text in the existing UI.

## Explicitly unverified / physical iPhone checklist
The native screenshot source is wired to real photo_manager APIs, but the automated import fixture substitutes a synthetic library source to avoid modifying Photos. The actual OS permission dialog could not be clicked interactively in this run because the desktop UI automation service timed out. Permission-state reads were exercised natively; consent-before-request was exercised with an injected adapter in widget/native integration tests.

Verify on a physical iPhone:
1. Enable from onboarding; test full, limited, denied and restricted OS authorization and limited-selection changes.
2. Capture a real screenshot while active and while the app is suspended/terminated; confirm collection updates on change/foreground reconciliation.
3. Revoke authorization or turn sync off during a native load/OCR operation; verify no cancelled result is stored.
4. Test iCloud-only, subsequently downloaded, deleted/restored and unusually long/large screenshots with realistic galleries.
5. Force-kill during discovery, OCR, file copy, transaction and imported-data deletion; verify restart cleanup and deduplication.
6. Verify backup exclusion/file protection on the physical device, and assess sensitive-screen false positives/negatives with representative Turkish/English content.
7. Perform release dependency/network inspection, physical-device memory/performance testing, signing and store privacy review.

Android automatic photo sync is deliberately unavailable pending policy eligibility validation. The Android SDK is absent, so APK execution and final merged-manifest inspection are not verified. Main-manifest directives remove broad plugin photo/storage permissions. Manual Android functionality is preserved in source.

No independent security audit, secure-erasure validation, perfect sensitivity/classification accuracy or continuous background-execution guarantee is claimed.

## Local build environment
This Desktop folder is iCloud-managed, which added codesign-incompatible Finder metadata to generated frameworks. The ignored build directory is staged outside Desktop through a symlink. README.md and tool/prepare_ios_build.sh explain the workaround; no Flutter SDK source was modified.
