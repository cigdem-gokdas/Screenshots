# Unuttuğum Screenshotlar — rebranding report

Date: 15 October 2026. This updates the existing application without changing its UI design, storage implementation or identifiers. **Verification did not meet the data-preservation requirement:** Flutter’s native test runner uninstalled the shared-ID simulator application at teardown, deleting two existing preference rows. No entries, images or sync jobs existed before the run. The preferences remain unrecovered; see VERIFICATION.md for details. The official product name is exactly **Unuttuğum Screenshotlar** in both Turkish and English.

## Visible names changed

- gen-l10n `appName` in both ARBs and generated Dart: Flutter application title, home/header, Settings footer and the text semantics exposed for accessibility.
- iOS base and Turkish/English localized `CFBundleDisplayName`/`CFBundleName`, plus all three Photos permission explanations.
- Android application label now references `@string/app_name`, with matching default, Turkish and English brand resources.
- Web manifest name/short name, HTML title and Apple mobile-web-app title. Starter metadata descriptions now describe the existing local-first screenshot organizer.
- macOS bundle display/name metadata, Linux window/header title, Windows window title and file/product descriptions. Windows C++ uses `\u011f` to render the same Turkish `ğ` independently of compiler source encoding.
- Product/readme/architecture/security/release documentation and brand assertions in existing tests.

All eight category colors, white backgrounds, Manrope font, icons, layouts, animations, translations other than the brand, and application features are retained. The current onboarding uses generic localized copy without the former brand; no replacement was necessary there. There is no separate About page or implemented notification-title surface containing the former name.

## Files modified or added

Paths below are relative to the unchanged project directory.

| Area | Files |
| --- | --- |
| Localization | `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`, generated `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_tr.dart` |
| iOS | `ios/Runner/Info.plist`, `ios/Runner/en.lproj/InfoPlist.strings`, `ios/Runner/tr.lproj/InfoPlist.strings` |
| Android | `android/app/src/main/AndroidManifest.xml`; added `android/app/src/main/res/values/strings.xml`, `values-en/strings.xml`, `values-tr/strings.xml` |
| Other platform display metadata | `macos/Runner/Info.plist`, `linux/runner/my_application.cc`, `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `web/index.html`, `web/manifest.json` |
| Regression assertions | `test/widget_test.dart`, `integration_test/sync_test.dart` |
| Visual evidence | Added `rebranded-home-iphone17.png` (removed from the repo) |
| Documentation / release preparation | `README.md`, `PRODUCT_SPEC.md`, `ARCHITECTURE.md`, `SECURITY_CHECKLIST.md`, `VERIFICATION.md`, added `RELEASE_CHECKLIST.md`, added `REBRANDING_REPORT.md`, `.gitignore` |

Flutter/Xcode also regenerate ignored build/configuration files during verification; these are not intentional identity/source changes. Native targets, project files, dependency versions and app icon assets were not changed.

## Internal identifiers intentionally preserved

| Identifier | Existing value / reason |
| --- | --- |
| iOS/macOS bundle ID | `com.example.screenshotCehennemi`; preserves installation identity and app container. Test bundle IDs retain the same prefix. Registration/ownership is still to be confirmed for distribution. |
| Android application ID / namespace | `com.example.screenshot_cehennemi`; preserves installed app identity, data and Kotlin package dependencies. |
| Dart package / project directory | `screenshot_cehennemi`; preserves package imports, tooling and workspace references. |
| SQLite database | `screenshot_cehennemi.sqlite`, schema 2; changing the name could open an empty database instead of existing data. No schema migration was added. |
| Native OCR channel | `screenshot_cehennemi/local_vision`; Dart and Swift must continue agreeing. |
| Preferences / media / history | `language`, `screenshot_sync.v1`, existing imported-file directories/relative paths and queue/tombstones; retains language choice, sync configuration and deduplication. |
| Native targets / artifacts | `Runner`, macOS product filename, desktop binary/internal filename and Linux application ID remain stable to avoid breaking schemes, dependencies or installation identity. |
| Signing / version | Existing team configuration and `1.1.0+2` remain unchanged; no new credential or distribution identity was invented. |

The database/repository/sync/native bridge code, pubspec/lockfile, iOS project and Android build configuration were fingerprinted before and after editing (15 critical files) and are byte-for-byte unchanged.

## Remaining former-name references

The spaced former brand has no remaining occurrence in active application text/localization resources. Technical underscore/CamelCase forms intentionally remain in the identifiers above, test imports, native product/test-host configuration, IDE metadata, generated workspace paths and the temporary build-directory helper prefix. Documentation mentions those exact identifiers to explain compatibility.

Existing `home-iphone17.png` (removed from the repo) and `automatic-sync-home-iphone17.png` (removed from the repo) are historical captures and may visibly show earlier branding. They are not bundled application assets. A new screenshot records the current brand without overwriting historical evidence. No risky global identifier replacement was used.

## TestFlight status

The compiled simulator bundle has the correct localized name, preserved bundle ID, iOS 15.5 deployment target and AppIcon configuration. Native plist resources parse correctly; all 19 icon dimensions match their slots and the 1024px marketing image is opaque RGB. Only Photos usage is declared in source. Flutter debug builds additionally inject their VM-service local-network/Bonjour entries; inspect the final Release payload before distribution.

No credential files or recognized secret patterns were found in the scoped source scan. Common local credential files are now ignored. There is no Git repository/history in this workspace, so a committed-history secret audit could not be performed.

Remaining release work: verify ownership/registration of the exact existing development-style bundle ID, team membership and real distribution signing/provisioning; confirm App Store Connect metadata/name availability and build-number uniqueness; create/validate a signed Release archive; complete privacy/export declarations and physical-iPhone Photos/lifecycle/storage QA. Android SDK/build validation and its existing automatic-sync policy restriction remain unchanged. See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). No App Store Connect app, signing credentials, upload or publication was created.

Executed test results, normal app launch and data-comparison evidence are recorded in [VERIFICATION.md](VERIFICATION.md).
