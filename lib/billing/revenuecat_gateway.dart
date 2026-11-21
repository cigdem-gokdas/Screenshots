import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/release_config.dart';
import 'subscription_models.dart';

class RevenueCatGateway
    implements SubscriptionGateway, SubscriptionIdentityGateway {
  RevenueCatGateway(this.config);
  final ReleaseConfig config;
  final Map<String, Package> _packages = {};
  void Function(CustomerInfo)? _listener;
  Future<void>? _configuration;
  bool _disposed = false;

  @override
  Future<void> initialize(void Function(SubscriptionAccess) onUpdate) =>
      _configuration ??= _initialize(onUpdate);
  Future<void> _initialize(void Function(SubscriptionAccess) onUpdate) async {
    if (!config.billingConfigured) {
      throw const BillingFailure(BillingMessage.unavailable);
    }
    await Purchases.setLogLevel(LogLevel.error);
    Purchases.setLogHandler(
      (_, _) {},
    ); // Do not forward SDK payloads to app logs.
    final options = PurchasesConfiguration(config.publicKey)
      ..entitlementVerificationMode = EntitlementVerificationMode.informational
      ..automaticDeviceIdentifierCollectionEnabled = false
      ..diagnosticsEnabled = false;
    await Purchases.configure(options);
    if (_disposed) return;
    _listener = (info) => onUpdate(accessFromCustomer(info));
    Purchases.addCustomerInfoUpdateListener(_listener!);
  }

  static SubscriptionAccess accessFromCustomer(CustomerInfo info) {
    final pro = info.entitlements.all[ReleaseConfig.entitlement];
    return SubscriptionAccess(
      active: pro?.isActive == true,
      verified:
          pro?.verification == VerificationResult.verified ||
          pro?.verification == VerificationResult.verifiedOnDevice,
      expiresAt: DateTime.tryParse(pro?.expirationDate ?? ''),
      checkedAt: DateTime.tryParse(info.requestDate),
    );
  }

  @override
  Future<SubscriptionAccess> customer({bool refresh = false}) async {
    if (refresh) await Purchases.invalidateCustomerInfoCache();
    return accessFromCustomer(await Purchases.getCustomerInfo());
  }

  @override
  Future<List<SubscriptionOffer>> offers() async {
    final offering = (await Purchases.getOfferings()).all[config.offeringId];
    _packages.clear();
    final offers = <SubscriptionOffer>[];
    for (final package in offering?.availablePackages ?? <Package>[]) {
      final id = package.storeProduct.identifier;
      final period =
          id == config.monthlyId && package.packageType == PackageType.monthly
          ? SubscriptionPeriod.monthly
          : id == config.yearlyId && package.packageType == PackageType.annual
          ? SubscriptionPeriod.yearly
          : null;
      if (period == null) continue;
      _packages[id] = package;
      offers.add(
        SubscriptionOffer(
          id: id,
          period: period,
          localizedPrice: package.storeProduct.priceString,
        ),
      );
    }
    // Do not sell a misconfigured offering or invent prices/product periods.
    if (offers.map((o) => o.period).toSet().length != 2) return [];
    return offers;
  }

  @override
  Future<SubscriptionAccess> purchase(String offerId) async {
    final package = _packages[offerId];
    if (package == null || !config.canSell) {
      throw const BillingFailure(BillingMessage.unavailable);
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return accessFromCustomer(result.customerInfo);
    } on PlatformException catch (e) {
      throw BillingFailure(mapError(e));
    }
  }

  static BillingMessage mapError(PlatformException error) {
    final number = int.tryParse(error.code);
    if (number == PurchasesErrorCode.purchaseCancelledError.index) {
      return BillingMessage.cancelled;
    }
    if (number == PurchasesErrorCode.paymentPendingError.index) {
      return BillingMessage.pending;
    }
    return BillingMessage.failed;
  }

  @override
  Future<SubscriptionAccess> restore() async {
    try {
      return accessFromCustomer(await Purchases.restorePurchases());
    } on PlatformException catch (e) {
      throw BillingFailure(mapError(e));
    }
  }

  @override
  Future<SubscriptionAccess> identify(String? uid) async {
    if (uid != null) {
      if (await Purchases.appUserID != uid) {
        return accessFromCustomer((await Purchases.logIn(uid)).customerInfo);
      }
    } else if (!await Purchases.isAnonymous) {
      return accessFromCustomer(await Purchases.logOut());
    }
    return customer(refresh: true);
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
    }
  }
}
