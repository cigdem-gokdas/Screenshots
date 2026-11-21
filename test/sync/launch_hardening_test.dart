import 'dart:typed_data';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/auth/auth_controller.dart';
import 'package:screenshot_cehennemi/billing/billing_consent_store.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/data/sync/private_storage.dart';

void main() {
  test('protectStorageAtLaunch runs first and tolerates failure', () async {
    final order = <String>[];
    await protectStorageAtLaunch(
      protect: () async {
        order.add('protect');
        throw StateError('no channel');
      },
    );
    order.add('database');
    expect(order, ['protect', 'database']);
    // Real default tolerates a missing platform channel.
    TestWidgetsFlutterBinding.ensureInitialized();
    await protectStorageAtLaunch();
  });

  group('install marker', () {
    Future<(bool, int, bool)> run({
      required bool existed,
      required bool marker,
      bool signOutFails = false,
    }) async {
      var wrote = false, outs = 0;
      final signed = await reconcileInstallMarker(
        databaseExisted: existed,
        readMarker: () async => marker,
        writeMarker: () async => wrote = true,
        signOutStale: () async {
          outs++;
          if (signOutFails) throw StateError('x');
        },
      );
      return (signed, outs, wrote);
    }

    test('fresh install signs out once and writes marker', () async {
      expect(await run(existed: false, marker: false), (true, 1, true));
    });
    test('upgrade only writes marker', () async {
      expect(await run(existed: true, marker: false), (false, 0, true));
    });
    test('marker present does nothing', () async {
      expect(await run(existed: false, marker: true), (false, 0, false));
    });
    test('signOut failure still writes marker', () async {
      expect(await run(existed: false, marker: false, signOutFails: true), (
        false,
        1,
        true,
      ));
    });
  });

  test('consent store writes versioned value and accepts legacy', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = BillingConsentStore(
      db,
      clock: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
    );
    expect(await store.read(), isFalse);
    await store.accept();
    final row = await (db.select(
      db.preferences,
    )..where((t) => t.key.equals(BillingConsentStore.key))).getSingle();
    expect(row.value, 'accepted:v1:2026-01-02T03:04:05.000Z');
    expect(await store.read(), isTrue);
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(
            key: BillingConsentStore.key,
            value: 'accepted',
          ),
        );
    expect(await store.read(), isTrue);
    expect(BillingConsentStore.isGranted('declined'), isFalse);
    expect(BillingConsentStore.isGranted(null), isFalse);
  });

  test('media store protects staged and retained files', () async {
    final root = await Directory.systemTemp.createTemp('media');
    addTearDown(() => root.delete(recursive: true));
    final protectedPaths = <String>[];
    final media = ImportMediaStore(
      supportDirectory: () async => root,
      temporaryDirectory: () async => root,
      protectFile: (path) async {
        protectedPaths.add(path);
        throw StateError('best effort');
      },
    );
    final key = 'a' * 64;
    final staged = await media.stage(key, Uint8List.fromList([1, 2, 3]));
    final name = await media.retain(key, staged);
    expect(protectedPaths.length, 2);
    expect(protectedPaths.last, endsWith(name));
  });
}
