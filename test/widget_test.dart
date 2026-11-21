import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/ui/app.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/l10n/app_localizations.dart';
import 'package:screenshot_cehennemi/ui/screens/settings_screen.dart';

class FailingSaveRepository extends LocalEntryRepository {
  FailingSaveRepository(super.db);
  @override
  Future<void> save(EntryDraft draft, {int? id}) async {
    throw StateError('Simulated write failure');
  }
}

void main() {
  late AppDatabase db;
  late AppController controller;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    controller = AppController(LocalEntryRepository(db));
  });
  tearDown(() async {
    controller.dispose();
    await db.close();
  });
  Future<void> start(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await controller.initialize();
    await tester.pumpWidget(ScreenshotApp(controller: controller));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'home, create, edit, status, search, review and delete work together',
    (tester) async {
      await start(tester);
      expect(find.text('Unuttuğum Screenshotlar'), findsOneWidget);
      final homeContext = tester.element(find.byType(AppShell));
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).onGenerateTitle!(
          homeContext,
        ),
        'Unuttuğum Screenshotlar',
      );
      expect(find.byKey(const Key('starter-add')), findsOneWidget);
      expect(find.text('No entries yet'), findsNothing);
      await tester.tap(find.byTooltip('New entry'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('save-entry')).hitTestable(),
        warnIfMissed: false,
      );
      await tester.enterText(find.byKey(const Key('entry-title')), 'Arrival');
      await tester.enterText(
        find.byKey(const Key('entry-description')),
        'Watch this weekend',
      );
      await tester.ensureVisible(find.byKey(const Key('save-entry')));
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      expect(controller.entries.single.title, 'Arrival');
      expect(find.text('1 entry'), findsOneWidget);
      await tester.tap(find.text('Library').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'arrival');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arrival'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(controller.entries.single.status.name, 'completed');
      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Arrival, tonight',
      );
      await tester.ensureVisible(find.byKey(const Key('save-entry')));
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Arrival, tonight'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily review').last);
      await tester.pumpAndSettle();
      expect(find.text('Saved today'), findsOneWidget);
      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();
      expect(find.text('Arrival, tonight'), findsOneWidget);
      await tester.tap(find.text('Arrival, tonight'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Delete entry'));
      await tester.tap(find.text('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(controller.entries, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unsupported device locale falls back, explicit language updates UI and persists',
    (tester) async {
      await controller.repository.save(
        const EntryDraft(title: 'Film', category: EntryCategory.watchlist),
      );
      await start(tester, locale: const Locale('de'));
      expect(find.text('İzleyeceklerim'), findsOneWidget);
      expect(find.text('Unuttuğum Screenshotlar'), findsOneWidget);
      await tester.tap(find.text('Ayarlar').last);
      await tester.pumpAndSettle();
      // Settings uses its own title, not the brand header.
      expect(find.text('Unuttuğum Screenshotlar'), findsNothing);
      expect(
        AppLocalizations.of(tester.element(find.byType(AppShell))).localeName,
        'tr',
      );
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNWidgets(2));
      expect(
        AppLocalizations.of(tester.element(find.byType(AppShell))).localeName,
        'en',
      );
      expect(await controller.repository.readLanguage(), 'en');
      final footerBrand = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.text('Unuttuğum Screenshotlar'),
      );
      await tester.scrollUntilVisible(
        footerBrand,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(footerBrand, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Device language').hitTestable(),
        -250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.text('Device language')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Device language').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Ayarlar'), findsAtLeastNWidgets(1));
      expect(
        AppLocalizations.of(tester.element(find.byType(AppShell))).localeName,
        'tr',
      );
      expect(await controller.repository.readLanguage(), isNull);
      await tester.scrollUntilVisible(
        footerBrand,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(footerBrand, findsOneWidget);
    },
  );
  testWidgets('editor validates title and unsafe URL without saving', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byTooltip('New entry'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-entry')));
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a title between 1 and 120 characters.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const Key('entry-title')));
    await tester.enterText(find.byKey(const Key('entry-title')), 'A find');
    await tester.ensureVisible(find.byKey(const Key('entry-url')));
    await tester.enterText(
      find.byKey(const Key('entry-url')),
      'javascript:alert(1)',
    );
    await tester.ensureVisible(find.byKey(const Key('save-entry')));
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a public https link without login details.'),
      findsOneWidget,
    );
    expect(controller.entries, isEmpty);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('starter-add')), findsOneWidget);
  });
  testWidgets('large text and narrow device have no layout exceptions', (
    tester,
  ) async {
    await start(tester, locale: const Locale('tr'));
    tester.view.physicalSize = const Size(320, 740);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Günlük bakış').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'failed save preserves the user draft and shows a recoverable error',
    (tester) async {
      controller.dispose();
      controller = AppController(FailingSaveRepository(db));
      await start(tester);
      await tester.tap(find.byTooltip('New entry'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Keep this draft',
      );
      await tester.ensureVisible(find.byKey(const Key('save-entry')));
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save. Your changes are still here. Try again.'),
        findsOneWidget,
      );
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(controller.entries, isEmpty);
    },
  );
  testWidgets('category and status filters combine and reset', (tester) async {
    await controller.repository.save(
      const EntryDraft(title: 'Film', category: EntryCategory.watchlist),
    );
    await controller.repository.save(
      const EntryDraft(
        title: 'Book',
        category: EntryCategory.reading,
        status: EntryStatus.completed,
      ),
    );
    await start(tester);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reading list').last);
    await tester.pumpAndSettle();
    expect(find.text('Book'), findsOneWidget);
    expect(find.text('Film'), findsNothing);
    await tester.tap(find.text('All statuses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To do').last);
    await tester.pumpAndSettle();
    expect(find.text('No matching entries'), findsOneWidget);
    await tester.tap(find.text('Clear filters').first);
    await tester.pumpAndSettle();
    expect(find.text('Film'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
  });

  Future<void> addRow(
    String title, {
    String? url,
    String? sourceAssetKey,
    EntryCategory category = EntryCategory.watchlist,
  }) async {
    final now = DateTime.now().toUtc();
    await db
        .into(db.savedEntries)
        .insert(
          SavedEntriesCompanion.insert(
            title: title,
            category: category.name,
            status: 'todo',
            createdAt: now,
            updatedAt: now,
            url: url == null ? const Value.absent() : Value(url),
            sourceAssetKey: Value(sourceAssetKey),
          ),
        );
  }

  testWidgets('empty home shows one starter card instead of eight tiles', (
    tester,
  ) async {
    await start(tester, locale: const Locale('tr'));
    expect(find.text('00'), findsNothing);
    expect(find.text('Henüz kayıt yok'), findsNothing);
    expect(find.byKey(const Key('starter-add')), findsOneWidget);
    expect(find.text('Elle ekle'), findsOneWidget);
    expect(find.text('İzleyeceklerim'), findsNothing);
  });

  testWidgets('top bar is per tab and collapses on scroll, then returns', (
    tester,
  ) async {
    for (var i = 0; i < 12; i++) {
      await addRow('Entry $i');
    }
    await start(tester);
    tester.view.physicalSize = const Size(390, 600);
    await tester.pumpAndSettle();
    final brand = find.text('Unuttuğum Screenshotlar');
    expect(find.byType(SliverAppBar), findsOneWidget);
    final big = tester.getSize(brand).height;
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(brand, findsOneWidget);
    final small = tester.getSize(brand).height;
    expect(small, lessThan(big));
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(brand).height, closeTo(big, .5));
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(brand, findsNothing);
    expect(find.text('All entries'), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
  });

  testWidgets('swipe delete removes the entry and Undo restores it', (
    tester,
  ) async {
    await addRow('Alpha');
    await addRow('Beta');
    await start(tester);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.drag(find.text('Beta'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(controller.entries.map((e) => e.title), ['Alpha']);
    expect(find.text('Entry deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(controller.entries.map((e) => e.title).toSet(), {'Alpha', 'Beta'});
    expect(find.text('Beta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe right completes an entry', (tester) async {
    await addRow('Alpha');
    await start(tester);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.drag(find.text('Alpha'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(controller.entries.single.status, EntryStatus.completed);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('links read from a screenshot ask before opening', (
    tester,
  ) async {
    await addRow(
      'Scanned',
      url: 'https://xn--bcher-kva.example/menu',
      sourceAssetKey: 'asset-1',
    );
    await start(tester);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scanned'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-link')));
    await tester.tap(find.byKey(const Key('open-link')));
    await tester.pumpAndSettle();
    expect(find.text('Open this link?'), findsOneWidget);
    expect(find.text('bücher.example (xn--bcher-kva.example)'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Open this link?'), findsNothing);
    expect(find.text('Scanned'), findsOneWidget);
  });

  testWidgets('manually added links open without a confirmation', (
    tester,
  ) async {
    await addRow('Typed', url: 'https://example.com/recipe');
    await start(tester);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Typed'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-link')));
    await tester.tap(find.byKey(const Key('open-link')));
    await tester.pumpAndSettle();
    expect(find.text('Open this link?'), findsNothing);
  });

  testWidgets('library sorts A to Z and searches after the debounce', (
    tester,
  ) async {
    await addRow('Çorba');
    await addRow('Zeytin');
    await addRow('Armut');
    await start(tester, locale: const Locale('tr'));
    await tester.tap(find.text('Arşivim').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sırala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A–Z').last);
    await tester.pumpAndSettle();
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Armut'), lessThan(y('Çorba')));
    expect(y('Çorba'), lessThan(y('Zeytin')));
    await tester.enterText(find.byType(TextField).first, 'zey');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Armut'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Armut'), findsNothing);
    expect(find.text('Zeytin'), findsOneWidget);
  });

  testWidgets('home, library, review and settings fit at 2x text', (
    tester,
  ) async {
    await addRow('Film night', category: EntryCategory.watchlist);
    await addRow('Pasta', category: EntryCategory.recipes);
    await start(tester, locale: const Locale('tr'));
    tester.view.physicalSize = const Size(375, 760);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['Arşivim', 'Günlük bakış', 'Ayarlar']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('dark theme builds the home screen', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await start(tester);
    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });
}
