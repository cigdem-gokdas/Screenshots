import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../data/entry_repository.dart';
import '../domain/entry.dart';
import '../sync/screenshot_sync.dart';
import '../billing/subscription_controller.dart';
import '../importing/selected_import.dart';
import '../data/sync/import_media_store.dart';

Locale resolveLocale(List<Locale>? locales) {
  for (final locale in locales ?? <Locale>[]) {
    if (locale.languageCode == 'tr' || locale.languageCode == 'en') {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('tr');
}

class AppController extends ChangeNotifier {
  AppController(
    this.repository, {
    this.sync,
    this.billing,
    this.importer,
    this.auth,
    this.onboarding,
  }) {
    billing?.addListener(_billingChanged);
    importer?.addListener(_notify);
    sync?.addListener(_notify);
    auth?.addListener(_notify);
    onboarding?.addListener(_notify);
  }
  final ScreenshotSync? sync;
  final SubscriptionController? billing;
  final SelectedImportService? importer;
  final AuthController? auth;
  final OnboardingController? onboarding;
  void _billingChanged() => _notify();

  final EntryRepository repository;

  /// Local image copies; shared by list thumbnails, details and sharing.
  late final ImportMediaStore media = sync?.media ?? ImportMediaStore();
  List<Entry> entries = [];
  final Map<int, Entry> _pendingDeletes = {};
  String? language;
  bool loading = true;
  bool failed = false;
  bool _disposed = false;
  StreamSubscription<List<Entry>>? _subscription;

  Future<void> initialize() async {
    loading = true;
    failed = false;
    _notify();
    await _subscription?.cancel();
    try {
      language = await repository.readLanguage();
      unawaited(billing?.initialize());
      unawaited(auth?.initialize());
      if (sync != null && !sync!.initialized) {
        await sync!.initialize();
      }
      if (_disposed) return;
      _subscription = repository.watchEntries().listen(
        (value) async {
          entries = value;
          try {
            if (onboarding != null && !onboarding!.ready) {
              await onboarding!.initialize(
                existingLibrary:
                    value.isNotEmpty || sync?.config.enabled == true,
              );
            }
          } catch (_) {
            failed = true;
            loading = false;
            _notify();
            return;
          }
          if (_disposed) return;
          loading = false;
          failed = false;
          _notify();
        },
        onError: (Object error) {
          loading = false;
          failed = true;
          _notify();
        },
      );
    } catch (_) {
      loading = false;
      failed = true;
      _notify();
    }
  }

  Future<void> changeLanguage(String? value) async {
    await repository.writeLanguage(value);
    language = value;
    _notify();
  }

  /// Pull-to-refresh: runs a sync scan when sync is on, otherwise reloads.
  Future<void> refresh() async {
    try {
      if (sync?.config.enabled == true) {
        await sync!.reconcile();
      } else {
        final value = await repository.watchEntries().first;
        if (!_disposed) {
          entries = value;
          _notify();
        }
      }
    } catch (_) {
      /* Refresh is best effort; the live stream keeps the list current. */
    }
  }

  /// Deletes right away but keeps the image file so [undoDelete] can restore
  /// it. Call [commitDelete] once the undo window has passed.
  Future<void> softDelete(Entry entry) async {
    final before = entries;
    entries = entries.where((e) => e.id != entry.id).toList();
    _pendingDeletes[entry.id] = entry;
    _notify();
    try {
      await repository.delete(entry.id, keepMedia: true);
    } catch (_) {
      _pendingDeletes.remove(entry.id);
      entries = before;
      _notify();
      rethrow;
    }
  }

  Future<void> undoDelete(Entry entry) async {
    if (_pendingDeletes.remove(entry.id) == null) return;
    await repository.restore(entry);
  }

  Future<void> commitDelete(Entry entry) async {
    final pending = _pendingDeletes.remove(entry.id);
    if (pending != null) await repository.discardMedia(pending.imagePath);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final entry in _pendingDeletes.values) {
      unawaited(repository.discardMedia(entry.imagePath));
    }
    _pendingDeletes.clear();
    billing?.removeListener(_billingChanged);
    billing?.dispose();
    importer?.removeListener(_notify);
    importer?.dispose();
    sync?.removeListener(_notify);
    sync?.dispose();
    auth?.removeListener(_notify);
    auth?.dispose();
    onboarding?.removeListener(_notify);
    onboarding?.dispose();
    _subscription?.cancel();
    super.dispose();
  }
}
