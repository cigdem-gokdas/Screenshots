import 'dart:convert';
import 'dart:typed_data';

import '../domain/entry.dart';

enum PhotoAccess { notDetermined, authorized, limited, denied, restricted }

extension PhotoAccessValue on PhotoAccess {
  bool get canRead =>
      this == PhotoAccess.authorized || this == PhotoAccess.limited;
}

enum SyncActivity {
  off,
  checking,
  scanning,
  processing,
  idle,
  waiting,
  paused,
  error,
  unsupported,
}

class SyncConfig {
  const SyncConfig({
    this.enabled = false,
    this.since,
    this.historyRequested = false,
    this.lastSuccess,
  });
  final bool enabled, historyRequested;
  final DateTime? since, lastSuccess;
  SyncConfig copyWith({
    bool? enabled,
    DateTime? since,
    bool? historyRequested,
    DateTime? lastSuccess,
  }) => SyncConfig(
    enabled: enabled ?? this.enabled,
    since: since ?? this.since,
    historyRequested: historyRequested ?? this.historyRequested,
    lastSuccess: lastSuccess ?? this.lastSuccess,
  );
  String encode() => jsonEncode({
    'enabled': enabled,
    'since': since?.toUtc().toIso8601String(),
    'history': historyRequested,
    'lastSuccess': lastSuccess?.toUtc().toIso8601String(),
  });
  factory SyncConfig.decode(String? raw) {
    if (raw == null) return const SyncConfig();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return SyncConfig(
      enabled: data['enabled'] == true,
      since: DateTime.tryParse(data['since'] as String? ?? ''),
      historyRequested: data['history'] == true,
      lastSuccess: DateTime.tryParse(data['lastSuccess'] as String? ?? ''),
    );
  }
}

class ScreenshotAsset {
  const ScreenshotAsset({required this.id, required this.createdAt});
  final String id;
  final DateTime createdAt;
}

class SyncCancellation {
  bool cancelled = false;
  void check() {
    if (cancelled) throw const SyncCancelled();
  }
}

class SyncCancelled implements Exception {
  const SyncCancelled();
}

class AssetUnavailable implements Exception {
  const AssetUnavailable(this.reason);
  final String
  reason; // An allowlisted code, never platform errors or OCR text.
}

abstract interface class ScreenshotLibrary {
  bool get supported;
  Future<PhotoAccess> access({bool request = false});
  Stream<List<ScreenshotAsset>> pages({
    required DateTime since,
    required PhotoAccess access,
    required SyncCancellation cancellation,
  });
  Future<Uint8List> load(ScreenshotAsset asset, SyncCancellation cancellation);
  Future<void> observe(void Function() onChange);
  Future<void> stopObserving();
  Future<void> cancelLoads();
  Future<void> clearCache();
  Future<void> openSettings();
}

abstract interface class LocalTextRecognizer {
  Future<String> recognize(String localPath);
  Future<void> close();
}

class Classification {
  const Classification({required this.category, this.title, this.url = ''});
  final EntryCategory category;
  final String? title;
  final String url;
}

abstract interface class ScreenshotClassifier {
  Classification classify(String text);
}
