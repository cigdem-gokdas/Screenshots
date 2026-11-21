import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/sync/photo_manager_library.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  final since = DateTime.utc(2026, 10, 15);
  Map<String, Object> path(String id, int subtype) => {
    'id': id,
    'name': 'Unrelated localized name',
    'isAll': false,
    'darwinAssetCollectionType': 2,
    'darwinAssetCollectionSubtype': subtype,
  };
  Map<String, Object> asset(String id, int subtype) => {
    'id': id,
    'type': 1,
    'width': 1200,
    'height': 2200,
    'createDt': since.millisecondsSinceEpoch ~/ 1000,
    'subtype': subtype,
  };
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getPermissionState' => 3,
            'requestPermissionExtend' => 4,
            'getAssetPathList' => {
              'data': [path('wrong', 209), path('screenshots', 211)],
            },
            'getAssetListPaged' || 'getAssetsByRange' => {
              'data': [
                asset('screenshot', 1 << 19),
                asset('ordinary-photo', 0),
              ],
            },
            _ => null,
          };
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('full access uses Apple Screenshots subtype rather than localized names and enforces asset subtype', () async {
    final library = PhotoManagerScreenshotLibrary(isIOS: () => true);
    final pages = await library
        .pages(
          since: since,
          access: PhotoAccess.authorized,
          cancellation: SyncCancellation(),
        )
        .toList();
    expect(pages.expand((p) => p).map((a) => a.id), ['screenshot']);
    final arguments =
        calls.singleWhere((c) => c.method == 'getAssetPathList').arguments
            as Map;
    expect(arguments['hasAll'], false);
    expect((arguments['pathOption'] as Map)['darwin'], {
      'type': [2],
      'subType': [211],
    });
    expect(
      (calls.singleWhere((c) => c.method == 'getAssetListPaged').arguments
          as Map)['id'],
      'screenshots',
    );
    expect(calls.any((c) => c.method == 'getThumb'), isFalse);
  });
  test('limited access pages permitted asset metadata and excludes ordinary photos', () async {
    final library = PhotoManagerScreenshotLibrary(isIOS: () => true);
    final pages = await library
        .pages(
          since: since,
          access: PhotoAccess.limited,
          cancellation: SyncCancellation(),
        )
        .toList();
    expect(pages.expand((p) => p).map((a) => a.id), ['screenshot']);
    expect(calls.any((c) => c.method == 'getAssetPathList'), isFalse);
    final args =
        calls.singleWhere((c) => c.method == 'getAssetsByRange').arguments
            as Map;
    expect(args['start'], 0);
    expect(args['end'], 50);
  });
  test(
    'permission checks never request authorization unless explicitly requested',
    () async {
      final library = PhotoManagerScreenshotLibrary(isIOS: () => true);
      expect(await library.access(), PhotoAccess.authorized);
      expect(calls.map((c) => c.method), ['getPermissionState']);
      expect(await library.access(request: true), PhotoAccess.limited);
      expect(calls.last.method, 'requestPermissionExtend');
    },
  );
}
