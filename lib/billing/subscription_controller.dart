import 'dart:async';

import 'package:flutter/foundation.dart';

import 'subscription_models.dart';
import '../config/release_config.dart';

class SubscriptionController extends ChangeNotifier {
  SubscriptionController({
    required this.gateway,
    required this.readConsent,
    required this.writeConsent,
    required this.config,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final SubscriptionGateway gateway;
  final Future<bool> Function() readConsent;
  final Future<void> Function() writeConsent;
  final ReleaseConfig config;
  final DateTime Function() clock;
  SubscriptionAccess access = const SubscriptionAccess();
  List<SubscriptionOffer> offers = [];
  BillingMessage? message;
  bool ready = false, busy = false, consented = false, _disposed = false;
  bool purchasePending = false;
  Future<void>? _starting, _refreshing;
  Timer? _expiryTimer;
  String? _desiredUid;
  int _identityRevision = 0;
  bool _identityChanging = false;
  Future<void>? _identityWork;
  Completer<void>? _storeOperation;
  bool get hasPro => !_identityChanging && access.allows(clock());

  /// Clears old-account access immediately. Serializes SDK transitions with a
  /// store sheet, and coalesces rapid changes without creating guest IDs on boot.
  Future<void> setAccountIdentity(String? uid) async {
    _identityRevision++;
    _desiredUid = uid;
    access = const SubscriptionAccess();
    _identityChanging = ready;
    _notify();
    if (!ready) return;
    await (_identityWork ??= _identify().whenComplete(
      () => _identityWork = null,
    ));
  }

  Future<void> _identify() async {
    await _storeOperation?.future;
    final identity = gateway;
    if (identity is! SubscriptionIdentityGateway) {
      _identityChanging = false;
      return;
    }
    try {
      while (true) {
        final target = _desiredUid;
        final value = await (identity as SubscriptionIdentityGateway).identify(
          target,
        );
        if (target != _desiredUid) continue;
        access = value;
        purchasePending = false;
        _identityChanging = false;
        _notify();
        return;
      }
    } catch (_) {
      // Keep commerce locked until a successful retry, never old-account Pro.
      access = const SubscriptionAccess();
      message = BillingMessage.unavailable;
      _notify();
      rethrow;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _update(SubscriptionAccess value) {
    if (_identityChanging) return;
    access = value;
    if (hasPro) {
      purchasePending = false;
      if (message == BillingMessage.pending) message = BillingMessage.purchased;
    }
    _notify();
  }

  Future<void> initialize() async {
    try {
      consented = await readConsent();
      if (consented && config.billingConfigured) await start();
    } catch (_) {
      message = BillingMessage.unavailable;
      _notify();
    }
  }

  /// Persisted consent only enables SDK initialization; it never grants Pro.
  Future<void> start({bool userConsented = false}) {
    if (_starting != null) return _starting!;
    return _starting = _start(userConsented)
        .whenComplete(() => _starting = null);
  }

  Future<void> _start(bool userConsented) async {
    if (!config.billingConfigured || (!consented && !userConsented)) {
      message = BillingMessage.unavailable;
      _notify();
      return;
    }
    busy = true;
    message = null;
    _notify();
    try {
      if (!consented) {
        await writeConsent();
        consented = true;
      }
      if (!ready) {
        // Configuration is local; network fetches below have bounded waits.
        await gateway.initialize(_update).timeout(ReleaseConfig.requestTimeout);
        if (_disposed) return;
        ready = true;
        _expiryTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _notify(),
        );
      }
      await setAccountIdentity(_desiredUid);
      final revision = _identityRevision;
      final current = await gateway.customer().timeout(
        ReleaseConfig.requestTimeout,
      );
      if (revision == _identityRevision) _update(current);
      unawaited(refresh());
      offers = await gateway.offers().timeout(ReleaseConfig.requestTimeout);
      if (offers.isEmpty) message = BillingMessage.unavailable;
    } catch (_) {
      message = BillingMessage.unavailable;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> refresh() {
    if (!ready || _disposed) return Future.value();
    if (_identityChanging) return setAccountIdentity(_desiredUid);
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    final revision = _identityRevision;
    try {
      final value = await gateway
          .customer(refresh: true)
          .timeout(ReleaseConfig.requestTimeout);
      if (revision == _identityRevision) _update(value);
    } catch (_) {
      message = BillingMessage.unavailable;
      _notify();
    } // Valid provider cache may remain until expiry/window.
  }

  Future<void> purchase(SubscriptionOffer offer) async {
    if (busy ||
        _identityChanging ||
        purchasePending ||
        !ready ||
        !config.canSell ||
        !offers.any((o) => o.id == offer.id)) {
      return;
    }
    await _transaction(() => gateway.purchase(offer.id), restoring: false);
  }

  Future<void> restore() async {
    if (busy || _identityChanging) return;
    if (!ready) {
      message = BillingMessage.unavailable;
      _notify();
      return;
    }
    await _transaction(gateway.restore, restoring: true);
  }

  Future<void> _transaction(
    Future<SubscriptionAccess> Function() action, {
    required bool restoring,
  }) async {
    busy = true;
    _storeOperation = Completer<void>();
    message = null;
    _notify();
    // A store sheet may stay open for approval. Never retry or release the
    // mutation lock merely because a UI deadline passed: that risks double buys.
    final pendingTimer = Timer(const Duration(minutes: 2), () {
      message = BillingMessage.pending;
      _notify();
    });
    try {
      _update(await action());
      purchasePending = !hasPro && !restoring;
      message = hasPro
          ? (restoring ? BillingMessage.restored : BillingMessage.purchased)
          : (restoring ? BillingMessage.noPurchases : BillingMessage.pending);
    } on BillingFailure catch (e) {
      message = e.message;
      purchasePending = e.message == BillingMessage.pending;
    } catch (_) {
      message = BillingMessage.failed;
    } finally {
      pendingTimer.cancel();
      _storeOperation?.complete();
      _storeOperation = null;
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    gateway.dispose();
    super.dispose();
  }
}
