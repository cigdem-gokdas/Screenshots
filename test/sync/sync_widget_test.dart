import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/data/sync/sync_repository.dart';
import 'package:screenshot_cehennemi/sync/screenshot_sync.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';
import 'package:screenshot_cehennemi/ui/app.dart';

import 'fakes.dart';

class _NoFileMedia extends ImportMediaStore {
  @override
  Future<void> clearStaging() async {}
  @override
  Future<void> sweep(Future<bool> Function(String) referenced) async {}
}

void main() {
  testWidgets(
    'onboarding precedes permission, cancel never requests, and switch off stops observation',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final library = FakeLibrary()
        ..permission = PhotoAccess.notDetermined
        ..requestedPermission = PhotoAccess.authorized;
      final sync = ScreenshotSync(
        repository: SyncRepository(db),
        library: library,
        recognizer: FakeRecognizer(),
        media: _NoFileMedia(),
        fallbackTitle: (_) => 'Screenshot',
      );
      final controller = AppController(LocalEntryRepository(db), sync: sync);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.runAsync(() async {
        try {
          await sync.initialize();
          await controller.initialize();
          await tester.pumpWidget(ScreenshotApp(controller: controller));
          await tester.pumpAndSettle();
          expect(library.permissionRequests, 0);
          await tester.tap(find.text('Settings').last);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('automatic-sync-switch')));
          await tester.pumpAndSettle();
          expect(find.text('Find your screenshots?'), findsOneWidget);
          expect(library.permissionRequests, 0);
          await tester.scrollUntilVisible(
            find.text('I’ll Choose'),
            300,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.tap(find.text('I’ll Choose'));
          await tester.pumpAndSettle();
          expect(library.permissionRequests, 0);
          expect(sync.config.enabled, isFalse);
          await tester.tap(find.byKey(const Key('automatic-sync-switch')));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const Key('photo-permission-primary')).hitTestable(),
            250,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('photo-permission-primary')).hitTestable(),
          );
          await tester.pumpAndSettle();
          expect(library.permissionRequests, 1);
          expect(sync.config.enabled, isTrue);
          expect(library.changed, isNotNull);
          await tester.tap(find.byKey(const Key('automatic-sync-switch')));
          await tester.pumpAndSettle();
          expect(sync.config.enabled, isFalse);
          expect(library.changed, isNull);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await sync.shutdown();
          controller.dispose();
          await db.close();
        }
      });
    },
  );
}
