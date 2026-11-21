import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/billing/subscription_controller.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/l10n/app_localizations.dart';
import 'package:screenshot_cehennemi/ui/app.dart';
import 'package:screenshot_cehennemi/ui/screens/paywall_screen.dart';
import 'package:screenshot_cehennemi/ui/screens/legal_screen.dart';

import 'subscription_test.dart' show FakeGateway, TestReleaseConfig;

void main() {
  testWidgets(
    'paywall explains billing before SDK, shows store prices and completes purchase',
    (tester) async {
      final gateway = FakeGateway();
      final billing = SubscriptionController(
        gateway: gateway,
        readConsent: () async => false,
        writeConsent: () async {},
        config: const TestReleaseConfig(),
        clock: () => gateway.now,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: PaywallScreen(billing: billing),
        ),
      );
      await tester.pumpAndSettle();
      expect(gateway.starts, 0);
      await tester.scrollUntilVisible(
        find.byKey(const Key('billing-consent')).hitTestable(),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-consent')));
      await tester.pumpAndSettle();
      expect(gateway.starts, 1);
      expect(find.text('₺49,99 / ay'), findsOneWidget);
      expect(find.text('₺399,99 / yıl'), findsOneWidget);
      gateway.info = gateway.signed;
      await tester.scrollUntilVisible(
        find.byKey(const Key('purchase-monthly')).hitTestable(),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('purchase-monthly')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('purchase-continue')));
      await tester.pumpAndSettle();
      expect(billing.hasPro, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      billing.dispose();
    },
  );
  testWidgets(
    'billing unavailable never hides saved data or opens a launch paywall',
    (tester) async {
      await tester.runAsync(() async {
        tester.platformDispatcher.localesTestValue = [const Locale('tr')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        final repo = LocalEntryRepository(db);
        await repo.save(
          const EntryDraft(
            title: 'My saved book',
            category: EntryCategory.reading,
          ),
        );
        final gateway = FakeGateway()..offline = true;
        final billing = SubscriptionController(
          gateway: gateway,
          readConsent: () async => true,
          writeConsent: () async {},
          config: const TestReleaseConfig(),
        );
        final controller = AppController(repo, billing: billing);
        await controller.initialize();
        await tester.pumpWidget(ScreenshotApp(controller: controller));
        await tester.pumpAndSettle();
        expect(find.byType(PaywallScreen), findsNothing);
        await tester.tap(find.text('Arşivim').last);
        await tester.pumpAndSettle();
        expect(find.text('My saved book'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await db.close();
      });
    },
  );
  testWidgets(
    'privacy summary remains readable offline with large Turkish text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LegalScreen(privacy: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('RevenueCat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
