import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/auth/auth_controller.dart';
import 'package:screenshot_cehennemi/auth/auth_models.dart';
import 'package:screenshot_cehennemi/billing/subscription_controller.dart';
import 'package:screenshot_cehennemi/billing/subscription_models.dart';
import 'package:screenshot_cehennemi/data/database.dart';
import 'package:screenshot_cehennemi/data/entry_repository.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';

import 'billing/subscription_test.dart' show FakeGateway, TestReleaseConfig;

class FakeAuth implements AuthGateway {
  @override
  bool configured = true;
  int initializes = 0, signOuts = 0, deletes = 0;
  LocalAccount? current;
  AuthMessage? failure;
  final events = StreamController<LocalAccount?>.broadcast();
  @override
  Stream<LocalAccount?> get changes => events.stream;
  @override
  Future<LocalAccount?> initialize() async {
    initializes++;
    return current;
  }

  LocalAccount signed(LoginProvider provider) =>
      LocalAccount(uid: 'verified-firebase-uid', providers: {provider});
  @override
  Future<LocalAccount> signIn(LoginProvider provider) async {
    if (failure != null) throw AuthFailure(failure!);
    current = signed(provider);
    events.add(current);
    return current!;
  }

  @override
  Future<LocalAccount> link(LoginProvider provider) async {
    if (failure != null) throw AuthFailure(failure!);
    current = LocalAccount(
      uid: current!.uid,
      providers: {...current!.providers, provider},
    );
    events.add(current);
    return current!;
  }

  @override
  Future<LocalAccount?> refresh() async {
    if (failure != null) throw AuthFailure(failure!);
    return current;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    current = null;
    events.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    deletes++;
    current = null;
    events.add(null);
  }

  @override
  Future<void> dispose() => events.close();
}

class IdentityGateway extends FakeGateway
    implements SubscriptionIdentityGateway {
  final identities = <String?>[];
  Completer<void>? identityHold;
  @override
  Future<SubscriptionAccess> identify(String? uid) async {
    identities.add(uid);
    await identityHold?.future;
    return uid == null ? const SubscriptionAccess() : signed;
  }
}

class DelayedCustomerGateway extends IdentityGateway {
  Completer<SubscriptionAccess>? heldCustomer;
  @override
  Future<SubscriptionAccess> customer({bool refresh = false}) =>
      heldCustomer?.future ?? super.customer(refresh: refresh);
}

void main() {
  late FakeAuth gateway;
  late AuthController auth;
  late bool enabled;
  late List<String?> identities;
  setUp(() {
    gateway = FakeAuth();
    enabled = false;
    identities = [];
    auth = AuthController(
      gateway: gateway,
      readEnabled: () async => enabled,
      writeEnabled: (value) async => enabled = value,
      identifyBilling: (uid) async {
        identities.add(uid);
      },
    );
  });
  tearDown(() => auth.dispose());
  test('guest starts without Firebase initialization or an account', () async {
    await auth.initialize();
    expect(gateway.initializes, 0);
    expect(auth.account, isNull);
    expect(enabled, isFalse);
  });
  for (final provider in LoginProvider.values) {
    test(
      '${provider.name} success uses stable verified UID and no email identity',
      () async {
        await auth.login(provider);
        expect(auth.account?.providers, {provider});
        expect(identities.last, 'verified-firebase-uid');
        expect(enabled, isTrue);
      },
    );
    for (final failure in [
      AuthMessage.cancelled,
      AuthMessage.failed,
      AuthMessage.network,
    ]) {
      test('${provider.name} $failure preserves guest access', () async {
        gateway.failure = failure;
        await auth.login(provider);
        expect(auth.account, isNull);
        expect(auth.message, failure);
        expect(auth.busy, isFalse);
      });
    }
  }
  test(
    'linking providers preserves UID and conflict never merges identities',
    () async {
      await auth.login(LoginProvider.google);
      final uid = auth.account!.uid;
      await auth.login(LoginProvider.apple);
      expect(auth.account!.uid, uid);
      expect(auth.account!.providers.length, 2);
      gateway.failure = AuthMessage.conflict;
      await auth.login(LoginProvider.apple);
      expect(auth.account!.uid, uid);
      expect(auth.message, AuthMessage.conflict);
    },
  );
  test('logout clears identity, preserves local library', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = LocalEntryRepository(db);
    await repo.save(
      const EntryDraft(
        title: 'Keep this recipe',
        category: EntryCategory.recipes,
      ),
    );
    await auth.login(LoginProvider.google);
    await auth.logout();
    expect(auth.account, isNull);
    expect(identities.last, isNull);
    expect(enabled, isFalse);
    expect((await repo.watchEntries().first).single.title, 'Keep this recipe');
    await db.close();
  });
  test(
    'guest to account, linking and deletion never mutate local entries',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = LocalEntryRepository(db);
      await repo.save(
        const EntryDraft(
          title: 'My saved book',
          category: EntryCategory.reading,
        ),
      );
      final before = await db.select(db.savedEntries).get();
      await auth.login(LoginProvider.apple);
      await auth.login(LoginProvider.google);
      await auth.deleteAccount();
      expect(await db.select(db.savedEntries).get(), before);
      expect(gateway.deletes, 1);
      expect(auth.message, AuthMessage.deleted);
      await db.close();
    },
  );
  test(
    'offline refresh retains session; revoked refresh returns to guest',
    () async {
      await auth.login(LoginProvider.apple);
      gateway.failure = AuthMessage.network;
      await auth.refresh();
      expect(auth.account, isNotNull);
      gateway.failure = AuthMessage.revoked;
      await auth.refresh();
      expect(auth.account, isNull);
      expect(identities.last, isNull);
      expect(auth.message, AuthMessage.revoked);
    },
  );
  test(
    'relaunch restores enabled provider session and subscription identity',
    () async {
      enabled = true;
      gateway.current = gateway.signed(LoginProvider.google);
      await auth.initialize();
      expect(auth.account!.uid, 'verified-firebase-uid');
      expect(identities.last, auth.account!.uid);
    },
  );
  test(
    'stale keychain session is not silently linked after fresh install',
    () async {
      gateway.current = const LocalAccount(
        uid: 'old-install-user',
        providers: {LoginProvider.apple},
      );
      await auth.login(LoginProvider.google);
      expect(auth.account!.uid, 'verified-firebase-uid');
      expect(identities, isNot(contains('old-install-user')));
    },
  );
  test(
    'billing failure cannot erase authenticated session or local access',
    () async {
      auth.dispose();
      auth = AuthController(
        gateway: FakeAuth(),
        readEnabled: () async => false,
        writeEnabled: (_) async {},
        identifyBilling: (_) async => throw StateError('offline'),
      );
      await auth.login(LoginProvider.google);
      expect(auth.account, isNotNull);
      expect(auth.message, AuthMessage.billingSync);
    },
  );
  test('RevenueCat guest/account/logout transitions serialize and reject stale access', () async {
    final billingGateway = IdentityGateway();
    final billing = SubscriptionController(
      gateway: billingGateway,
      config: const TestReleaseConfig(),
      readConsent: () async => true,
      writeConsent: () async {},
      clock: () => billingGateway.now,
    );
    await billing.initialize();
    expect(billingGateway.identities, [null]);
    await billing.setAccountIdentity('firebase-google');
    expect(billing.hasPro, isTrue);
    billingGateway.identityHold = Completer<void>();
    final logout = billing.setAccountIdentity(null);
    expect(billing.hasPro, isFalse);
    final apple = billing.setAccountIdentity('firebase-apple');
    billingGateway.identityHold!.complete();
    await Future.wait([logout, apple]);
    expect(billingGateway.identities.last, 'firebase-apple');
    expect(billing.hasPro, isTrue);
    await billing.restore();
    expect(billingGateway.restores, 1);
    await billing.setAccountIdentity(null);
    expect(billing.hasPro, isFalse);
    billing.dispose();
  });
  test(
    'old in-flight refresh cannot replace the next account entitlement',
    () async {
      final gateway = DelayedCustomerGateway();
      final billing = SubscriptionController(
        gateway: gateway,
        config: const TestReleaseConfig(),
        readConsent: () async => true,
        writeConsent: () async {},
        clock: () => gateway.now,
      );
      await billing.initialize();
      await billing.refresh();
      await billing.setAccountIdentity('first');
      gateway.heldCustomer = Completer<SubscriptionAccess>();
      final stale = billing.refresh();
      await billing.setAccountIdentity('second');
      expect(billing.hasPro, isTrue);
      gateway.heldCustomer!.complete(const SubscriptionAccess());
      await stale;
      expect(billing.hasPro, isTrue);
      billing.dispose();
    },
  );
}
