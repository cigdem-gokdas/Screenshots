import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';

void main() {
  late AppDatabase db;
  late LocalEntryRepository repository;
  final now = DateTime.utc(2026, 10, 15, 12);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalEntryRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('CRUD, statuses and reactive counts use actual SQLite rows', () async {
    expect(await repository.watchEntries().first, isEmpty);
    await repository.save(
      const EntryDraft(
        title: '  Arrival  ',
        category: EntryCategory.watchlist,
        description: '  A quiet evening  ',
        url: 'https://example.org/movie',
      ),
    );
    final entry = (await repository.watchEntries().first).single;
    expect(entry.title, 'Arrival');
    expect(entry.description, 'A quiet evening');
    expect(entry.createdAt.toUtc(), now);
    await repository.save(
      const EntryDraft(
        title: 'Dune',
        category: EntryCategory.reading,
        status: EntryStatus.completed,
      ),
      id: entry.id,
    );
    final edited = (await repository.watchEntries().first).single;
    expect(edited.category, EntryCategory.reading);
    expect(edited.createdAt, entry.createdAt);
    expect(edited.status, EntryStatus.completed);
    await repository.setStatus(entry.id, EntryStatus.archived);
    expect(
      (await repository.watchEntries().first).single.status,
      EntryStatus.archived,
    );
    await repository.setStatus(entry.id, EntryStatus.todo);
    expect(
      (await repository.watchEntries().first).single.status,
      EntryStatus.todo,
    );
    await repository.delete(entry.id);
    expect(await repository.watchEntries().first, isEmpty);
  });
  test('invalid input never reaches storage', () async {
    for (final draft in [
      const EntryDraft(title: ' ', category: EntryCategory.other),
      const EntryDraft(
        title: 'Unsafe link',
        category: EntryCategory.other,
        url: 'javascript:alert(1)',
      ),
    ]) {
      await expectLater(repository.save(draft), throwsArgumentError);
    }
    expect(await repository.watchEntries().first, isEmpty);
  });
  test('missing update reports failure', () async {
    await expectLater(
      repository.save(
        const EntryDraft(title: 'Missing', category: EntryCategory.other),
        id: 99,
      ),
      throwsStateError,
    );
    await expectLater(
      repository.setStatus(99, EntryStatus.completed),
      throwsStateError,
    );
  });
  test('language is persisted and system mode removes override', () async {
    expect(await repository.readLanguage(), isNull);
    await repository.writeLanguage('en');
    expect(await repository.readLanguage(), 'en');
    await repository.writeLanguage('tr');
    expect(await repository.readLanguage(), 'tr');
    await repository.writeLanguage(null);
    expect(await repository.readLanguage(), isNull);
    await expectLater(repository.writeLanguage('de'), throwsArgumentError);
  });
  test(
    'entries and language survive closing and reopening the database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'screenshot-persistence-',
      );
      final file = File('${directory.path}/test.sqlite');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final disk = db;
      final diskRepo = LocalEntryRepository(disk);
      await diskRepo.save(
        const EntryDraft(title: 'Persist me', category: EntryCategory.ideas),
      );
      await diskRepo.writeLanguage('en');
      await disk.close();
      db = AppDatabase(NativeDatabase(file));
      final reopened = db;
      try {
        final repo = LocalEntryRepository(reopened);
        expect((await repo.watchEntries().first).single.title, 'Persist me');
        expect(await repo.readLanguage(), 'en');
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
