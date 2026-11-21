import 'database.dart';

class ProductPreferences {
  ProductPreferences(this.db);
  final AppDatabase db;
  Future<bool> read(String key) async =>
      (await (db.select(
        db.preferences,
      )..where((p) => p.key.equals(key))).getSingleOrNull())?.value ==
      'true';
  Future<void> write(String key, bool value) => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(key: key, value: value.toString()),
      );
}
