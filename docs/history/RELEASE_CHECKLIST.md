# Unuttuğum Screenshotlar — TestFlight preparation

This checklist prepares the existing application for a later authorized distribution. No archive upload, App Store Connect app creation, credential generation, identifier change or publication has been performed. The brand is exactly **Unuttuğum Screenshotlar** in Turkish and English.

## Project checks completed for this rebrand

- [x] Flutter gen-l10n `appName`, home/header and Settings branding use the same official name in both locales. Other interface translations remain Turkish/English.
- [x] iOS `CFBundleDisplayName` and `CFBundleName`, including both native InfoPlist.strings localizations, use the official name. Bundle executable/target names remain unchanged.
- [x] Native Photos usage descriptions include the new name and explain screenshot processing and potentially broader OS library access. No camera, microphone, location, tracking or background-execution permission was added. No photo-write permission is requested.
- [x] Source Info.plist declares only Photos usage. The simulator debug bundle additionally contains Flutter's generated local-network/`_dartVmService._tcp` debugging entries; the installed Flutter build script skips that insertion in Release. Inspect the final Release archive to confirm its actual permission/entitlement payload before distribution.
- [x] Existing iOS bundle ID `com.example.screenshotCehennemi` is syntactically valid and preserved in Debug, Profile and Release. Registration, ownership and distribution provisioning have **not** been verified.
- [x] Existing deployment target remains iOS 15.5. The simulator build validates this configuration with the installed Xcode 26.3/iOS 26.3 SDK, not execution on the oldest supported device.
- [x] All app configurations select the existing `AppIcon` asset catalog; all 19 referenced PNG dimensions match their slots, including an opaque RGB 1024×1024 marketing icon. The icon has no text requiring rebranding.
- [x] Bundle/application IDs, Dart package, native targets/products, database filename/schema, preference keys, imported-file paths and OCR channel remain unchanged. Apply updates over the installed app without uninstalling or clearing data.
- [x] Source scan found no `.p8`, `.p12`, `.pfx`, provisioning profile, keystore, signing-properties or `.env` credential files and no recognized private-key/AWS/Google/GitHub/OpenAI key patterns. This is a limited source scan, not a guarantee. This workspace has no `.git`, so committed history could not be inspected. Ignore rules now cover common local credential files.

**Verification incident:** the native test runner’s default uninstall removed the original simulator container. Data preservation is not a passed check; see VERIFICATION.md for recovery status. Future integration runs must use `--no-uninstall` and a full app-data backup, preferably on a dedicated test simulator.

Executed commands, results and data-preservation evidence are recorded in [REBRANDING_REPORT.md](REBRANDING_REPORT.md) and [VERIFICATION.md](VERIFICATION.md).

## Required before an authorized upload

- [ ] Confirm active Apple Developer Program membership, access to the existing signing team and ownership/registration of the **exact existing** bundle ID. `com.example...` is a development-style identifier; its syntax alone does not establish registration eligibility. Resolve any ownership problem explicitly before changing identity, since a different ID creates a different installation and storage container.
- [ ] Confirm the App Store Connect record and matching bundle ID with the owner. Create a record only after authorization. Use **Unuttuğum Screenshotlar** as its localized product name, subject to Apple's name availability/review.
- [ ] Review the existing team configuration; select real distribution certificates/profiles through the owner's account. Do not put private signing material in source control. No credentials were invented or replaced for this task.
- [ ] Check build-number uniqueness against App Store Connect. Current version/build remains `1.1.0+2`; increment the build number before upload if required. Rebranding alone does not reset version history.
- [ ] Make a Release archive for a physical iOS destination, run Xcode distribution validation and inspect the final signed payload, entitlements, Info.plist, bundled privacy manifests and dependency declarations. A debug simulator build does not establish TestFlight eligibility.
- [ ] Complete applicable App Store privacy disclosures, privacy/support URLs, export-compliance assessment, beta description, review contact information and testing notes. Do not infer legal encryption declarations solely from local-first storage or a simulator run.
- [ ] Complete physical-iPhone QA: install/update over existing data; full/limited/denied/revoked Photos access; real screenshot notifications and foreground reconciliation; iCloud-deferred assets; restart/deduplication; backup exclusion/file protection; memory/performance and sensitive-screen heuristics. See SECURITY_CHECKLIST.md and VERIFICATION.md.
- [ ] Review current Apple upload/SDK requirements and dependencies again at release time. The existing Android sync-policy restriction and absent Android SDK validation remain outside this iOS rebrand.
- [ ] Obtain explicit authorization before uploading/distributing to TestFlight. No upload is part of the present task.

## Apple references

Apple requires the app's bundle ID to match the App Store Connect record and warns that it cannot be changed for that record after the first uploaded build: [Set the bundle ID](https://help.apple.com/xcode/mac/current/en.lproj/deve21d0239c.html), [Prepare for app distribution](https://help.apple.com/xcode/mac/current/en.lproj/dev91fe7130a.html).

Use the currently supported toolchain and a distinct build string when submitting: [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/). Distribution additionally needs program membership, signing and a real archive: [Distribute using TestFlight](https://help.apple.com/xcode/mac/current/en.lproj/dev2539d985f.html). These pages were consulted on 15 October 2026; recheck before release.

## Current production pass — 21 October 2026
Use [docs/MANUAL_RELEASE_TASKS.md](../MANUAL_RELEASE_TASKS.md) as the concrete current checklist. Optional RevenueCat billing, native selected imports and legal/privacy flows now exist. Real public SDK/legal configuration, store products/offering, signed archive validation and physical/sandbox QA remain required; unsigned compilation alone does not make this build ready for TestFlight. The original simulator was untouched in this pass, with a full backup and byte-identical file check. Do not rerun unsafe historical native commands: `tool/test_ios_safely.sh` creates a new simulator and uses `--no-uninstall`.

## Additional auth/product gates
- [ ] Complete MANUAL_AUTH_AND_SERVICE_SETUP.md with this app’s real Firebase/OAuth/Apple values and matching native callback. No secrets in dart-defines.
- [ ] Validate Apple entitlement/provisioning, Hide My Email, returning authorization, revoked credentials, conflict/link and Delete Account on physical iPhone.
- [ ] Validate guest → Google/Apple → logout/relaunch/restore in RevenueCat with existing/new UIDs and the intended dashboard transfer policy.
- [ ] Update subscription metadata: Pro is 50-image selected batches; basic automatic discovery is free.
- [ ] Replace earlier anonymous-only privacy labels with account-linked name/email/User ID/purchase disclosures and approved retention/legal text.
- [ ] Follow PHYSICAL_IPHONE_RUN.md; never uninstall/erase an existing installation to resolve signing or tests.
