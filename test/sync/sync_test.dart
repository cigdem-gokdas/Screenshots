import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/data/sync/sync_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/sync/screenshot_sync.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late SyncRepository repo;
  late FakeLibrary library;
  late FakeRecognizer ocr;
  late ImportMediaStore media;
  late ScreenshotSync sync;
  late Directory directory;
  var now = DateTime.utc(2026, 10, 15, 12);
  final before = DateTime.utc(2026, 10, 1);
  setUp(() async {
    now = DateTime.utc(2026, 10, 15, 12);
    db = AppDatabase(NativeDatabase.memory());
    repo = SyncRepository(db);
    library = FakeLibrary();
    ocr = FakeRecognizer();
    directory = await Directory.systemTemp.createTemp('screenshot-sync-test-');
    media = ImportMediaStore(
      supportDirectory: () async => directory,
      temporaryDirectory: () async => directory,
    );
    sync = ScreenshotSync(
      repository: repo,
      library: library,
      recognizer: ocr,
      media: media,
      clock: () => now,
      fallbackTitle: (_) => 'Screenshot',
    );
  });
  tearDown(() async {
    await sync.shutdown();
    sync.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<List<Entry>> entries() =>
      LocalEntryRepository(db).watchEntries().first;
  Future<void> enable() async {
    await sync.initialize();
    await sync.enable();
    await sync.reconcile();
  }

  test('status read never prompts or imports before explicit enable; existing default preserved', () async {
    library.add('old', 'Old movie\nIMDb\nDirector', before);
    await sync.initialize();
    expect(library.accessReads, 1);
    expect(library.loadCount, 0);
    await sync.enable();
    await sync.reconcile();
    expect(library.permissionRequests, 0);
    expect(await entries(), isEmpty);
    library.add(
      'new',
      'Lemon Pasta\nRecipe\nIngredients',
      now.add(const Duration(seconds: 1)),
    );
    now = now.add(const Duration(seconds: 2));
    await sync.reconcile();
    expect((await entries()).single.category, EntryCategory.recipes);
    expect((await entries()).single.title, 'Lemon Pasta');
  });
  test('history action imports old finds; stable IDs and content hashes suppress duplicates', () async {
    library.add('old', 'Lemon Pasta\nRecipe\nIngredients', before);
    await enable();
    await sync.importExisting();
    await sync.reconcile();
    expect((await entries()).length, 1);
    library.add('copy', 'Lemon Pasta\nRecipe\nIngredients', now);
    await sync.reconcile();
    await sync.reconcile();
    expect((await entries()).length, 1);
    expect(ocr.calls, 2); // Same identifier was not processed twice.
    expect(await repo.pendingCount(), 0);
    expect(sync.config.historyRequested, isFalse);
  });
  test(
    'unreliable screenshots go directly to Other without fabricated metadata',
    () async {
      library.add('empty', '', now);
      await enable();
      final entry = (await entries()).single;
      expect(entry.category, EntryCategory.other);
      expect(entry.title, 'Screenshot');
      expect(entry.url, '');
      expect(entry.description, '');
      expect(entry.imagePath, isNotNull);
    },
  );
  test('sensitive images/text/hash are not retained; minimal digest tombstone suppresses repeats', () async {
    library.add('secret', 'Your verification code is 123456\nBanking', now);
    await enable();
    await sync.reconcile();
    expect(await entries(), isEmpty);
    expect(ocr.calls, 1);
    final job = (await db.select(db.screenshotJobs).get()).single;
    expect(job.state, 'excluded');
    expect(job.assetId, isNull);
    expect(job.capturedAt, isNull);
    expect(job.contentHash, isNull);
    expect(
      await directory.list(recursive: true).where((f) => f is File).length,
      0,
    );
  });
  test(
    'denied/restricted/limited permission changes never prompt automatically',
    () async {
      library.permission = PhotoAccess.denied;
      library.add('limited', 'Dune\nISBN\nPaperback', now);
      await enable();
      expect(await entries(), isEmpty);
      expect(library.changed, isNull);
      library.permission = PhotoAccess.restricted;
      await sync.reconcile();
      expect(await entries(), isEmpty);
      library.permission = PhotoAccess.limited;
      await sync.setForeground(true);
      expect((await entries()).single.category, EntryCategory.reading);
      expect(library.permissionRequests, 0);
      library.permission = PhotoAccess.denied;
      await sync.reconcile();
      expect(library.changed, isNull);
    },
  );
  test('revocation during OCR discards result and resumes queued work after access returns', () async {
    library.add('a', 'Lemon Pasta\nRecipe\nIngredients', now);
    ocr.entered = Completer();
    ocr.release = Completer();
    await sync.initialize();
    await sync.enable();
    await ocr.entered!.future;
    library.permission = PhotoAccess.denied;
    ocr.release!.complete();
    await sync.reconcile();
    expect(await entries(), isEmpty);
    expect(library.changed, isNull);
    library.permission = PhotoAccess.authorized;
    await sync.reconcile();
    expect((await entries()).length, 1);
  });
  test('turning off during OCR cancels commit and prevents subsequent observation/import', () async {
    library.add('a', 'Lemon Pasta\nRecipe\nIngredients', now);
    library.add('b', 'Dune\nISBN\nPaperback', now);
    ocr.entered = Completer();
    ocr.release = Completer();
    await sync.initialize();
    await sync.enable();
    await ocr.entered!.future;
    final stopped = sync.disable();
    expect(sync.config.enabled, isFalse);
    ocr.release!.complete();
    await stopped;
    await sync.reconcile();
    await sync.setForeground(true);
    expect(await entries(), isEmpty);
    expect(ocr.calls, 1);
    expect(library.changed, isNull);
    expect((await repo.loadConfig()).enabled, isFalse);
  });
  test('foreground pause cancels and foreground resume reconciles missed screenshots', () async {
    await enable();
    await sync.setForeground(false);
    expect(library.changed, isNull);
    library.add('missed', 'Lemon Pasta\nRecipe\nIngredients', now);
    expect(await entries(), isEmpty);
    await sync.setForeground(true);
    expect((await entries()).length, 1);
  });
  test('interrupted processing is recovered without duplicate entries or lost jobs', () async {
    library.add('interrupted', 'Dune\nISBN\nPaperback', now);
    await repo.saveConfig(SyncConfig(enabled: true, since: before));
    await repo.enqueue(library.assets);
    await repo.claim((await repo.nextBatch(now)).single);
    await sync.initialize();
    expect((await entries()).length, 1);
    expect((await db.select(db.screenshotJobs).get()).single.state, 'done');
    await sync.reconcile();
    expect((await entries()).length, 1);
  });
  test('cloud-only assets are deferred without exhausting retries and recover when local', () async {
    library.add('cloud', 'Dune\nISBN\nPaperback', now);
    library.cloud.add('cloud');
    await enable();
    expect(await entries(), isEmpty);
    expect(sync.activity, SyncActivity.waiting);
    expect(sync.config.lastSuccess, isNull);
    expect((await db.select(db.screenshotJobs).get()).single.attempts, 0);
    now = now.add(const Duration(minutes: 16));
    library.cloud.clear();
    await sync.reconcile();
    expect((await entries()).length, 1);
    expect(sync.config.lastSuccess, isNotNull);
  });
  test(
    'partial failures retry with backoff and recover after bounded failures',
    () async {
      library.add('missing', 'Dune\nISBN\nPaperback', now);
      library.missing.add('missing');
      library.add('good', 'Lemon Pasta\nRecipe\nIngredients', now);
      await enable();
      expect((await entries()).length, 1);
      for (var i = 0; i < 2; i++) {
        now = now.add(const Duration(minutes: 5));
        await sync.reconcile();
      }
      expect(
        (await db.select(db.screenshotJobs).get())
            .where((j) => j.state == 'failed')
            .length,
        1,
      );
      library.missing.clear();
      await sync.retry();
      await sync.reconcile();
      expect((await entries()).length, 2);
    },
  );
  test('individual deletion does not trigger reimport; full wipe preserves manual entries', () async {
    library.add('a', 'Lemon Pasta\nRecipe\nIngredients', now);
    await enable();
    final local = LocalEntryRepository(db, media: media);
    await local.delete((await entries()).single.id);
    await sync.reconcile();
    expect(await entries(), isEmpty);
    library.add('b', 'Dune\nISBN\nPaperback', now);
    await sync.reconcile();
    await local.save(
      const EntryDraft(title: 'Manual idea', category: EntryCategory.ideas),
    );
    await sync.deleteImportedData();
    expect((await entries()).single.title, 'Manual idea');
    expect(await db.select(db.screenshotJobs).get(), isEmpty);
    expect(sync.config.enabled, isFalse);
    expect(sync.config.lastSuccess, isNull);
    expect(
      await directory.list(recursive: true).where((f) => f is File).length,
      0,
    );
  });
  test('large galleries page discovery and never process more than one image at a time', () async {
    for (var i = 0; i < 125; i++) {
      library.add('asset-$i', 'Find $i', now);
    }
    await enable();
    expect(library.pageCount, greaterThanOrEqualTo(3));
    expect(ocr.maxInFlight, 1);
    expect((await entries()).length, 125);
  });
  test('enabled cold startup while inactive waits for foreground before processing', () async {
    library.add('cold', 'Lemon Pasta\nRecipe\nIngredients', now);
    await repo.saveConfig(SyncConfig(enabled: true, since: before));
    await sync.setForeground(false);
    await sync.initialize();
    expect(ocr.calls, 0);
    expect(library.changed, isNull);
    await sync.setForeground(true);
    expect((await entries()).length, 1);
  });

  test('permission expansion automatically retries previously inaccessible failed assets', () async {
    library.add('limited-missing', 'Lemon Pasta\nRecipe\nIngredients', now);
    library.permission = PhotoAccess.limited;
    library.missing.add('limited-missing');
    await enable();
    for (var i = 0; i < 2; i++) {
      now = now.add(const Duration(minutes: 5));
      await sync.reconcile();
    }
    expect((await db.select(db.screenshotJobs).get()).single.state, 'failed');
    library.permission = PhotoAccess.authorized;
    library.missing.clear();
    await sync.reconcile();
    expect((await entries()).length, 1);
  });
}
