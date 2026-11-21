import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/data/sync/sync_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';

void main() {
  test(
    'v1 migration preserves existing entries, statuses, dates and language',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (sqlite) {
            sqlite.execute(
              'CREATE TABLE saved_entries (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT \'\', url TEXT NOT NULL DEFAULT \'\', status TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
            );
            sqlite.execute(
              'CREATE TABLE preferences (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
            );
            sqlite.execute(
              "INSERT INTO saved_entries VALUES (7, 'Existing book', 'reading', 'Keep this note', 'https://example.org', 'completed', 1700000000, 1700000001)",
            );
            sqlite.execute("INSERT INTO preferences VALUES ('language', 'tr')");
            sqlite.execute('PRAGMA user_version = 1');
          },
        ),
      );
      try {
        final local = LocalEntryRepository(db);
        final entry = (await local.watchEntries().first).single;
        expect(entry.id, 7);
        expect(entry.title, 'Existing book');
        expect(entry.status, EntryStatus.completed);
        expect(entry.description, 'Keep this note');
        expect(entry.createdAt.millisecondsSinceEpoch, 1700000000000);
        expect(entry.sourceAssetKey, isNull);
        expect(entry.imagePath, isNull);
        expect(await local.readLanguage(), 'tr');
        final repo = SyncRepository(db);
        await repo.enqueue([
          ScreenshotAsset(id: 'new', createdAt: DateTime.now()),
        ]);
        expect((await repo.nextBatch(DateTime.now())).length, 1);
        expect(
          await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type='index' AND name='import_hash'",
              )
              .get(),
          hasLength(1),
        );
      } finally {
        await db.close();
      }
    },
  );
  test(
    'cancelled transactional import cannot leave an entry or completed marker',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = SyncRepository(db);
        await repo.enqueue([
          ScreenshotAsset(id: 'cancelled', createdAt: DateTime.now()),
        ]);
        final job = (await repo.nextBatch(DateTime.now())).single;
        final token = SyncCancellation()..cancelled = true;
        await expectLater(
          repo.commit(
            job: job,
            draft: const EntryDraft(
              title: 'Never saved',
              category: EntryCategory.other,
            ),
            hash: 'hash',
            imagePath: 'image',
            now: DateTime.now(),
            cancellation: token,
          ),
          throwsA(isA<SyncCancelled>()),
        );
        expect(await LocalEntryRepository(db).watchEntries().first, isEmpty);
        expect(
          (await db.select(db.screenshotJobs).get()).single.state,
          'queued',
        );
      } finally {
        await db.close();
      }
    },
  );
}
