import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/sync/import_media_store.dart';
import '../data/sync/sync_repository.dart';
import '../data/sync/vision_recognizer.dart';
import '../domain/entry.dart';
import '../sync/classifier.dart';
import '../sync/sync_models.dart';

abstract interface class SelectedImagePicker {
  Future<List<String>> pick();
  Future<void> discard(String path);
}

abstract interface class SelectedAssetIdentity {
  Future<String?> assetIdFor(String path);
}

/// True only when [path] canonicalizes to a regular file strictly inside
/// `<temp>/selected_imports` (symlinks and `..` resolved on both sides).
Future<bool> isInsideSelectedImports(String path, Directory temporary) async {
  try {
    if (await FileSystemEntity.isLink(path)) return false;
    final base = await Directory(p.join(temporary.path, 'selected_imports'))
        .resolveSymbolicLinks();
    final target = p.normalize(await File(path).resolveSymbolicLinks());
    return p.isWithin(p.normalize(base), target);
  } catch (_) {
    return false;
  }
}

class SystemImagePicker implements SelectedImagePicker, SelectedAssetIdentity {
  SystemImagePicker({this.limit, this.tempRoot});
  final int Function()? limit;
  final Future<Directory> Function()? tempRoot;
  @override
  Future<String?> assetIdFor(String path) async => Platform.isIOS
      ? await VisionLocalTextRecognizer.channel.invokeMethod<String>(
          'selectedAssetId',
          {'path': path},
        )
      : null;
  @override
  Future<List<String>> pick() async =>
      await VisionLocalTextRecognizer.channel.invokeListMethod<String>(
        'pickImages',
        {'limit': (limit?.call() ?? 10).clamp(1, 50)},
      ) ??
      [];
  @override
  Future<void> discard(String path) async {
    // Only files returned by the picker (its private cache copies) reach here.
    final file = File(path);
    if (!await file.exists()) return;
    final root = (tempRoot ?? getTemporaryDirectory)();
    final expected = await isInsideSelectedImports(path, await root);
    if (expected) await file.delete();
  }
}

class NormalizedImage {
  const NormalizedImage(this.bytes, {this.png = false});
  final Uint8List bytes;
  final bool png;
}

typedef NormalizeImage = Future<NormalizedImage> Function(String);

Future<NormalizedImage> normalizeSelectedImage(String path) async {
  final file = File(path);
  if (await file.length() > 20 * 1024 * 1024) {
    throw const AssetUnavailable('image');
  }
  if (Platform.isIOS) {
    final bytes = await VisionLocalTextRecognizer.channel
        .invokeMethod<Uint8List>('normalizeImage', {'path': path})
        .timeout(const Duration(seconds: 30));
    if (bytes == null || bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw const AssetUnavailable('image');
    }
    return NormalizedImage(bytes);
  }
  // Android picker imports work without broad storage permission. Re-encoding
  // from pixels drops EXIF/location; OCR remains iOS-only in this release.
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 80000000 ||
        descriptor.width <= 0 ||
        descriptor.height <= 0) {
      throw const AssetUnavailable('image');
    }
    final ratio = [
      1.0,
      1600 / descriptor.width,
      2400 / descriptor.height,
    ].reduce((a, b) => a < b ? a : b);
    codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * ratio).round().clamp(1, 1600),
      targetHeight: (descriptor.height * ratio).round().clamp(1, 2400),
    );
    image = (await codec.getNextFrame()).image;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    if (bytes.length > 8 * 1024 * 1024) throw const AssetUnavailable('image');
    return NormalizedImage(bytes, png: true);
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

class ImportSummary {
  const ImportSummary({
    this.imported = 0,
    this.duplicates = 0,
    this.skipped = 0,
    this.failed = 0,
  });
  final int imported, duplicates, skipped, failed;
}

class SelectedImportService extends ChangeNotifier {
  SelectedImportService({
    required this.picker,
    required this.normalize,
    required this.repository,
    required this.media,
    required this.fallbackTitle,
    required this.prepare,
    this.recognizer,
    this.batchLimit,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final SelectedImagePicker picker;
  final NormalizeImage normalize;
  final SyncRepository repository;
  final ImportMediaStore media;
  final LocalTextRecognizer? recognizer;
  final int Function()? batchLimit;
  final String Function(DateTime) fallbackTitle;
  final Future<void> Function() prepare;
  final DateTime Function() clock;
  bool busy = false, picking = false, _disposed = false;
  SyncCancellation? _cancellation;
  Future<ImportSummary>? _running;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void cancel() => _cancellation?.cancelled = true;
  void pause() {
    if (!picking) cancel();
  }

  Future<void> cancelAndDrain() async {
    cancel();
    await _running;
  }

  Future<ImportSummary> import() =>
      _running ??= _import().whenComplete(() => _running = null);
  Future<ImportSummary> _import() async {
    busy = true;
    _notify();
    List<String> paths = [];
    var imported = 0, duplicates = 0, skipped = 0, failed = 0;
    try {
      final token = SyncCancellation();
      _cancellation = token;
      await prepare();
      token.check();
      picking = true;
      try {
        paths = await picker.pick();
      } finally {
        picking = false;
      }
      if (paths.isEmpty || _disposed) return const ImportSummary();
      token.check();
      for (final path in paths.take((batchLimit?.call() ?? 10).clamp(1, 50))) {
        if (token.cancelled) break;
        File? staged;
        String? retained;
        var committed = false;
        try {
          final source = picker;
          final id = source is SelectedAssetIdentity
              ? await (source as SelectedAssetIdentity).assetIdFor(path)
              : null;
          final sourceKey = id == null ? null : assetKey(id);
          if (sourceKey != null && await repository.assetHandled(sourceKey)) {
            duplicates++;
            continue;
          }
          final normalized = await normalize(path);
          token.check();
          final hash = sha256.convert(normalized.bytes).toString();
          if (await repository.knownHash(hash)) {
            duplicates++;
            continue;
          }
          final key =
              sourceKey ??
              sha256.convert('selected:$hash'.codeUnits).toString();
          staged = await media.stage(
            key,
            normalized.bytes,
            png: normalized.png,
          );
          final text = recognizer == null
              ? ''
              : await recognizer!.recognize(staged.path);
          token.check();
          if (text.length > 32000 ||
              SensitiveScreenshotDetector().isSensitive(text)) {
            skipped++;
            continue;
          }
          final proposal = RuleBasedClassifier().classify(text);
          final now = clock();
          final notes = text.trim();
          final draft = EntryDraft(
            title: proposal.title ?? fallbackTitle(now),
            category: proposal.category,
            description: notes.length > 5000 ? notes.substring(0, 5000) : notes,
            url: proposal.url,
          );
          retained = await media.retain(key, staged);
          token.check();
          committed = await repository.commitSelected(
            key: key,
            hash: hash,
            draft: draft,
            imagePath: retained,
            now: now,
            cancellation: token,
          );
          if (committed) {
            imported++;
          } else {
            duplicates++;
          }
        } on SyncCancelled {
          break;
        } catch (_) {
          failed++;
        } finally {
          if (staged != null) {
            try {
              if (await staged.exists()) await staged.delete();
            } catch (_) {}
          }
          if (retained != null && !committed) {
            try {
              await media.remove(retained);
            } catch (_) {}
          }
        }
      }
    } on SyncCancelled {
      // User cancellation is not a failed image.
    } catch (_) {
      failed++;
    } finally {
      // Picker never supplies original Photos assets: discard only cache copies.
      for (final path in paths) {
        try {
          await picker.discard(path);
        } catch (_) {}
      }
      busy = false;
      _cancellation = null;
      _notify();
    }
    return ImportSummary(
      imported: imported,
      duplicates: duplicates,
      skipped: skipped,
      failed: failed,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
