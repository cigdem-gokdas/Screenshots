import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../sync/sync_models.dart';

/// Album identity and the asset subtype both enforce screenshot-only reads.
/// No album name, Photos write API, or general library image loader is used.
class PhotoManagerScreenshotLibrary
    implements ScreenshotLibrary, LimitedPhotoAccessManager {
  PhotoManagerScreenshotLibrary({bool Function()? isIOS})
    : _isIOS = isIOS ?? (() => Platform.isIOS);
  final bool Function() _isIOS;
  static const options = PermissionRequestOption(
    iosAccessLevel: IosAccessLevel.readWrite,
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: false,
    ),
  );
  static const screenshotSubtype =
      1 << 19; // PHAssetMediaSubtype.photoScreenshot
  PMCancelToken? _loadToken;
  void Function()? _onChange;
  bool _observing = false;
  Future<void> _observationWork = Future.value();
  @override
  bool get supported => _isIOS();
  @override
  Future<PhotoAccess> access({bool request = false}) async {
    if (!supported) return PhotoAccess.restricted;
    final state = request
        ? await PhotoManager.requestPermissionExtend(requestOption: options)
        : await PhotoManager.getPermissionState(requestOption: options)
              .timeout(const Duration(seconds: 15));
    return switch (state) {
      PermissionState.authorized => PhotoAccess.authorized,
      PermissionState.limited => PhotoAccess.limited,
      PermissionState.denied => PhotoAccess.denied,
      PermissionState.restricted => PhotoAccess.restricted,
      PermissionState.notDetermined => PhotoAccess.notDetermined,
    };
  }

  @override
  Stream<List<ScreenshotAsset>> pages({
    required DateTime since,
    required PhotoAccess access,
    required SyncCancellation cancellation,
  }) async* {
    cancellation.check();
    final filters = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: since.toLocal(),
        max: DateTime.now().add(const Duration(seconds: 1)),
      ),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: true)],
    );
    // Limited grants do not expose smart albums reliably. Fetch only the
    // OS-accessible image metadata and discard all non-screenshot subtypes.
    if (access == PhotoAccess.limited) {
      var page = 0;
      while (true) {
        cancellation.check();
        final assets = await PhotoManager.getAssetListPaged(
          page: page++,
          pageCount: 50,
          type: RequestType.image,
          filterOption: filters,
        );
        cancellation.check();
        if (assets.isEmpty) break;
        yield _eligible(assets, since);
        if (assets.length < 50) break;
      }
      return;
    }
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
      onlyAll: false,
      filterOption: filters,
      pathFilterOption: const PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [PMDarwinAssetCollectionType.smartAlbum],
          subType: [PMDarwinAssetCollectionSubtype.smartAlbumScreenshots],
        ),
      ),
    );
    for (final path in paths) {
      if (path.albumTypeEx?.darwin?.subtype !=
          PMDarwinAssetCollectionSubtype.smartAlbumScreenshots) {
        continue;
      }
      var page = 0;
      while (true) {
        cancellation.check();
        final assets = await path.getAssetListPaged(page: page++, size: 50);
        cancellation.check();
        if (assets.isEmpty) break;
        yield _eligible(assets, since);
        if (assets.length < 50) break;
      }
    }
  }

  List<ScreenshotAsset> _eligible(List<AssetEntity> assets, DateTime since) => [
    for (final asset in assets)
      if (_isScreenshot(asset) &&
          !asset.createDateTime.toUtc().isBefore(since.toUtc()))
        ScreenshotAsset(id: asset.id, createdAt: asset.createDateTime),
  ];
  bool _isScreenshot(AssetEntity asset) =>
      asset.type == AssetType.image && asset.subtype & screenshotSubtype != 0;
  @override
  Future<Uint8List> load(
    ScreenshotAsset asset,
    SyncCancellation cancellation,
  ) async {
    cancellation.check();
    final entity = await AssetEntity.fromId(asset.id);
    if (entity == null || !_isScreenshot(entity)) {
      throw const AssetUnavailable('missing');
    }
    if (!await entity.isLocallyAvailable()) {
      throw const AssetUnavailable('cloud');
    }
    cancellation.check();
    final token = PMCancelToken();
    _loadToken = token;
    try {
      final data = await entity.thumbnailDataWithOption(
        ThumbnailOption.ios(
          size: const ThumbnailSize(1600, 2400),
          quality: 92,
          deliveryMode: DeliveryMode.highQualityFormat,
          resizeMode: ResizeMode.exact,
          resizeContentMode: ResizeContentMode.fit,
        ),
        cancelToken: token,
      );
      cancellation.check();
      if (data == null || data.isEmpty || data.length > 8 * 1024 * 1024) {
        throw const AssetUnavailable('image');
      }
      return data;
    } finally {
      if (_loadToken == token) _loadToken = null;
    }
  }

  void _changed(MethodCall _) {
    _onChange?.call();
  }

  @override
  Future<void> observe(void Function() onChange) {
    _onChange = onChange;
    return _observationWork = _observationWork
        .catchError((Object _) {})
        .then((_) => _observe(onChange));
  }

  Future<void> _observe(void Function() onChange) async {
    _onChange = onChange;
    if (_observing) return;
    _observing = true;
    PhotoManager.addChangeCallback(_changed);
    try {
      await PhotoManager.startChangeNotify();
    } catch (_) {
      PhotoManager.removeChangeCallback(_changed);
      _observing = false;
      rethrow;
    }
  }

  @override
  Future<void> stopObserving() {
    _onChange = null;
    return _observationWork = _observationWork
        .catchError((Object _) {})
        .then((_) => _stopObserving());
  }

  Future<void> _stopObserving() async {
    _onChange = null;
    if (!_observing) return;
    _observing = false;
    PhotoManager.removeChangeCallback(_changed);
    await PhotoManager.stopChangeNotify();
  }

  @override
  Future<void> cancelLoads() async {
    await _loadToken?.cancelRequest();
  }

  @override
  Future<void> clearCache() => PhotoManager.clearFileCache();
  @override
  Future<void> manageLimitedAccess() async {
    if (await access() == PhotoAccess.limited) {
      await PhotoManager.presentLimited();
    }
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();
}

abstract interface class LimitedPhotoAccessManager {
  Future<void> manageLimitedAccess();
}
