import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/domain/link_host.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';

class RecoverableRepository extends LocalEntryRepository {
  RecoverableRepository(super.db);
  bool failRead = true;
  bool failWrite = false;
  @override
  Future<String?> readLanguage() {
    if (failRead) throw StateError('Simulated unavailable storage');
    return super.readLanguage();
  }

  @override
  Future<void> writeLanguage(String? language) {
    if (failWrite) throw StateError('Simulated unavailable storage');
    return super.writeLanguage(language);
  }
}

void main() {
  test(
    'startup failure is recoverable and stream updates reach controller',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = RecoverableRepository(db);
      final controller = AppController(repository);
      try {
        await controller.initialize();
        expect(controller.failed, isTrue);
        expect(controller.loading, isFalse);
        repository.failRead = false;
        await controller.initialize();
        final received = Completer<void>();
        controller.addListener(() {
          if (controller.entries.isNotEmpty && !received.isCompleted) {
            received.complete();
          }
        });
        await repository.save(
          const EntryDraft(title: 'Recovered', category: EntryCategory.other),
        );
        await received.future.timeout(const Duration(seconds: 5));
        expect(controller.failed, isFalse);
        expect(controller.entries.single.title, 'Recovered');
        repository.failWrite = true;
        await expectLater(controller.changeLanguage('en'), throwsStateError);
        expect(controller.language, isNull);
        expect(await repository.readLanguage(), isNull);
      } finally {
        controller.dispose();
        await db.close();
      }
    },
  );

  test('soft delete keeps the image until the undo window ends', () async {
    final dir = await Directory.systemTemp.createTemp('soft-delete-test-');
    final db = AppDatabase(NativeDatabase.memory());
    final media = ImportMediaStore(
      supportDirectory: () async => dir,
      temporaryDirectory: () async => dir,
    );
    final repository = LocalEntryRepository(db, media: media);
    final controller = AppController(repository);
    try {
      final key = 'a' * 64;
      final staged = await media.stage(key, Uint8List.fromList([1, 2, 3]));
      final name = await media.retain(key, staged);
      final now = DateTime.now().toUtc();
      await db
          .into(db.savedEntries)
          .insert(
            SavedEntriesCompanion.insert(
              title: 'With picture',
              category: 'other',
              status: 'todo',
              createdAt: now,
              updatedAt: now,
              imagePath: Value(name),
              sourceAssetKey: const Value('asset'),
            ),
          );
      await controller.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final entry = controller.entries.single;
      await controller.softDelete(entry);
      expect(controller.entries, isEmpty);
      expect(await media.image(name), isNotNull);
      await controller.undoDelete(entry);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.entries.single.id, entry.id);
      expect(controller.entries.single.imagePath, name);
      expect(await media.image(name), isNotNull);
      await controller.softDelete(controller.entries.single);
      await controller.commitDelete(entry);
      expect(await media.image(name), isNull);
    } finally {
      controller.dispose();
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test('link host decodes punycode and keeps the raw host visible', () {
    expect(displayHost('https://example.com/a'), 'example.com');
    expect(
      displayHost('https://xn--bcher-kva.example/'),
      'bücher.example (xn--bcher-kva.example)',
    );
    expect(punycodeDecode('!!'), isNull);
  });

  test('sorting handles Turkish letters and both date directions', () {
    Entry e(int id, String title, int day) => Entry(
      id: id,
      title: title,
      category: EntryCategory.other,
      description: '',
      url: '',
      status: EntryStatus.todo,
      createdAt: DateTime(2026, 1, day),
      updatedAt: DateTime(2026, 1, day),
    );
    final list = [e(1, 'Zeytin', 1), e(2, 'Çorba', 2), e(3, 'Armut', 3)];
    expect(sortEntries(list, EntrySort.title).map((x) => x.title), [
      'Armut',
      'Çorba',
      'Zeytin',
    ]);
    expect(sortEntries(list, EntrySort.newest).map((x) => x.id), [3, 2, 1]);
    expect(sortEntries(list, EntrySort.oldest).map((x) => x.id), [1, 2, 3]);
  });
}
