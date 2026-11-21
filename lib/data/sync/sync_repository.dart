import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/entry.dart';
import '../../sync/sync_models.dart';
import '../database.dart';

String assetKey(String id) => sha256.convert(utf8.encode('ios:$id')).toString();

class SyncRepository {
  SyncRepository(this.db);
  final AppDatabase db;
  Future<SyncConfig> loadConfig() async => SyncConfig.decode(
    (await (db.select(
          db.preferences,
        )..where((t) => t.key.equals('screenshot_sync.v1'))).getSingleOrNull())
        ?.value,
  );
  Future<void> saveConfig(SyncConfig config) => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(
          key: 'screenshot_sync.v1',
          value: config.encode(),
        ),
      );

  Future<void> enqueue(List<ScreenshotAsset> assets) =>
      db.transaction(() async {
        for (final asset in assets) {
          await db
              .into(db.screenshotJobs)
              .insert(
                ScreenshotJobsCompanion.insert(
                  assetKey: assetKey(asset.id),
                  assetId: Value(asset.id),
                  capturedAt: Value(asset.createdAt.toUtc()),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      });
  Future<void> recoverInterrupted() => db.customUpdate(
    "UPDATE screenshot_jobs SET state = 'queued', attempts = MAX(0, attempts - 1), retry_at = NULL WHERE state = 'processing'",
    updates: {db.screenshotJobs},
  );
  Future<void> retryFailed() =>
      (db.update(
        db.screenshotJobs,
      )..where((t) => t.state.equals('failed'))).write(
        const ScreenshotJobsCompanion(
          state: Value('queued'),
          attempts: Value(0),
          retryAt: Value(null),
          errorCode: Value(null),
        ),
      );
  Future<List<ScreenshotJob>> nextBatch(DateTime now) =>
      (db.select(db.screenshotJobs)
            ..where(
              (t) =>
                  t.state.equals('queued') |
                  (t.state.equals('retry') &
                      (t.retryAt.isNull() |
                          t.retryAt.isSmallerOrEqualValue(now.toUtc()))),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.capturedAt)])
            ..limit(12))
          .get();
  Future<bool> claim(ScreenshotJob job) async =>
      await (db.update(db.screenshotJobs)..where(
            (t) =>
                t.assetKey.equals(job.assetKey) &
                t.state.isIn(['queued', 'retry', 'failed']),
          ))
          .write(
            ScreenshotJobsCompanion(
              state: const Value('processing'),
              attempts: Value(job.attempts + 1),
              errorCode: const Value(null),
            ),
          ) ==
      1;
  Future<void> requeue(ScreenshotJob job) =>
      (db.update(db.screenshotJobs)..where(
            (t) =>
                t.assetKey.equals(job.assetKey) & t.state.equals('processing'),
          ))
          .write(
            ScreenshotJobsCompanion(
              state: const Value('queued'),
              attempts: Value(job.attempts),
            ),
          );

  Future<void> finish(ScreenshotJob job, String state, {String? hash}) =>
      (db.update(
        db.screenshotJobs,
      )..where((t) => t.assetKey.equals(job.assetKey))).write(
        ScreenshotJobsCompanion(
          state: Value(state),
          assetId: const Value(null),
          capturedAt: const Value(null),
          contentHash: Value(hash),
          errorCode: const Value(null),
          retryAt: const Value(null),
        ),
      );
  Future<void> defer(ScreenshotJob job, DateTime now, String reason) {
    final cloud = reason == 'cloud';
    final attempt = job.attempts + 1;
    return (db.update(
      db.screenshotJobs,
    )..where((t) => t.assetKey.equals(job.assetKey))).write(
      ScreenshotJobsCompanion(
        state: Value(!cloud && attempt >= 3 ? 'failed' : 'retry'),
        attempts: Value(cloud ? job.attempts : attempt),
        retryAt: Value(
          now.toUtc().add(
            Duration(
              seconds: cloud ? 900 : 30 * (1 << job.attempts.clamp(0, 4)),
            ),
          ),
        ),
        errorCode: Value(
          const {'cloud', 'missing', 'image', 'ocr', 'storage'}.contains(reason)
              ? reason
              : 'image',
        ),
      ),
    );
  }

  Future<bool> assetHandled(String key) async {
    final row = await (db.select(
      db.screenshotJobs,
    )..where((t) => t.assetKey.equals(key))).getSingleOrNull();
    return row != null &&
        [
          'done',
          'duplicate',
          'excluded',
          'missing',
          'processing',
        ].contains(row.state);
  }

  Future<bool> knownHash(String hash) async =>
      (await (db.select(db.screenshotJobs)
                ..where((t) => t.contentHash.equals(hash))
                ..limit(1))
              .get())
          .isNotEmpty;
  Future<bool> commit({
    required ScreenshotJob job,
    required EntryDraft draft,
    required String hash,
    required String imagePath,
    required DateTime now,
    required SyncCancellation cancellation,
  }) => db.transaction(() async {
    cancellation.check();
    if (!draft.isValid) throw ArgumentError('Invalid import');
    if (await knownHash(hash)) {
      cancellation.check();
      await finish(job, 'duplicate', hash: hash);
      return false;
    }
    cancellation.check();
    final id = await db
        .into(db.savedEntries)
        .insert(
          SavedEntriesCompanion.insert(
            title: draft.title,
            category: draft.category.name,
            description: Value(draft.description),
            url: Value(draft.url),
            status: draft.status.name,
            createdAt: now.toUtc(),
            updatedAt: now.toUtc(),
            sourceAssetKey: Value(job.assetKey),
            imagePath: Value(imagePath),
            capturedAt: Value(job.capturedAt),
          ),
        );
    // Cancellation rolls this whole transaction back, including the new entry.
    cancellation.check();
    await (db.update(
      db.screenshotJobs,
    )..where((t) => t.assetKey.equals(job.assetKey))).write(
      ScreenshotJobsCompanion(
        state: const Value('done'),
        entryId: Value(id),
        contentHash: Value(hash),
        assetId: const Value(null),
        capturedAt: const Value(null),
        retryAt: const Value(null),
        errorCode: const Value(null),
      ),
    );
    cancellation.check();
    return true;
  });

  /// Selected imports enter the ledger and entry table in one transaction, so
  /// the automatic worker can never claim an unfinished picker job.
  Future<bool> commitSelected({
    required String key,
    required String hash,
    required EntryDraft draft,
    required String imagePath,
    required DateTime now,
    required SyncCancellation cancellation,
  }) => db.transaction(() async {
    cancellation.check();
    if (await knownHash(hash) || await assetHandled(key)) return false;
    await db
        .into(db.screenshotJobs)
        .insertOnConflictUpdate(
          ScreenshotJobsCompanion.insert(
            assetKey: key,
            state: const Value('processing'),
            capturedAt: Value(now.toUtc()),
          ),
        );
    final job = await (db.select(
      db.screenshotJobs,
    )..where((t) => t.assetKey.equals(key))).getSingle();
    return commit(
      job: job,
      draft: draft,
      hash: hash,
      imagePath: imagePath,
      now: now,
      cancellation: cancellation,
    );
  });

  Future<int> pendingCount() async {
    final count = db.screenshotJobs.assetKey.count();
    final row =
        await (db.selectOnly(db.screenshotJobs)
              ..addColumns([count])
              ..where(
                db.screenshotJobs.state.isIn([
                  'queued',
                  'processing',
                  'retry',
                  'failed',
                ]),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<DateTime?> nextRetry() async {
    final row =
        await (db.select(db.screenshotJobs)
              ..where((t) => t.state.equals('retry'))
              ..orderBy([(t) => OrderingTerm.asc(t.retryAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.retryAt;
  }

  Future<bool> imageReferenced(String path) async =>
      (await (db.select(db.savedEntries)
                ..where((t) => t.imagePath.equals(path))
                ..limit(1))
              .get())
          .isNotEmpty;
  Future<void> deleteImportedData(SyncConfig reset) => db.transaction(() async {
    await (db.delete(
      db.savedEntries,
    )..where((t) => t.sourceAssetKey.isNotNull())).go();
    await db.delete(db.screenshotJobs).go();
    await saveConfig(reset);
  });
}
