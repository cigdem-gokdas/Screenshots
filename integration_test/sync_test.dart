import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/data/sync/photo_manager_library.dart';
import 'package:screenshot_cehennemi/data/sync/sync_repository.dart';
import 'package:screenshot_cehennemi/data/sync/vision_recognizer.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/domain/review.dart';
import 'package:screenshot_cehennemi/sync/screenshot_sync.dart';
import 'package:screenshot_cehennemi/sync/classifier.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';
import 'package:screenshot_cehennemi/ui/app.dart';

import '../test/sync/fakes.dart';

import 'package:flutter/services.dart';
import 'package:screenshot_cehennemi/importing/selected_import.dart';

class FixtureLibrary extends FakeLibrary {
  FixtureLibrary(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List> load(
    ScreenshotAsset asset,
    SyncCancellation cancellation,
  ) async {
    cancellation.check();
    return bytes;
  }
}

class CountingVision implements LocalTextRecognizer {
  final vision = VisionLocalTextRecognizer();
  int calls = 0;
  @override
  Future<String> recognize(String path) {
    calls++;
    return vision.recognize(path);
  }

  @override
  Future<void> close() => vision.close();
}

Future<Uint8List> recipeImage({
  String text = 'Lemon Pasta\n\nRecipe\nIngredients\n\n200 g pasta\n2 tablespoons olive oil\n1 lemon\n\nCook pasta for 10 minutes.',
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black, fontSize: 58, height: 1.6),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 1080);
  painter.paint(canvas, const Offset(60, 80));
  final picture = recorder.endRecording();
  final image = await picture.toImage(1200, 1800);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  painter.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native Vision OCR imports without review, persists, deduplicates and preserves manual data on wipe',
    (tester) async {
      final root = await Directory((await getTemporaryDirectory()).path)
          .createTemp('native-sync-verification-');
      final bytes = await recipeImage();
      final now = DateTime.now().toUtc();
      final source = FixtureLibrary(bytes)
        ..permission = PhotoAccess.notDetermined
        ..requestedPermission = PhotoAccess.authorized
        ..add('local-integration-fixture', '', now);
      final media = ImportMediaStore(
        supportDirectory: () async => root,
        temporaryDirectory: () async => root,
      );
      AppDatabase database() => AppDatabase(
        driftDatabase(
          name: 'sync_verification',
          native: DriftNativeOptions(
            databasePath: () async => '${root.path}/verification.sqlite',
          ),
        ),
      );
      var db = database();
      var ocr = CountingVision();
      ScreenshotSync service(AppDatabase database, CountingVision recognizer) =>
          ScreenshotSync(
            repository: SyncRepository(database),
            library: source,
            recognizer: recognizer,
            media: media,
            clock: () => now,
            fallbackTitle: (_) => 'Screenshot',
            prepareStorage: () => VisionLocalTextRecognizer.channel
                .invokeMethod<void>('protectStorage', {
                  'paths': [root.path],
                }),
          );
      var sync = service(db, ocr);
      var controller = AppController(
        LocalEntryRepository(db, media: media),
        sync: sync,
      );
      try {
        await controller.repository.writeLanguage('en');
        await sync.initialize();
        await controller.initialize();
        await tester.pumpWidget(ScreenshotApp(controller: controller));
        await tester.pumpAndSettle();
        expect(find.text('Unuttuğum Screenshotlar'), findsOneWidget);
        await tester.tap(find.text('Settings').last);
        await tester.pumpAndSettle();
        // Exercise the same official brand in both languages, using only this
        // test's isolated SQLite database, never the installed user's settings.
        await tester.scrollUntilVisible(
          find.text('Türkçe').hitTestable(),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Türkçe'));
        await tester.pumpAndSettle();
        expect(find.text('Unuttuğum Screenshotlar'), findsAtLeastNWidgets(1));
        expect(await controller.repository.readLanguage(), 'tr');
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(find.text('Unuttuğum Screenshotlar'), findsAtLeastNWidgets(1));
        expect(await controller.repository.readLanguage(), 'en');
        await tester.scrollUntilVisible(
          find.byKey(const Key('automatic-sync-switch')).hitTestable(),
          -300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('automatic-sync-switch')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('automatic-sync-switch')));
        await tester.pumpAndSettle();
        expect(source.permissionRequests, 0);
        await tester.scrollUntilVisible(
          find.byKey(const Key('photo-permission-primary')).hitTestable(),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('photo-permission-primary')));
        await tester.pumpAndSettle();
        for (var i = 0; !sync.config.enabled && i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(sync.config.enabled, isTrue);
        await sync.reconcile();
        await tester.pumpAndSettle();
        final imported =
            (await controller.repository.watchEntries().first).single;
        expect(imported.category, EntryCategory.recipes);
        expect(imported.title.toLowerCase(), contains('lemon pasta'));
        expect(imported.description.toLowerCase(), contains('ingredients'));
        expect(await media.image(imported.imagePath), isNotNull);
        expect(ocr.calls, 1);
        expect(source.permissionRequests, 1);
        expect(DailyReview([imported], now).savedToday, 1);
        final turkishFile = File('${root.path}/turkish-fixture.png');
        await turkishFile.writeAsBytes(
          await recipeImage(
            text: 'Mercimek Çorbası\n\nTarifi\nMalzemeler\n\n2 yemek kaşığı zeytinyağı\n1 bardak mercimek',
          ),
        );
        final turkishText = await VisionLocalTextRecognizer().recognize(
          turkishFile.path,
        );
        expect(
          RuleBasedClassifier().classify(turkishText).category,
          EntryCategory.recipes,
        );
        await sync.reconcile();
        expect(ocr.calls, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await sync.shutdown();
        controller.dispose();
        await db.close();
        db = database();
        ocr = CountingVision();
        sync = service(db, ocr);
        controller = AppController(
          LocalEntryRepository(db, media: media),
          sync: sync,
        );
        await sync.initialize();
        expect(ocr.calls, 0);
        expect(
          (await controller.repository.watchEntries().first).single.title,
          imported.title,
        );
        expect(
          (await controller.repository.watchEntries().first).single.imagePath,
          imported.imagePath,
        );
        await controller.repository.save(
          const EntryDraft(
            title: 'Manual entry survives',
            category: EntryCategory.ideas,
          ),
        );
        await sync.deleteImportedData();
        expect(
          (await controller.repository.watchEntries().first).single.title,
          'Manual entry survives',
        );
        expect(await media.image(imported.imagePath), isNull);
        expect(source.changed, isNull);
        expect(sync.config.enabled, isFalse);
        // Verify the real photo_manager bridge can read permission state without
        // presenting a prompt or touching any Photos content in this fixture test.
        expect(
          await PhotoManagerScreenshotLibrary().access(),
          isA<PhotoAccess>(),
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await sync.shutdown();
        controller.dispose();
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native image normalization bounds pixels and rejects corrupt or out-of-sandbox inputs',
    (tester) async {
      final root = await Directory((await getTemporaryDirectory()).path)
          .createTemp('bounded-image-verification-');
      try {
        final input = File('${root.path}/selected.png');
        await input.writeAsBytes(await recipeImage());
        final normalized = await normalizeSelectedImage(input.path);
        expect(normalized.bytes.take(2), [0xff, 0xd8]);
        final codec = await ui.instantiateImageCodec(normalized.bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width <= 1600, true);
        expect(frame.image.height <= 2400, true);
        frame.image.dispose();
        codec.dispose();
        final corrupt = File('${root.path}/corrupt.jpg');
        await corrupt.writeAsBytes([1, 2, 3, 4]);
        await expectLater(
          normalizeSelectedImage(corrupt.path),
          throwsA(isA<PlatformException>()),
        );
        await expectLater(
          VisionLocalTextRecognizer().recognize('/etc/passwd'),
          throwsA(isA<PlatformException>()),
        );
        final oversized = File('${root.path}/oversized.png');
        final handle = await oversized.open(mode: FileMode.write);
        await handle.truncate(20 * 1024 * 1024 + 1);
        await handle.close();
        await expectLater(
          normalizeSelectedImage(oversized.path),
          throwsA(isA<AssetUnavailable>()),
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
