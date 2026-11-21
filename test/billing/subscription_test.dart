import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:screenshot_cehennemi/billing/revenuecat_gateway.dart';
import 'package:screenshot_cehennemi/billing/subscription_controller.dart';
import 'package:screenshot_cehennemi/billing/subscription_models.dart';
import 'package:screenshot_cehennemi/config/release_config.dart';

class TestReleaseConfig extends ReleaseConfig {
  const TestReleaseConfig();
  @override
  bool get billingConfigured => true;
  @override
  bool get canSell => true;
}

class FakeGateway implements SubscriptionGateway {
  int starts = 0, purchases = 0, restores = 0;
  bool offline = false;
  final now = DateTime.utc(2026, 10, 21, 12);
  SubscriptionAccess info = const SubscriptionAccess();
  BillingMessage? failure;
  Completer<SubscriptionAccess>? transaction;
  void Function(SubscriptionAccess)? update;
  final options = const [
    SubscriptionOffer(
      id: 'monthly',
      period: SubscriptionPeriod.monthly,
      localizedPrice: '₺49,99',
    ),
    SubscriptionOffer(
      id: 'yearly',
      period: SubscriptionPeriod.yearly,
      localizedPrice: '₺399,99',
    ),
  ];
  @override
  Future<void> initialize(void Function(SubscriptionAccess) listener) async {
    starts++;
    update = listener;
  }

  @override
  Future<SubscriptionAccess> customer({bool refresh = false}) async {
    if (offline) throw StateError('offline');
    return info;
  }

  @override
  Future<List<SubscriptionOffer>> offers() async => options;
  @override
  Future<SubscriptionAccess> purchase(String id) async {
    purchases++;
    if (failure != null) throw BillingFailure(failure!);
    return transaction == null ? info : transaction!.future;
  }

  @override
  Future<SubscriptionAccess> restore() async {
    restores++;
    return info;
  }

  @override
  void dispose() {}
  SubscriptionAccess get signed => SubscriptionAccess(
    active: true,
    verified: true,
    checkedAt: now,
    expiresAt: now.add(const Duration(days: 30)),
  );
}

void main() {
  late FakeGateway gateway;
  late SubscriptionController controller;
  late DateTime clock;
  bool consent = false;
  setUp(() {
    gateway = FakeGateway();
    clock = gateway.now;
    consent = false;
    controller = SubscriptionController(
      gateway: gateway,
      config: const TestReleaseConfig(),
      readConsent: () async => consent,
      writeConsent: () async => consent = true,
      clock: () => clock,
    );
  });
  tearDown(() => controller.dispose());
  test(
    'no SDK/network initialization without explicit persisted consent',
    () async {
      await controller.initialize();
      expect(gateway.starts, 0);
      expect(controller.hasPro, false);
      await controller.start(userConsented: true);
      expect(consent, true);
      expect(gateway.starts, 1);
      expect(controller.offers.length, 2);
    },
  );
  test('purchase double taps create exactly one store transaction', () async {
    await controller.start(userConsented: true);
    gateway.transaction = Completer();
    final first = controller.purchase(gateway.options.first);
    await controller.purchase(gateway.options.first);
    expect(gateway.purchases, 1);
    gateway.transaction!.complete(gateway.signed);
    await first;
    expect(controller.hasPro, true);
    expect(controller.message, BillingMessage.purchased);
  });
  for (final outcome in [
    BillingMessage.cancelled,
    BillingMessage.pending,
    BillingMessage.failed,
  ]) {
    test(
      'purchase $outcome grants no entitlement and permits safe UI recovery',
      () async {
        await controller.start(userConsented: true);
        gateway.failure = outcome;
        await controller.purchase(gateway.options.first);
        expect(controller.message, outcome);
        expect(controller.hasPro, false);
        expect(controller.busy, false);
      },
    );
  }
  test('restore handles no purchase and a real active entitlement', () async {
    await controller.start(userConsented: true);
    await controller.restore();
    expect(controller.message, BillingMessage.noPurchases);
    gateway.info = gateway.signed;
    await controller.restore();
    expect(controller.hasPro, true);
    expect(controller.message, BillingMessage.restored);
  });
  test(
    'expiration and refund updates remove Pro without touching saved data',
    () async {
      gateway.info = gateway.signed;
      await controller.start(userConsented: true);
      expect(controller.hasPro, true);
      gateway.update!(const SubscriptionAccess());
      expect(controller.hasPro, false);
      gateway.update!(gateway.signed);
      clock = clock.add(const Duration(days: 31));
      expect(controller.hasPro, false);
    },
  );
  test(
    'offline verified cache is bounded and never becomes permanent Pro',
    () async {
      gateway.info = gateway.signed;
      await controller.start(userConsented: true);
      gateway.offline = true;
      await controller.refresh();
      expect(controller.hasPro, true);
      clock = clock.add(const Duration(hours: 73));
      expect(controller.hasPro, false);
    },
  );
  test('unverified SDK entitlement is denied even when marked active', () {
    for (final verification in VerificationResult.values) {
      final entitlement = EntitlementInfo(
        'pro',
        true,
        true,
        '2026-10-21',
        '2026-10-21',
        'monthly',
        true,
        expirationDate: '2026-11-21T12:00:00Z',
        verification: verification,
      );
      final info = CustomerInfo(
        EntitlementInfos({'pro': entitlement}, {'pro': entitlement}),
        {},
        [],
        [],
        [],
        '2026-10-21',
        'anonymous-fixture',
        {},
        '2026-10-21T12:00:00Z',
      );
      expect(
        RevenueCatGateway.accessFromCustomer(info).allows(clock),
        verification == VerificationResult.verified ||
            verification == VerificationResult.verifiedOnDevice,
      );
    }
  });
  test(
    'malformed platform errors are safe and cancelled/pending are distinct',
    () {
      expect(
        RevenueCatGateway.mapError(PlatformException(code: 'not-a-number')),
        BillingMessage.failed,
      );
      expect(
        RevenueCatGateway.mapError(
          PlatformException(
            code: '${PurchasesErrorCode.purchaseCancelledError.index}',
          ),
        ),
        BillingMessage.cancelled,
      );
      expect(
        RevenueCatGateway.mapError(
          PlatformException(
            code: '${PurchasesErrorCode.paymentPendingError.index}',
          ),
        ),
        BillingMessage.pending,
      );
    },
  );
  test(
    'missing configuration fails closed without SDK initialization',
    () async {
      controller.dispose();
      controller = SubscriptionController(
        gateway: gateway,
        config: const ReleaseConfig(),
        readConsent: () async => true,
        writeConsent: () async {},
      );
      await controller.initialize();
      await controller.start(userConsented: true);
      expect(gateway.starts, 0);
      expect(controller.hasPro, false);
    },
  );
}
