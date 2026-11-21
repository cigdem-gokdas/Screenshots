import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/data/sync/sync_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/importing/selected_import.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';

import '../sync/fakes.dart';

class FakePicker implements SelectedImagePicker, SelectedAssetIdentity {
  String? sourceId;
  @override
  Future<String?> assetIdFor(String path) async => sourceId;
  int calls = 0;
  List<String> paths = ['selected'];
  final discarded = <String>[];
  @override
  Future<List<String>> pick() async {
    calls++;
    return paths;
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
  }
}

void main() {
  late Directory root;
  late AppDatabase db;
  late SelectedImportService importer;
  late FakePicker picker;
  late FakeRecognizer ocr;
  late ImportMediaStore media;
  var text = 'Lemon Pasta\nRecipe\nIngredients';
  bool broken = false;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('selected-test-');
    db = AppDatabase(NativeDatabase.memory());
    picker = FakePicker();
    ocr = FakeRecognizer();
    text = 'Lemon Pasta\nRecipe\nIngredients';
    broken = false;
    media = ImportMediaStore(
      supportDirectory: () async => root,
      temporaryDirectory: () async => root,
    );
    importer = SelectedImportService(
      picker: picker,
      normalize: (_) async {
        if (broken) throw StateError('corrupt');
        return NormalizedImage(Uint8List.fromList(utf8.encode(text)));
      },
      repository: SyncRepository(db),
      media: media,
      fallbackTitle: (_) => 'Screenshot',
      prepare: () async {},
      recognizer: ocr,
    );
  });
  tearDown(() async {
    importer.dispose();
    await db.close();
    await root.delete(recursive: true);
  });
  test(
    'free selected import classifies and deduplicates before repeated OCR',
    () async {
      final first = await importer.import();
      expect(first.imported, 1);
      expect(
        (await LocalEntryRepository(db).watchEntries().first).single.category,
        EntryCategory.recipes,
      );
      expect((await importer.import()).duplicates, 1);
      expect(ocr.calls, 1);
      expect(picker.discarded.length, 2);
    },
  );
  test('picker asset identity suppresses an already automatic import with different image encoding', () async {
    picker.sourceId = 'same-photos-asset';
    final repo = SyncRepository(db);
    final now = DateTime.now();
    await repo.enqueue([ScreenshotAsset(id: picker.sourceId!, createdAt: now)]);
    final job = (await repo.nextBatch(now)).single;
    expect(await repo.claim(job), isTrue);
    await repo.commit(
      job: job,
      draft: const EntryDraft(
        title: 'Already saved',
        category: EntryCategory.reading,
      ),
      hash: 'different-normalization-hash',
      imagePath: 'owned-existing-image.jpg',
      now: now,
      cancellation: SyncCancellation(),
    );
    final result = await importer.import();
    expect(result.duplicates, 1);
    expect(ocr.calls, 0);
    expect((await db.select(db.savedEntries).get()).length, 1);
  });
  test('picker commit prevents a stale queued automatic claim from duplicating its entry', () async {
    picker.sourceId = 'picker-and-automatic-race';
    final repo = SyncRepository(db);
    final now = DateTime.now();
    await repo.enqueue([ScreenshotAsset(id: picker.sourceId!, createdAt: now)]);
    final stale = (await repo.nextBatch(now)).single;
    expect((await importer.import()).imported, 1);
    expect(await repo.claim(stale), isFalse);
    expect((await db.select(db.savedEntries).get()).length, 1);
    expect(await repo.pendingCount(), 0);
  });
  test('concurrent import taps share one operation', () async {
    ocr.entered = Completer();
    ocr.release = Completer();
    final one = importer.import();
    await ocr.entered!.future;
    final two = importer.import();
    expect(picker.calls, 1);
    ocr.release!.complete();
    await Future.wait([one, two]);
    expect((await LocalEntryRepository(db).watchEntries().first).length, 1);
  });
  test(
    'corrupt input produces recoverable counts and discards private cache copy',
    () async {
      broken = true;
      final result = await importer.import();
      expect(result.failed, 1);
      expect(picker.discarded, ['selected']);
      expect(await LocalEntryRepository(db).watchEntries().first, isEmpty);
    },
  );
  test(
    'no OCR text keeps image in Other with a truthful fallback title',
    () async {
      text = ' ';
      await importer.import();
      final entry = (await LocalEntryRepository(
        db,
      ).watchEntries().first).single;
      expect(entry.category, EntryCategory.other);
      expect(entry.title, 'Screenshot');
      expect(entry.description, '');
      expect(await media.image(entry.imagePath), isNotNull);
    },
  );
  test(
    'sensitive selection retains no image, entry or content hash ledger',
    () async {
      text = 'Your verification code is 123456\nBanking';
      expect((await importer.import()).skipped, 1);
      expect(await db.select(db.screenshotJobs).get(), isEmpty);
      expect(await LocalEntryRepository(db).watchEntries().first, isEmpty);
      expect(
        await root.list(recursive: true).where((f) => f is File).toList(),
        isEmpty,
      );
    },
  );
  test(
    'cancelled OCR cannot commit and restart leaves no picker jobs pending',
    () async {
      ocr.entered = Completer();
      ocr.release = Completer();
      final running = importer.import();
      await ocr.entered!.future;
      importer.cancel();
      ocr.release!.complete();
      await running;
      expect(await LocalEntryRepository(db).watchEntries().first, isEmpty);
      expect(await db.select(db.screenshotJobs).get(), isEmpty);
      expect(
        await root.list(recursive: true).where((f) => f is File).toList(),
        isEmpty,
      );
    },
  );
  test(
    'staging refuses traversal, empty payloads and oversized images',
    () async {
      await expectLater(
        media.stage('../escape', Uint8List(1)),
        throwsArgumentError,
      );
      await expectLater(
        media.stage('a' * 64, Uint8List(0)),
        throwsArgumentError,
      );
      await expectLater(
        media.stage('a' * 64, Uint8List(8 * 1024 * 1024 + 1)),
        throwsArgumentError,
      );
    },
  );
}
