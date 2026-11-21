# Product, auth, permissions and UI verification — 21 October 2026

This is the later product/auth pass on the existing project. It supersedes earlier Pro-automation and anonymous-only privacy descriptions. No project, bundle/application ID, database filename, schema version or native target was renamed. Source and app data were backed up privately before editing. No Git repository exists, so no committed-history review is claimed.

## Implemented behavior

- Three short editorial scenes use local vector screenshot fragments, progressively resolving into semantic groups and category colors. No remote artwork, personal image, AI gradient or long splash is used. First-run completion persists in the existing preference table; established libraries skip and record completion. Android goes directly to selected import after the scenes because automatic discovery/OCR remain iOS-only.
- A compact contextual sheet precedes the native request. Only an explicit primary action in the actual not-determined state requests access. Denied/restricted states do not re-request. Manual picker remains available. Limited access uses Apple's limited-selection manager. Settings and Home show actual status; failed reads show unavailable rather than an invented status. Foreground/Settings return refreshes it.
- New explicit access grants include available screenshot history, then use metadata/subtype filtering and incremental full-access reconciliation. Limited-selection changes can expose older assets and reconcile through the existing ledger. Paused existing configuration is respected. No unrelated image content is scanned automatically. Cross-path picker/automatic Photos IDs and conditional queue claims prevent duplicate/stale commits.
- Existing four destinations now use a floating dock with safe-area spacing, restrained selected capsule/weight, 190ms scale response, intentional haptics, keyboard handling and explicit VoiceOver tap semantics. IndexedStack preserves tab state and Scaffold reserves content space.
- Optional Firebase Auth only: local guest first, Google/Apple token exchange, nonce-bound Apple authorization, current-provider reauthentication before linking/deletion, conflicts without silent merges, SDK session refresh/revocation, logout and confirmed account deletion preserving the local library. Firebase UID bridges to RevenueCat only after billing consent. Old-user access is cleared; identity/store operations serialize and older refresh results cannot replace a newer account.
- Basic automatic discovery is now free. Verified iOS Pro increases selected batches from 10 to 50; expired/offline-unverified status does not lock saved content or free discovery. No paid cloud AI or fake server quota was introduced.

## Executed automated checks

- `dart format .`: 68 Dart files; final clean check recorded separately in console logs.
- `flutter analyze`: no issues; diagnostics were fixed, not suppressed.
- `flutter test`: **99 tests passed**, including both providers' mock success/cancel/failure, guest/startup, linking/conflicts, stale Keychain-session protection, logout/delete/revocation/offline behavior, exact local-row preservation and RevenueCat identity/refresh races; all permission states, unknown status, Settings return, older limited selections, onboarding persistence, denial/manual action, accessible layouts and cross-path duplicate races.
- **All 3 existing native integration tests passed**, command `flutter test integration_test --no-uninstall --dds --dds-port=0 --verbose -d <SIMULATOR_ID>`. Real English/Turkish Apple Vision, bounded normalization/corrupt/out-of-sandbox rejection, SQLite reopen/CRUD, localized UI and synthetic automatic-import fixtures ran. Fake Photos sources are not proof of physical screenshot notifications.
- `flutter build ios --simulator --debug` passed (367.4 seconds). Normal `lib/main.dart` built and launched on the new iPhone 17 (388.1 seconds); the normal launch command exited zero. Native tests were never run on the original development simulator.
- OSV checked **119 locked hosted Pub packages**, including dev dependencies, with no known advisory IDs returned. This limited lookup is not a security guarantee or complete native SDK review.
- Scoped source credential/logging scan found no recognized secrets or source review notes. Generated SDK/build trees are pruned before walking to avoid File Provider stalls; expected Firebase public client API-key fields are distinguished from private credentials. No keys were supplied during this pass.

## Actual simulator UI observations

All three editorial scenes and the compact pre-prompt were viewed. Apple's actual Photos prompt appeared only after the explained primary action. Denial led to a usable Home and truthful Not Allowed card with manual/Settings actions, plus the floating dock. The system picker opened after denial and displayed Apple's selected-only privacy banner. Seven selected images were then observed saved (one Recipe, six Other), with broad access still Not Allowed. This is a real selected-import result, not seeded production sample content. The test device contains those seven saved rows; they were retained and backed up rather than cleared.

Guest Settings showed equivalent Google/Apple controls and explicit unavailable configuration, with photo access, free/Pro and restore entry points. Both provider controls correctly remained unavailable without actual public configuration; no real OAuth sheet, account creation/deletion or store transaction was claimed. Visual review led to matching caption colors, a less regular recognition arrangement and an isolated Apple-button VoiceOver label; these refinements were compiled/tested in source. Physical visual/accessibility QA remains necessary.

Original development simulator <SIMULATOR_ID> was not launched/uninstalled/erased: **all 12 app-file content hashes remain unchanged**. Older test simulator <SIMULATOR_ID> was backed up and shut down on a read-only Settings screen. New test simulator <SIMULATOR_ID> was also backed up and shut down for Release compilation; all seven entry rows matched its private backup. No simulator was deleted. These checks do not undo the separate historical 15 October preference-loss incident.

## Native build issues resolved and limits

The latest Firebase Core 5/Auth 7 native SDK 13 cannot resolve alongside current Google Sign-In iOS 9 due to incompatible GTMSessionFetcher ranges. Compatible published Core 4.15.0/Auth 6.7.0 (native Firebase 12.19.0) were selected; no SDK code/resolver constraints were patched. Preserve the lockfile and rerun native builds before upgrading that combination.

The Mac ran out of free disk space. Only obsolete generated outputs/verification caches from this app were reclaimed; source/data backups and a previously verified app artifact were retained. Generated iOS/macOS plugin files in the iCloud-managed Desktop then timed out. They were preserved in ignored sibling directories and regenerated through temporary staging; the helper now supports the same repair. A generated Android SDK-location file that timed out was restored byte-for-byte from the pre-change backup. No app database or user preference was removed to repair the environment. Native builds run sequentially; a two-job unsigned device precompile reduces memory pressure.

Native auth manifests disclose Google/Firebase operational diagnostics/usage/identifiers. Account/privacy copy and the matrix now say so; there is no blanket telemetry-off guarantee. No screenshot/OCR payload is supplied to those SDKs. Only a physical configured build with network inspection can validate full processor behavior.

## External work and readiness

Real Firebase/OAuth configuration, native callback and Apple entitlement/provisioning, approved hosted legal URLs, store/RevenueCat products and keys, sandbox purchases/restore/identity aliases and physical-device Photos/iCloud/revocation/VoiceOver remain unverified. Android SDK is absent; this pass does not claim a new APK/device result. Existing Android build failure remains applicable to that toolchain, and Android Pro sales stay disabled.

Follow [AUTH_AUDIT.md](AUTH_AUDIT.md), [MANUAL_AUTH_AND_SERVICE_SETUP.md](MANUAL_AUTH_AND_SERVICE_SETUP.md), [PHYSICAL_IPHONE_RUN.md](PHYSICAL_IPHONE_RUN.md) and the current privacy matrix. No Apple account configuration, provider project, App Store record, signing credential or publication was created automatically.

**READY FOR PHYSICAL IPHONE TEST: NO for the complete auth/purchase flow until legitimate signing and real configuration are supplied. Guest/local code can be installed and tested after valid signing.**

**READY FOR TESTFLIGHT: NO.** Missing real configuration, legitimate signing/archive validation, approved legal/disclosure content and actual store/device acceptance checks remain blockers.

## Unsigned Release result

Device Release compilation/manifest audit is recorded below when the actual command finishes; unsigned compilation never implies signing, archive validation or upload.
