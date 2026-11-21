# Unuttuğum Screenshotlar — privacy/security review

This is an implementation review, not an independent audit or a security guarantee.

## Implemented controls
- [x] Sync is off initially. Only the explicit enable action after onboarding calls the OS authorization request. Startup/foreground reconciliation only reads authorization state when previously enabled.
- [x] Separate handling for not determined, full, limited, denied and restricted photo authorization.
- [x] Full access uses Apple's Screenshots smart-album subtype; all loaded assets must independently carry the screenshot media subtype. Limited access processes only permitted screenshot assets.
- [x] UI explicitly says iOS permission can cover the full library; it never claims OS-enforced screenshot-only scope.
- [x] No Photos editor/write/delete/move APIs. App deletions target only owned SQLite rows and owned image/staging files.
- [x] Google ML Kit and its telemetry dependencies were removed after the user's explicit Apple Vision choice. Native Vision is local; no analytics SDK, cloud OCR, remote classifier, upload client, API key or account service is added.
- [x] On-device sensitive-screen detection runs before classification, retained image copy or content fingerprinting. Excluded jobs clear raw asset IDs/dates and keep no OCR text/image/hash.
- [x] No application logging of OCR, image bytes, native errors, asset IDs, filenames or content metadata. photo_manager logging is left disabled; verbose logging is never enabled.
- [x] Stable ID digests and non-sensitive content hashes suppress duplicate/repeated processing. Individual entry deletion retains tombstones; full wipe deletes them.
- [x] Additive schema migration, persistent queue, transactional entry+completion writes, bounded retries and restart cleanup.
- [x] Pause/off cancels future work, observation, native loads and timers; in-flight OCR results cannot commit after cancellation.
- [x] Owned image names are fixed hexadecimal digests with relative safe paths. Native Vision accepts sandbox file URLs only. Original EXIF/location metadata is not copied into normalized preview files.
- [x] iOS storage preparation requests complete file protection and backup exclusion for database-containing Documents and imported image/staging directories before automatic processing. Failure blocks the worker and surfaces an error.
- [x] Existing HTTP(S) URL validation and explicit external-browser action remain; no saved link is fetched for classification.
- [x] Android broad photo/storage permissions are explicitly removed in the main manifest, including plugin-contributed READ_EXTERNAL_STORAGE. Automatic sync is disabled on Android.

## Limits / required release verification
- [ ] Heuristics are imperfect: sensitive content may be missed and harmless content may be excluded. Test OTP, Turkish/English banks, recovery phrases, redacted screens and adversarial/obscured text on physical devices. Never advertise perfect detection.
- [ ] A temporary staged file may survive process termination until next startup. Immutable OCR strings can remain in process memory until garbage collection. No verified secure-memory or forensic-erasure claim is made.
- [ ] SQLite deletion is not certified secure erasure; deleted pages, old device backups or filesystem snapshots can retain older data. This app does not alter backups already made before backup exclusion was configured.
- [ ] Confirm actual backup exclusion, file-protection behavior while locked and OS/simulator differences on a physical iPhone. Existing Apple device diagnostics and OS backup behavior are not independently audited.
- [ ] Validate full/limited/restricted authorization, permission revocation during a job, limited selection changes, iCloud-only/evicted assets, missing assets, capture notifications, large galleries and forced termination on a physical iPhone.
- [ ] Verify notification start/stop and that no work commits after off/pause across real native lifecycle timing.
- [ ] Review release dependency advisories and perform network/telemetry inspection before making broader zero-network guarantees. Opening a saved URL intentionally uses the browser and its separate behavior.
- [ ] Android APK/merged-manifest validation requires an installed SDK. Do not remove permission-blocking directives or enable Android sync until a documented Play policy eligibility review and appropriate implementation are complete.
- [ ] Release signing, identifiers, App Store privacy declarations and independent security review remain outstanding.

## Policy/reference notes
The current implementation deliberately requests no Android broad media access. This is not a claim of Play eligibility or approval. Before any future Android implementation, review the current [Google Play Photo and Video Permissions policy](https://support.google.com/googleplay/android-developer/answer/14115180), document why persistent broad access is necessary, validate eligibility through the required declaration/review process and test the final merged manifest.

[Apple limited Photos access](https://developer.apple.com/documentation/photokit/delivering-an-enhanced-privacy-experience-in-your-photos-app), [Apple on-device text recognition](https://developer.apple.com/documentation/vision/recognizing-text-in-images), and [photo_manager](https://pub.dev/packages/photo_manager) are the native integration references. [Google's ML Kit data disclosure](https://developers.google.com/ml-kit/ios-data-disclosure) prompted the user's choice to remove ML Kit.

## Rebranding controls
- [x] Display names and localized permission explanations updated without changing bundle/application IDs, database/schema, storage paths, preference keys or permission-request code. Preservation of runtime state failed during verification as noted below.
- [x] Rebranding introduces no data-reset code, new SDK, permission or signing credential.
- [ ] Verification preservation failed: the native test runner defaulted to uninstalling the shared-ID app during teardown, deleting its simulator preferences. See VERIFICATION.md for recovery status. README native test commands now use `--no-uninstall`; back up app data and prefer a dedicated test simulator.
- [ ] Before TestFlight, complete the source/dependency, signing, privacy and physical-device checks in RELEASE_CHECKLIST.md. A simulator debug build does not validate distribution signing or App Store approval.

## Production hardening — 21 October 2026
The current [release audit](../FINAL_RELEASE_AUDIT.md) and [privacy matrix](../APP_STORE_PRIVACY_MATRIX.md) supersede earlier statements about the absence of purchase SDKs/network services. Optional RevenueCat processing now sends purchase history and an anonymous purchase identifier after billing consent. Screenshots/OCR stay local; SDK diagnostics/automatic attribution collection are disabled. No app analytics/ad/tracking SDK, cloud AI or authentication service is added. Public purchase SDK keys are configuration, not secrets.

Implemented: native least-permission selected import; bounded image/MIME decoding and metadata-free output; filename/symlink guards; request timeouts/coalescing; transactional deduplication; private temporary cleanup; SQLite secure_delete; existing-file iOS protection and Android backup/cleartext restrictions; verified subscription access and expiry/revocation gates; privacy/terms/restore/manage entries; privacy manifest and pinned CI/source audit tooling. None establishes a universal security/erasure guarantee. Actual store billing and device-level privacy behavior remain unverified pending owner configuration/real-device QA.

This pass backed up the full existing app container and left its 12 files byte-for-byte unchanged. Native tests run on separate new simulators with `--no-uninstall`; the historical rebrand incident is not claimed resolved. See docs/RELEASE_VERIFICATION.md for actual final results and docs/MANUAL_RELEASE_TASKS.md for release blockers.

## Later optional-auth/product pass
- [x] Fresh guest does not initialize account services or require registration.
- [x] Provider credentials use Firebase verification; Apple nonce/code revocation path; no tokens/secret keys in application preferences.
- [x] Current-provider reauthentication before linking/deletion; duplicate identities fail safely, no implicit email merge.
- [x] Logout/deletion preserve local library; account-delete confirmation describes retention and store cancellation separately.
- [x] RevenueCat uses Firebase UID only after billing consent, clears stale-user access and serializes identity/store operations; no local Pro boolean.
- [x] Photos status reads do not prompt; only explicit not-determined action requests; denial/restriction keep nonblocking manual use; limited selection management and foreground refresh are implemented.
- [x] Picker/automatic asset identity dedupe and conditional queue claims guard a cross-path import race.
- [ ] Real OAuth/revocation/deletion, RevenueCat identity aliases/restore and signed physical-device data/network/permission checks remain mandatory; see current setup/device guides.
