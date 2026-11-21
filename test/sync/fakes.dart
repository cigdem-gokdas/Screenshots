import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:screenshot_cehennemi/sync/sync_models.dart';

class FakeLibrary implements ScreenshotLibrary {
  @override
  bool supported = true;
  PhotoAccess permission = PhotoAccess.authorized;
  PhotoAccess? requestedPermission;
  bool failAccess = false;
  final List<ScreenshotAsset> assets = [];
  final Map<String, String> contents = {};
  final Set<String> cloud = {}, missing = {};
  int accessReads = 0,
      permissionRequests = 0,
      loadCount = 0,
      pageCount = 0,
      observeCount = 0;
  void Function()? changed;
  @override
  Future<PhotoAccess> access({bool request = false}) async {
    accessReads++;
    if (failAccess) throw StateError('permission status unavailable');
    if (request) {
      permissionRequests++;
      permission = requestedPermission ?? permission;
    }
    return permission;
  }

  void add(String id, String content, DateTime date) {
    assets.add(ScreenshotAsset(id: id, createdAt: date));
    contents[id] = content;
  }

  @override
  Stream<List<ScreenshotAsset>> pages({
    required DateTime since,
    required PhotoAccess access,
    required SyncCancellation cancellation,
  }) async* {
    final eligible = assets.where((a) => !a.createdAt.isBefore(since)).toList();
    for (var i = 0; i < eligible.length; i += 50) {
      cancellation.check();
      pageCount++;
      yield eligible.skip(i).take(50).toList();
    }
  }

  @override
  Future<Uint8List> load(
    ScreenshotAsset asset,
    SyncCancellation cancellation,
  ) async {
    cancellation.check();
    loadCount++;
    if (cloud.contains(asset.id)) throw const AssetUnavailable('cloud');
    if (missing.contains(asset.id)) throw const AssetUnavailable('missing');
    return Uint8List.fromList(
      utf8.encode(contents[asset.id]!.isEmpty ? ' ' : contents[asset.id]!),
    );
  }

  @override
  Future<void> observe(void Function() onChange) async {
    observeCount++;
    changed = onChange;
  }

  @override
  Future<void> stopObserving() async {
    changed = null;
  }

  @override
  Future<void> cancelLoads() async {}
  @override
  Future<void> clearCache() async {}
  @override
  Future<void> openSettings() async {}
}

class FakeRecognizer implements LocalTextRecognizer {
  int calls = 0, inFlight = 0, maxInFlight = 0;
  bool fail = false;
  Completer<void>? entered, release;
  @override
  Future<String> recognize(String path) async {
    calls++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    if (entered != null && !entered!.isCompleted) entered!.complete();
    try {
      await release?.future;
      if (fail) throw StateError('Simulated OCR failure');
      return await File(path).readAsString();
    } finally {
      inFlight--;
    }
  }

  @override
  Future<void> close() async {}
}
