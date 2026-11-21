Historical hardening-pass report, before the later optional-auth/product changes. See docs/PRODUCT_AUTH_VERIFICATION.md (or PRODUCT_AUTH_VERIFICATION.md within docs) for the current behavior and results.

# Release verification — 21 October 2026

Environment: Flutter 3.47.7, Dart 3.13.5, Xcode 26.3, iOS 26.3 simulator runtime. App minimum iOS 15.5, version/build `1.1.0+2`, schema 2 and existing identifiers remain unchanged.

## Passed checks

- `dart format .` and final `dart format --output=none --set-exit-if-changed .`: 56 Dart files, final check changed 0.
- `flutter analyze`: no issues. Introduced diagnostics were fixed rather than suppressed.
- `flutter test`: **64 unit/widget tests passed**. Existing CRUD/status/search/review/localization/migration/permission/recovery flows remain covered. New coverage includes selected import deduplication, cancellation, corruption, sensitive-content cleanup, size limits, coalesced purchases, cancel/pending/failure, restore found/empty, signature rejection, expiration/refund updates, bounded offline access, no launch paywall, saved data during billing failure, price rendering using injected store fixtures and large Turkish privacy text. Billing fixtures are not real store transactions.
- `flutter build ios --release --no-codesign`: unsigned Release compilation passed, including a clean reassembly from a source-identical temporary checkout at `/private/tmp/screenshot-production-verify-lhad1zes`, 37.5 MB. This is not signing, archive validation, physical installation or upload.
- Clean Release metadata: exact base/TR/EN names, existing bundle ID, iOS 15.5, Photos-only usage description, no ATS exception and no Flutter debug Bonjour/local-network entries.
- Clean Release includes **5 parsed privacy manifests**: app, RevenueCat, photo_manager, url_launcher_ios and Flutter framework. All declare no tracking. Removed picker SDK resources are absent. Detailed declarations/reasons are in IOS_RELEASE_MANIFEST_AUDIT.json.
- All 19 iOS icon slots match PNG dimensions; marketing icon is opaque RGB 1024×1024. Android manifest/backup-extraction XML parses. ARB keys match for TR/EN; the official name is identical.
- Scoped credential scan: no recognized secret/credential-file findings and no TODO/FIXME, development-endpoint or logging review notes in app source. Git history is absent, so no committed-history audit is claimed.
- OSV checked **102 locked hosted Pub packages** with no known advisory IDs returned. Public upstream advisory endpoints for RevenueCat purchases-ios/hybrid-common and photo_manager returned zero published records. These limited database queries are not a security guarantee. Outdated versions are recorded without mass major-version upgrades.
- Original iPhone 17 app data: full private backup first; **all 12 file-content hashes remain identical**. Baseline had zero entries/preferences/jobs. No original simulator launch, uninstall, erase or app-data write occurred. Historical 15 October preference loss is not claimed repaired.

## Build environment

Simulator and Release operations initially collided in the original Desktop checkout's Xcode derived data, producing VFS/module/build-database failures. A stale incremental app also retained an obsolete picker resource bundle. Failed rebuilds are not counted as passes. Final iOS verification runs sequentially in a temporary copy with 111 matching app/test/asset source fingerprints, outside the original Xcode index. The old generated build directory and conflicting project intermediates were preserved privately; a fresh ignored build symlink is prepared for subsequent main-checkout builds. Source and installed user data were not removed.

## Native integration

**All 3 native integration tests passed** on the dedicated iPhone 17 simulator <SIMULATOR_ID>. Actual successful command: `flutter test integration_test --no-uninstall --dds --dds-port=0 --verbose -d <SIMULATOR_ID>`, executed in the matching temporary checkout. Tests exercised real English/Turkish Apple Vision OCR, automatic classification/persistence/deduplication/wipe preserving a manual fixture, native photo-permission state reads, image normalization/pixel bounds and corrupt/out-of-sandbox/oversized rejection, plus UI save/completion, SQLite reopen and deletion.

Earlier attempts are not passes: a first startup/harness stall was interrupted; direct `--no-dds` allowed test execution but produced a Flutter golden-stream protocol error, and the older UI test assumed an offscreen Save button was built while the keyboard was open. Native tests now scroll to controls. Explicit DDS on a loopback port fixed the custom-stream handshake and the final command completed with `+3: All tests passed!`. The safe runner now uses the verified DDS flags and checks for an actual completion marker, since Flutter can exit zero on interruption. It still always creates a separate simulator and forces `--no-uninstall`, then restores `lib/main.dart` as the generated archive entry point after success. The main checkout entry point was also explicitly restored at the end of this pass.

The normal app also built and launched successfully on that dedicated device. Home branding, all eight collection labels, free import entry point and no launch paywall were observed. The free-import explanation and Apple's native selected-only privacy banner were inspected. Photos TCC rows stayed absent before/after opening the picker, confirming no broad authorization grant. Native-picker item coordinate clicks failed in the computer-use service (`noWindowsAvailable`), so a full manual picker selection/commit was not claimed; real-device selection remains a checklist item. The dedicated app was restarted without uninstalling/clearing data after this inspection. Settings upgrade/restore/manage controls and the empty Daily Review were also observed. The normal home preview is saved at `hardened-home-iphone17.png` (removed from the repo). Existing original-device data stayed untouched.

## Actual failures and remaining validation

- `flutter build apk --release` was attempted and stopped because the Android SDK is absent. Android/Kotlin paths have source review, not a passed APK/device result.
- Configuration preflight correctly reports **NOT READY**: owner-filled `config/release.public.json` is missing. Real public SDK key, legal URLs, products/offering and signed-distribution setup remain external work.
- Real sandbox purchase, pending/Ask to Buy, restore, renewal, expiry, refund/revocation and RevenueCat dashboard behavior are not verified. Unit fixtures do not substitute for them.
- Physical-device Photos dialogs, iCloud eviction, real screenshot notifications, kill/restart stress, locked storage/backup behavior, packet capture, VoiceOver and signed-archive privacy validation remain manual.
- Pinned/read-only CI was supplied but has not run on GitHub because this directory has no Git repository/remote.

**Ready for TestFlight distribution: NO.** Complete the external configuration, legitimate signing/identifier ownership, approved legal URLs and real store/device checks in MANUAL_RELEASE_TASKS.md. Nothing was published; no cloud AI/account/ad service was added.
