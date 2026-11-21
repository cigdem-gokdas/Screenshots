import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/ui/app.dart';
import 'package:screenshot_cehennemi/ui/widgets.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native SQLite, UI save, cold reopen and deletion on iPhone', (
    tester,
  ) async {
    var db = AppDatabase();
    var repository = LocalEntryRepository(db);
    var controller = AppController(repository);
    final previousLanguage = await repository.readLanguage();
    final title =
        'Simulator verification ${DateTime.now().microsecondsSinceEpoch}';
    int? testId;
    try {
      await repository.writeLanguage('en');
      await controller.initialize();
      await tester.pumpWidget(ScreenshotApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New entry'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('entry-title')), title);
      await tester.enterText(
        find.byKey(const Key('entry-description')),
        'Native persistence verification',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('save-entry')).hitTestable(),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      final created = controller.entries.singleWhere((e) => e.title == title);
      testId = created.id;
      await tester.tap(find.text('Library').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, title);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EntryTile, title));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(
        controller.entries.singleWhere((e) => e.id == testId).status,
        EntryStatus.completed,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
      await db.close();
      db = AppDatabase();
      repository = LocalEntryRepository(db);
      controller = AppController(repository);
      expect(await repository.readLanguage(), 'en');
      final reopened = (await repository.watchEntries().first).singleWhere(
        (e) => e.id == testId,
      );
      expect(reopened.title, title);
      expect(reopened.status, EntryStatus.completed);
      await controller.initialize();
      await tester.pumpWidget(ScreenshotApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, title);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EntryTile, title));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Delete entry').hitTestable(),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(
        (await repository.watchEntries().first).any((e) => e.id == testId),
        isFalse,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      if (testId != null) await repository.delete(testId);
      await repository.writeLanguage(previousLanguage);
      controller.dispose();
      await db.close();
    }
  });
}
