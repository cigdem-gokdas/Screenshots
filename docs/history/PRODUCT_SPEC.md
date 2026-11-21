# Unuttuğum Screenshotlar — automatic local organizer (1.1)

The official product name is **Unuttuğum Screenshotlar** in both Turkish and English; the brand is never translated. Rebranding preserves existing installations, data and the visual design.

## Core experience
After one explicit opt-in and the operating system's photo authorization, accessible new screenshots are discovered, read on device and saved into collections automatically. There is no screenshot picker, mandatory review, correction or per-item confirmation. Optional manual creation, editing, deletion, statuses, search/filtering, all eight collections and Daily Review remain available with real persistent data.

The white/Manrope design, exact category colors, line icons and reduced-motion-aware transitions are preserved. Home shows unobtrusive sync status linking to Settings. Turkish and English cover the entire experience, including the native Photos permission explanation. Unsupported app languages fall back to Turkish; saved overrides still work.

## OCR decision
The user explicitly selected **Apple Vision instead of Google ML Kit** to prioritize strict no-telemetry requirements. Vision runs on device through a small native channel. ML Kit, GoogleDataTransport and related Google native dependencies are absent from the final app. There is no remote classification, content upload, account, analytics SDK or API key.

## Consent and discovery
- Sync is off by default. Onboarding explains access breadth, local processing, imperfect sensitive detection/classification, foreground execution and iCloud deferral before any OS authorization request.
- First enable records a persistent creation-time boundary. New Screenshots Only is the default; the initial boundary is rounded to seconds to match photo_manager's timestamp precision, so an asset from the same second may be included.
- Full access uses Apple's `smartAlbumScreenshots` identity, never a localized album name. Each asset must also have the PhotoKit screenshot media subtype before its bytes are loaded.
- Limited access fetches only permitted image metadata, filters screenshot subtypes, and automatically processes those eligible assets. It cannot discover screenshots outside the granted selection. The app never asks the user to select individual screenshots for import.
- Denied, restricted, not-yet-requested, full and limited access have distinct Settings states. After denial/restriction, Settings links to iOS Settings. Automatic reconciliation checks permission but never prompts again itself.
- iOS grants library access, not access scoped to the Screenshots album. Screenshot-only processing is an application restriction, clearly explained to users.

## Synchronization behavior
- Reconcile on startup if enabled, foreground return and debounced photo_manager library change events while active.
- New-only reconciliation always rechecks the saved boundary; it does not advance a lossy high-water mark that could miss failed or newly accessible assets.
- Import Existing Screenshots is a separate explicit action. It persists the history request until discovery finishes; an interrupted scan safely starts again with duplicate suppression.
- Discovery pages hold at most 50 asset metadata objects. The disk queue reads 12 jobs per batch and processes one bounded image at a time.
- Owned copies are normalized JPEG previews, fitted within 1600×2400 pixels, at most 8 MiB, without copying original EXIF metadata. The original Photos assets are never changed or deleted.
- Stable platform identifiers are digested for deduplication. Eligible non-sensitive image copies also use SHA-256 content fingerprints. Repeated assets and identical normalized copies do not create duplicate entries.
- Likely sensitive OCR output (authentication codes, recovery/seed/private keys, banking/card/account details) is rejected before classification, content hashing or retained copying. Only a digest tombstone remains to avoid re-reading the same excluded asset. No image, OCR text, content hash, raw identifier or capture timestamp is retained for excluded jobs.
- Confident bilingual rules require multiple distinct category cues and a usable observed title. Weak, ambiguous, empty or titleless results go directly to Other with a localized screenshot/date title. A URL is saved only when present in the recognized text and valid. No external metadata is invented. Notes retain up to 5,000 recognized characters.
- Cloud-only assets are deferred until locally available and retried no sooner than 15 minutes later while active; their retry budget is not exhausted. The app does not intentionally initiate iCloud downloads. Other failures retry with bounded backoff, up to three attempts, then remain visible as waiting work with a Retry action. Access expansion, re-enabling, or a fresh enabled startup also retries previously failed work.
- Last Successful Sync means a completed discovery pass with no pending/failed jobs. Partial imports still refresh collections and Daily Review immediately.

## Stopping, revocation and deletion
Disabling invalidates current work immediately, removes callbacks, stops notifications, cancels load requests and retry/debounce timers, and drains an already-running native OCR call. Its result cannot commit after cancellation. The setting is persisted; no future automatic work runs while off. Foreground resume reconciles missed jobs only while enabled.

Permission revocation stops observation and discards in-flight results before persistence. Already imported app-local entries remain until the user deletes them. Deleting one imported entry removes its owned copy while retaining a digest/fingerprint tombstone so it is not silently imported again. Delete Imported Screenshot Data turns sync off, removes imported entries, owned copies, recognized text and the import ledger, and resets the boundary. Manual entries remain. An explicit future historical import can import those assets again.

## Daily Review
Saved today uses the entry's local creation/import date, not the original capture date. Counts include manual and imported entries. Still to do and Completed are inventory totals. Distribution includes all eight categories and all statuses. Revisit lists unfinished entries untouched since local midnight seven calendar days ago. Suggestions select a real saved item deterministically; no remote AI is involved. Existing tap-through filters and details remain functional.

## Practical limits
There is no continuous background/terminated-app monitoring, background entitlement or execution workaround. An already running Vision call cannot be forcibly interrupted; its result is discarded on pause/off. A killed process can leave an app-private staging file until the next startup sweep. Sensitive detection and classification are heuristics with false positives and false negatives; they are not security guarantees. Deletion is not certified secure erasure. iOS backup exclusion and file-protection attributes are requested for imported storage and the database; OS internals and physical-device behavior still need release validation.

## Android scope
Manual features remain cross-platform. Automatic photo sync is deliberately disabled on Android until broad-photo-access eligibility has been reviewed and validated for Google Play. Manifest merger directives remove broad photo permissions contributed by plugins. No Android photo authorization is requested.

## Still deferred
Optional remote AI assistance and reminder notifications. Physical-iPhone verification, release signing, store declarations and Android SDK/device build verification are release tasks, not claimed complete.

## Production hardening / monetization — 21 October 2026
Free system-picker imports now precede optional broader access: on iOS, PHPicker sends only selected file representations to bounded local normalization, Vision OCR and the existing classifier. Android uses Photo Picker/document selection and manual organization; it requests no broad media access. Up to 10 selections per batch is a local resource bound, not a paid cloud quota.

Pro is an optional monthly/yearly RevenueCat/store subscription with verified `pro` access. It increases iOS manual selection batches from 10 to 50; basic foreground automatic discovery is free. Saved data, selected imports, local iOS analysis, editing/deletion/search/review are free. There is no launch paywall, account requirement, cloud-AI request or advertised cloud credit allowance. Expired/unverified Pro removes the larger manual batch allowance without pausing free discovery or deleting entries. Android Pro sales are blocked until an Android Pro benefit exists. Real store configuration and device tests remain required.

Settings includes privacy/terms summaries, hosted-URL entry points, upgrade/restore/manage and Pro status. Purchases remain disabled without real public SDK/legal configuration. See the current docs folder for complete behavior, limits, privacy and release tasks.

## Focused product/auth update — 21 October 2026
Editorial first-run scenes (saved/lost → meaning → organization) end in a compact choice. Primary explicitly requests Photos access only if undetermined; secondary completes onboarding and opens the system picker. Completion is persisted in the existing preference table; established libraries skip and record completion. Denied/restricted states never trigger repeated native prompts. Limited access offers management of Apple’s exposed selection. The picker remains available independently. Permission refreshes on foreground/Settings return. Automatic discovery loads only screenshot candidates; initial grant includes available history and later full-access scans use a one-second-overlap watermark. Limited selection changes can include older assets and reconcile history through the dedupe ledger. Optional sync can still be paused explicitly.

Google/Apple accounts are optional via Firebase Auth; no anonymous cloud account is created for a local guest. Firebase UID links subscription identity only. Linking reauthenticates and does not auto-merge conflicting accounts; logout/deletion never deletes the installation’s library. Delete Account confirms local retention, reauthenticates, revokes fresh Apple authorization where applicable and deletes Firebase Auth account. No cloud screenshot backup exists. The existing four destinations retain meaning/state in an accessible floating dock. Current audit/setup/device guides live in docs/.
