import 'package:drift/drift.dart';

import '../domain/entry.dart';
import 'database.dart';
import 'sync/import_media_store.dart';

abstract class EntryRepository {
  Stream<List<Entry>> watchEntries();
  Future<void> save(EntryDraft draft, {int? id});
  Future<void> setStatus(int id, EntryStatus status);
  Future<void> delete(int id, {bool keepMedia = false});

  /// Re-inserts a previously deleted entry with its original id and dates.
  Future<void> restore(Entry entry);

  /// Removes the image copy of an entry deleted with `keepMedia: true`.
  Future<void> discardMedia(String? imagePath);
  Future<String?> readLanguage();
  Future<void> writeLanguage(String? language);
}

class LocalEntryRepository implements EntryRepository {
  LocalEntryRepository(this.db, {DateTime Function()? clock, this.media})
    : clock = clock ?? DateTime.now;
  final AppDatabase db;
  final ImportMediaStore? media;
  final DateTime Function() clock;

  @override
  Stream<List<Entry>> watchEntries() =>
      (db.select(db.savedEntries)..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (r) => Entry(
                    id: r.id,
                    title: r.title,
                    category: EntryCategory.values.byName(r.category),
                    description: r.description,
                    url: r.url,
                    status: EntryStatus.values.byName(r.status),
                    createdAt: r.createdAt.toLocal(),
                    updatedAt: r.updatedAt.toLocal(),
                    sourceAssetKey: r.sourceAssetKey,
                    imagePath: r.imagePath,
                    capturedAt: r.capturedAt?.toLocal(),
                  ),
                )
                .toList(),
          );

  @override
  Future<void> save(EntryDraft draft, {int? id}) async {
    if (!draft.isValid) throw ArgumentError('Invalid entry');
    final now = clock().toUtc();
    final row = SavedEntriesCompanion(
      title: Value(draft.title.trim()),
      category: Value(draft.category.name),
      description: Value(draft.description.trim()),
      url: Value(draft.url.trim()),
      status: Value(draft.status.name),
      updatedAt: Value(now),
    );
    if (id == null) {
      await db
          .into(db.savedEntries)
          .insert(row.copyWith(createdAt: Value(now)));
    } else {
      final count = await (db.update(
        db.savedEntries,
      )..where((t) => t.id.equals(id))).write(row);
      if (count != 1) throw StateError('Entry missing');
    }
  }

  @override
  Future<void> setStatus(int id, EntryStatus status) async {
    final count =
        await (db.update(db.savedEntries)..where((t) => t.id.equals(id))).write(
          SavedEntriesCompanion(
            status: Value(status.name),
            updatedAt: Value(clock().toUtc()),
          ),
        );
    if (count != 1) throw StateError('Entry missing');
  }

  @override
  Future<void> delete(int id, {bool keepMedia = false}) async {
    final entry = await (db.select(
      db.savedEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    await (db.delete(db.savedEntries)..where((t) => t.id.equals(id))).go();
    // Keep the digest tombstone to avoid reimport; orphan files are also swept.
    if (!keepMedia) await discardMedia(entry?.imagePath);
  }

  @override
  Future<void> discardMedia(String? imagePath) async {
    if (imagePath == null || media == null) return;
    try {
      await media!.remove(imagePath);
    } catch (_) {
      /* Startup sweeps orphan copies. */
    }
  }

  @override
  Future<void> restore(Entry entry) async {
    await db
        .into(db.savedEntries)
        .insertOnConflictUpdate(
          SavedEntriesCompanion(
            id: Value(entry.id),
            title: Value(entry.title),
            category: Value(entry.category.name),
            description: Value(entry.description),
            url: Value(entry.url),
            status: Value(entry.status.name),
            createdAt: Value(entry.createdAt.toUtc()),
            updatedAt: Value(entry.updatedAt.toUtc()),
            sourceAssetKey: Value(entry.sourceAssetKey),
            imagePath: Value(entry.imagePath),
            capturedAt: Value(entry.capturedAt?.toUtc()),
          ),
        );
    final key = entry.sourceAssetKey;
    if (key != null) {
      // The job row keeps the dedupe tombstone; re-link it to the entry.
      await (db.update(db.screenshotJobs)..where((t) => t.assetKey.equals(key)))
          .write(ScreenshotJobsCompanion(entryId: Value(entry.id)));
    }
  }

  @override
  Future<String?> readLanguage() async => (await (db.select(
    db.preferences,
  )..where((t) => t.key.equals('language'))).getSingleOrNull())?.value;
  @override
  Future<void> writeLanguage(String? language) async {
    if (language != null && language != 'tr' && language != 'en') {
      throw ArgumentError('Unsupported locale');
    }
    if (language == null) {
      await (db.delete(
        db.preferences,
      )..where((t) => t.key.equals('language'))).go();
    } else {
      await db
          .into(db.preferences)
          .insertOnConflictUpdate(
            PreferencesCompanion.insert(key: 'language', value: language),
          );
    }
  }
}
