import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class SavedEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get sourceAssetKey => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get capturedAt => dateTime().nullable()();
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@TableIndex(name: 'import_hash', columns: {#contentHash})
class ScreenshotJobs extends Table {
  TextColumn get assetKey => text()();
  TextColumn get assetId => text().nullable()();
  DateTimeColumn get capturedAt => dateTime().nullable()();
  TextColumn get state => text().withDefault(const Constant('queued'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get retryAt => dateTime().nullable()();
  TextColumn get contentHash => text().nullable()();
  IntColumn get entryId => integer().nullable().customConstraint(
    'REFERENCES saved_entries(id) ON DELETE SET NULL',
  )();
  TextColumn get errorCode => text().nullable()();
  @override
  Set<Column> get primaryKey => {assetKey};
}

/// Whether the default on-disk database file exists. Call BEFORE [AppDatabase]
/// is constructed; any failure is reported as "existed" (the safe answer, since
/// it only ever suppresses the fresh-install session cleanup).
Future<bool> defaultDatabaseFileExists() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    return await File(p.join(directory.path, "screenshot_cehennemi.sqlite"))
        .exists();
  } catch (_) {
    return true;
  }
}

@DriftDatabase(tables: [SavedEntries, Preferences, ScreenshotJobs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'screenshot_cehennemi'));
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(savedEntries, savedEntries.sourceAssetKey);
        await m.addColumn(savedEntries, savedEntries.imagePath);
        await m.addColumn(savedEntries, savedEntries.capturedAt);
        await m.createTable(screenshotJobs);
        await m.createIndex(importHash);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA secure_delete = ON');
    },
  );
}
