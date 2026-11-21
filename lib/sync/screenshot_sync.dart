import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/sync/import_media_store.dart';
import '../data/sync/sync_repository.dart';
import '../domain/entry.dart';
import 'classifier.dart';
import 'sync_models.dart';

/// Foreground-only orchestration. One image/OCR operation is ever in flight.
/// Platform operations already running may finish after pause, but their results
/// cannot be committed once their cancellation token is invalidated.
class ScreenshotSync extends ChangeNotifier {
  ScreenshotSync({
    required this.repository,
    required this.library,
    required this.recognizer,
    required this.media,
    required this.fallbackTitle,
    this.prepareStorage,
    bool initiallyForeground = true,
    bool initialAutomationAccess = true,
    this.beforeDelete,
    ScreenshotClassifier? classifier,
    DateTime Function()? clock,
  }) : _foreground = initiallyForeground,
       _automationAllowed = initialAutomationAccess,
       classifier = classifier ?? RuleBasedClassifier(),
       clock = clock ?? DateTime.now;
  final Future<void> Function()? prepareStorage, beforeDelete;
  bool _automationAllowed;
  bool get automationAllowed => _automationAllowed;
  Future<void>? _initializing;
  final SyncRepository repository;
  final ScreenshotLibrary library;
  final LocalTextRecognizer recognizer;
  final ImportMediaStore media;
  final String Function(DateTime) fallbackTitle;
  final ScreenshotClassifier classifier;
  final DateTime Function() clock;
  final sensitive = SensitiveScreenshotDetector();
  SyncConfig config = const SyncConfig();
  SyncActivity activity = SyncActivity.off;
  PhotoAccess permission = PhotoAccess.notDetermined;
  bool permissionKnown = false;
  int pending = 0;
  bool _foreground;
  bool _storageReady = false;
  bool initialized = false, _disposed = false, _again = false;
  bool get supported => library.supported;
  bool get busy =>
      activity == SyncActivity.checking ||
      activity == SyncActivity.scanning ||
      activity == SyncActivity.processing;
  SyncCancellation? _cancellation;
  Future<void>? _running;
  Timer? _retryTimer, _changeTimer;

  // photo_manager exposes creation timestamps at whole-second precision.
  DateTime _boundaryNow() => DateTime.fromMillisecondsSinceEpoch(
    (clock().toUtc().millisecondsSinceEpoch ~/ 1000) * 1000,
    isUtc: true,
  );

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _activity(SyncActivity value) {
    activity = value;
    _notify();
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    try {
      config = await repository.loadConfig();
      await prepareStorage?.call();
      _storageReady = true;
      await media.clearStaging();
      await media.sweep(repository.imageReferenced);
      if (supported) await library.clearCache();
      await repository.recoverInterrupted();
      initialized = true;
      if (!supported) {
        _activity(SyncActivity.unsupported);
        return;
      }
      await _access();
      if (config.enabled) {
        await reconcile();
      } else {
        _activity(SyncActivity.off);
      }
    } catch (_) {
      initialized = true;
      _activity(SyncActivity.error);
    }
  }

  Future<void> _access({bool request = false}) async {
    try {
      permission = await library.access(request: request);
      permissionKnown = true;
    } catch (_) {
      permissionKnown = false;
      rethrow;
    }
  }

  /// Called only after the in-app explanation and explicit enable action.
  Future<void> enable({bool includeExisting = false}) async {
    if (!supported || _disposed || !_automationAllowed) return;
    config = config.copyWith(
      enabled: true,
      since: config.since ?? _boundaryNow(),
      historyRequested: includeExisting || config.historyRequested,
    );
    await repository.saveConfig(config);
    _activity(SyncActivity.checking);
    try {
      await _access();
      if (permission == PhotoAccess.notDetermined) {
        await _access(request: true);
      }
      if (permission.canRead) {
        await repository.retryFailed();
      }
      _notify();
      if (_foreground && config.enabled) {
        unawaited(reconcile());
      } else {
        _activity(SyncActivity.paused);
      }
    } catch (_) {
      _activity(SyncActivity.error);
    }
  }

  Future<void> disable() async {
    config = config.copyWith(enabled: false);
    _cancel(); // Stop immediately, before any asynchronous storage operation.
    _activity(SyncActivity.off);
    await _stopLibrary();
    await repository.saveConfig(config);
    await _running; // Drain current native operation; its result is discarded.
    _activity(SyncActivity.off);
  }

  void _cancel() {
    _cancellation?.cancelled = true;
    _again = false;
    _retryTimer?.cancel();
    _changeTimer?.cancel();
  }

  Future<void> _stopLibrary() async {
    try {
      await library.stopObserving();
    } catch (_) {
      /* State is already off. */
    }
    try {
      await library.cancelLoads();
    } catch (_) {
      /* Results remain cancelled. */
    }
  }

  Future<void> setAutomationAccess(bool allowed) async {
    if (_automationAllowed == allowed) return;
    _automationAllowed = allowed;
    if (!allowed) {
      _cancel();
      await _stopLibrary();
      if (config.enabled) _activity(SyncActivity.paused);
    } else if (initialized && config.enabled && _foreground) {
      await _running;
      await reconcile();
    }
  }

  Future<void> setForeground(bool value) async {
    _foreground = value;
    if (!value) {
      _cancel();
      if (config.enabled) _activity(SyncActivity.paused);
      await _stopLibrary();
    } else if (initialized) {
      await refreshPermission();
      if (!config.enabled) return;
      await _running;
      if (_foreground && config.enabled && !_disposed) await reconcile();
    }
  }

  /// Read-only status refresh. Never shows the native permission popup.
  Future<void> refreshPermission() async {
    if (!supported || _disposed) return;
    try {
      final previous = permission;
      await _access();
      if (permission.canRead &&
          (previous != permission || permission == PhotoAccess.limited)) {
        config = config.copyWith(historyRequested: true);
      }
      if (!permission.canRead) {
        _cancel();
        await _stopLibrary();
      }
      _notify();
    } catch (_) {
      _activity(SyncActivity.error);
    }
  }

  Future<void> importExisting() async {
    if (!config.enabled || !supported || !_automationAllowed) return;
    config = config.copyWith(historyRequested: true);
    await repository.saveConfig(config);
    unawaited(reconcile());
  }

  Future<void> retry() async {
    await repository.retryFailed();
    unawaited(reconcile());
  }

  Future<void> deleteImportedData() async {
    await beforeDelete?.call();
    await disable();
    final reset = SyncConfig(since: _boundaryNow());
    await repository.deleteImportedData(reset);
    config = reset;
    // The database is authoritative; any interrupted file cleanup is swept at
    // next startup. This never touches the user's Photos library.
    await media.deleteAll();
    _storageReady = false;
    if (supported) await library.clearCache();
    pending = 0;
    _notify();
  }

  void _libraryChanged() {
    if (!_foreground || !config.enabled || _disposed) return;
    _changeTimer?.cancel();
    if (permission == PhotoAccess.limited) {
      config = config.copyWith(historyRequested: true);
    }
    _changeTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(reconcile());
    });
  }

  Future<void> reconcile() {
    if (_disposed ||
        !supported ||
        !config.enabled ||
        !_foreground ||
        !_automationAllowed) {
      if (config.enabled && !_automationAllowed) _activity(SyncActivity.paused);
      return Future.value();
    }
    if (_running != null) {
      _again = true;
      return _running!;
    }
    _retryTimer?.cancel();
    final cancellation = SyncCancellation();
    _cancellation = cancellation;
    final future = _drain(cancellation);
    _running = future.whenComplete(() {
      _running = null;
    });
    return _running!;
  }

  Future<void> _drain(SyncCancellation cancellation) async {
    do {
      _again = false;
      _retryTimer?.cancel();
      await _run(cancellation);
    } while (_again &&
        !cancellation.cancelled &&
        !_disposed &&
        config.enabled &&
        _foreground);
  }

  Future<void> _readPermission(SyncCancellation cancellation) async {
    cancellation.check();
    final previousPermission = permission;
    await _access();
    cancellation.check();
    if (permission.canRead && permission != previousPermission) {
      await repository.retryFailed();
      cancellation.check();
    }
    if (!permission.canRead) {
      cancellation.cancelled = true;
      await _stopLibrary();
      _notify();
      throw const SyncCancelled();
    }
  }

  Future<void> _run(SyncCancellation cancellation) async {
    try {
      _activity(SyncActivity.checking);
      if (!_storageReady) {
        await prepareStorage?.call();
        _storageReady = true;
        cancellation.check();
      }
      await _readPermission(cancellation);
      await library.observe(_libraryChanged);
      cancellation.check();
      await repository.recoverInterrupted();
      final includeHistory = config.historyRequested;
      final since = includeHistory
          ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
          : config.lastSuccess?.subtract(const Duration(seconds: 1)) ??
                config.since ??
                clock().toUtc();
      _activity(SyncActivity.scanning);
      await for (final page in library.pages(
        since: since,
        access: permission,
        cancellation: cancellation,
      )) {
        cancellation.check();
        await repository.enqueue(page);
        // Yield between pages so stop/pause controls are never starved.
        await Future<void>.delayed(Duration.zero);
      }
      cancellation.check();
      if (includeHistory) {
        config = config.copyWith(historyRequested: false);
        await repository.saveConfig(config);
      }
      while (true) {
        cancellation.check();
        final batch = await repository.nextBatch(clock());
        if (batch.isEmpty) break;
        for (final job in batch) {
          cancellation.check();
          _activity(SyncActivity.processing);
          await _process(job, cancellation);
        }
      }
      cancellation.check();
      pending = await repository.pendingCount();
      if (pending == 0) {
        config = config.copyWith(lastSuccess: clock().toUtc());
        await repository.saveConfig(config);
      }
      cancellation.check();
      _activity(pending == 0 ? SyncActivity.idle : SyncActivity.waiting);
      final retryAt = await repository.nextRetry();
      if (retryAt != null &&
          _foreground &&
          config.enabled &&
          !cancellation.cancelled) {
        final delay = retryAt.difference(clock().toUtc());
        _retryTimer = Timer(
          delay.isNegative ? const Duration(seconds: 1) : delay,
          () {
            unawaited(reconcile());
          },
        );
      }
    } on SyncCancelled {
      if (!_disposed) {
        _activity(
          !config.enabled
              ? SyncActivity.off
              : !_foreground
              ? SyncActivity.paused
              : SyncActivity.idle,
        );
      }
    } catch (_) {
      // Do not log exceptions: native errors may include photo identifiers.
      if (!cancellation.cancelled) _activity(SyncActivity.error);
    }
  }

  Future<void> _process(
    ScreenshotJob job,
    SyncCancellation cancellation,
  ) async {
    File? staged;
    String? retained;
    var committed = false;
    var phase = 'image';
    try {
      await _readPermission(cancellation);
      if (!await repository.claim(job)) return;
      cancellation.check();
      if (job.assetId == null || job.capturedAt == null) {
        await repository.finish(job, 'missing');
        return;
      }
      final bytes = await library.load(
        ScreenshotAsset(id: job.assetId!, createdAt: job.capturedAt!),
        cancellation,
      );
      cancellation.check();
      staged = await media.stage(job.assetKey, bytes);
      cancellation.check();
      phase = 'ocr';
      final text = await recognizer.recognize(staged.path);
      cancellation.check();
      await _readPermission(cancellation);
      if (text.length > 32000 || sensitive.isSensitive(text)) {
        await repository.finish(job, 'excluded');
        return;
      }
      final hash = sha256.convert(bytes).toString();
      if (await repository.knownHash(hash)) {
        await repository.finish(job, 'duplicate', hash: hash);
        return;
      }
      cancellation.check();
      final proposal = classifier.classify(text);
      final title = proposal.title ?? fallbackTitle(job.capturedAt!.toLocal());
      final notes = text.trim();
      final draft = EntryDraft(
        title: title,
        category: proposal.category,
        description: notes.length > 5000 ? notes.substring(0, 5000) : notes,
        url: proposal.url,
      );
      phase = 'storage';
      retained = await media.retain(job.assetKey, staged);
      cancellation.check();
      committed = await repository.commit(
        job: job,
        draft: draft,
        hash: hash,
        imagePath: retained,
        now: clock(),
        cancellation: cancellation,
      );
    } on SyncCancelled {
      await repository.requeue(job);
      rethrow;
    } on AssetUnavailable catch (e) {
      if (cancellation.cancelled) {
        await repository.requeue(job);
        throw const SyncCancelled();
      }
      await repository.defer(job, clock(), e.reason);
    } catch (_) {
      if (cancellation.cancelled) {
        await repository.requeue(job);
        throw const SyncCancelled();
      }
      await repository.defer(job, clock(), phase);
    } finally {
      // Keep no staged file/OCR cache after success, exclusion, error or pause.
      if (staged != null) {
        try {
          if (await staged.exists()) await staged.delete();
        } catch (_) {
          /* Startup sweeps leftover staging files. */
        }
      }
      if (retained != null && !committed) {
        try {
          await media.remove(retained);
        } catch (_) {
          /* Startup sweeps orphan copies. */
        }
      }
      try {
        await library.clearCache();
      } catch (_) {
        /* Next startup clears it. */
      }
    }
  }

  Future<void> shutdown() async {
    _cancel();
    _foreground = false;
    await _stopLibrary();
    await _running;
    await recognizer.close();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(shutdown());
    super.dispose();
  }
}
