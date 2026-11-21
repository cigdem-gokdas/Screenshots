import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/product_preferences.dart';
import 'package:screenshot_cehennemi/data/sync/import_media_store.dart';
import 'package:screenshot_cehennemi/data/sync/sync_repository.dart';
import 'package:screenshot_cehennemi/l10n/app_localizations.dart';
import 'package:screenshot_cehennemi/onboarding/onboarding_controller.dart';
import 'package:screenshot_cehennemi/sync/screenshot_sync.dart';
import 'package:screenshot_cehennemi/sync/sync_models.dart';
import 'package:screenshot_cehennemi/ui/floating_dock.dart';
import 'package:screenshot_cehennemi/ui/screens/editorial_onboarding.dart';
import 'package:screenshot_cehennemi/ui/screens/photo_access_section.dart';

import 'sync/fakes.dart';
import 'auth_test.dart' show FakeAuth;

import 'package:screenshot_cehennemi/auth/auth_controller.dart';
import 'package:screenshot_cehennemi/ui/screens/account_section.dart';

Widget localized(Widget child) => MaterialApp(
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);
void main() {
  late AppDatabase db;
  late FakeLibrary library;
  late ScreenshotSync sync;
  late Directory directory;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    library = FakeLibrary();
    directory = await Directory.systemTemp.createTemp(
      'product-permission-test-',
    );
    sync = ScreenshotSync(
      repository: SyncRepository(db),
      library: library,
      recognizer: FakeRecognizer(),
      media: ImportMediaStore(
        supportDirectory: () async => directory,
        temporaryDirectory: () async => directory,
      ),
      fallbackTitle: (_) => 'Screenshot',
    );
  });
  tearDown(() async {
    await sync.shutdown();
    sync.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });
  for (final access in PhotoAccess.values) {
    test(
      'initialization reads actual $access without requesting permission',
      () async {
        library.permission = access;
        await sync.initialize();
        expect(sync.permission, access);
        expect(library.permissionRequests, 0);
      },
    );
  }
  test('permission read failures are unknown, never a fabricated denied or full status', () async {
    library.failAccess = true;
    await sync.initialize();
    expect(sync.permissionKnown, isFalse);
    expect(library.permissionRequests, 0);
    library.failAccess = false;
    library.permission = PhotoAccess.denied;
    await sync.refreshPermission();
    expect(sync.permissionKnown, isTrue);
    expect(sync.permission, PhotoAccess.denied);
  });
  test('denied and restricted access are never requested repeatedly', () async {
    for (final access in [PhotoAccess.denied, PhotoAccess.restricted]) {
      library.permission = access;
      await sync.initialize();
      await sync.enable(includeExisting: true);
      await sync.reconcile();
      expect(library.permissionRequests, 0);
      expect(sync.permission, access);
    }
  });
  test(
    'not determined requests only after explicit action, not resume',
    () async {
      library.permission = PhotoAccess.notDetermined;
      await sync.initialize();
      await sync.setForeground(true);
      expect(library.permissionRequests, 0);
      await sync.enable(includeExisting: true);
      expect(library.permissionRequests, 1);
    },
  );
  test(
    'Settings return sees full access and imports old screenshots once',
    () async {
      library.permission = PhotoAccess.denied;
      await sync.initialize();
      await sync.enable(includeExisting: true);
      await sync.reconcile();
      await sync.setForeground(false);
      library.add(
        'old-photo',
        'A recipe\nIngredients\nOlive oil',
        DateTime(2020),
      );
      library.permission = PhotoAccess.authorized;
      await sync.setForeground(true);
      expect(sync.permission, PhotoAccess.authorized);
      expect((await db.select(db.savedEntries).get()).length, 1);
      await sync.reconcile();
      expect((await db.select(db.savedEntries).get()).length, 1);
    },
  );
  test(
    'limited selection expansion discovers older newly exposed screenshots',
    () async {
      library.permission = PhotoAccess.limited;
      await sync.initialize();
      await sync.enable(includeExisting: true);
      await sync.reconcile();
      library.add('newly-exposed', 'A book\nAuthor\nNovel', DateTime(2019));
      await sync.setForeground(false);
      await sync.setForeground(true);
      expect((await db.select(db.savedEntries).get()).length, 1);
    },
  );
  test('onboarding completion persists in existing preference table', () async {
    final prefs = ProductPreferences(db);
    OnboardingController create() => OnboardingController(
      readCompleted: () => prefs.read('editorial_onboarding.v1'),
      writeCompleted: () => prefs.write('editorial_onboarding.v1', true),
    );
    final first = create();
    await first.initialize(existingLibrary: false);
    expect(first.show, isTrue);
    await first.complete();
    final second = create();
    await second.initialize(existingLibrary: false);
    expect(second.show, isFalse);
    final existing = OnboardingController(
      readCompleted: () async => false,
      writeCompleted: () async {},
    );
    await existing.initialize(existingLibrary: true);
    expect(existing.show, isFalse);
    first.dispose();
    second.dispose();
    existing.dispose();
  });
  testWidgets('denial card still offers picker and app Settings', (
    tester,
  ) async {
    library.permission = PhotoAccess.denied;
    await tester.runAsync(sync.initialize);
    var manual = 0;
    await tester.pumpWidget(
      localized(
        PhotoAccessSection(sync: sync, onManual: () => manual++, compact: true),
      ),
    );
    expect(
      find.text(
        'Galeri erişimi kapalı. İstersen ekran görüntülerini kendin seçebilirsin.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Fotoğraf Seç'));
    expect(manual, 1);
    expect(find.text('Ayarlardan İzin Ver'), findsOneWidget);
  });
  testWidgets('onboarding scenes work with reduced motion and large text', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      localized(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: EditorialOnboarding(onFinish: () async => finished++),
        ),
      ),
    );
    expect(find.text('Kaydettin.'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.byKey(const Key('onboarding-next')));
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(finished, 1);
  });
  testWidgets(
    'floating dock exposes four intentional destinations at large text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var selected = -1;
      await tester.pumpWidget(
        localized(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingDock(
                index: 0,
                onSelect: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(Key('dock-$i')), findsOneWidget);
      }
      final node = tester.getSemantics(
        find.byKey(const Key('dock-semantics-3')),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.byKey(const Key('dock-3')));
      expect(selected, 3);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  testWidgets(
    'both provider buttons remain usable in narrow large-text account surface',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthController(
        gateway: FakeAuth(),
        readEnabled: () async => false,
        writeEnabled: (_) async {},
        identifyBilling: (_) async {},
      );
      await tester.pumpWidget(
        localized(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AccountSection(auth: auth, showApple: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sign-in-google')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-apple')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
