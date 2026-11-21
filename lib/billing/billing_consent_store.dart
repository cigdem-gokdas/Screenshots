import '../data/database.dart';

class BillingConsentStore {
  BillingConsentStore(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;
  static const key = 'billing_consent.v1';
  static const legacyValue = 'accepted';
  static const versionedPrefix = 'accepted:v1:';

  /// Legacy and versioned values both count as granted.
  static bool isGranted(String? value) =>
      value == legacyValue || (value?.startsWith(versionedPrefix) ?? false);
  Future<bool> read() async => isGranted(
    (await (db.select(
      db.preferences,
    )..where((t) => t.key.equals(key))).getSingleOrNull())?.value,
  );
  Future<void> accept() async => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(
          key: key,
          value: '$versionedPrefix${_clock().toUtc().toIso8601String()}',
        ),
      );
}
