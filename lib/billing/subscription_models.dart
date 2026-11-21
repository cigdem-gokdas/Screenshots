import '../config/release_config.dart';

enum BillingMessage {
  purchased,
  restored,
  noPurchases,
  cancelled,
  pending,
  failed,
  unavailable,
}

enum SubscriptionPeriod { monthly, yearly }

class SubscriptionOffer {
  const SubscriptionOffer({
    required this.id,
    required this.period,
    required this.localizedPrice,
  });
  final String id, localizedPrice;
  final SubscriptionPeriod period;
}

/// Produced only from the subscription provider's CustomerInfo, never a local
/// preference. Cached signatures are honored only within expiry and 72 hours.
class SubscriptionAccess {
  const SubscriptionAccess({
    this.active = false,
    this.verified = false,
    this.expiresAt,
    this.checkedAt,
  });
  final bool active, verified;
  final DateTime? expiresAt, checkedAt;
  bool allows(DateTime now) =>
      active &&
      verified &&
      expiresAt != null &&
      checkedAt != null &&
      now.toUtc().isBefore(expiresAt!.toUtc()) &&
      now.toUtc().difference(checkedAt!.toUtc()) <=
          ReleaseConfig.offlineAccessWindow &&
      !checkedAt!.toUtc().isAfter(now.toUtc().add(const Duration(minutes: 5)));
}

class BillingFailure implements Exception {
  const BillingFailure(this.message);
  final BillingMessage message;
}

abstract interface class SubscriptionGateway {
  Future<void> initialize(void Function(SubscriptionAccess) onUpdate);
  Future<SubscriptionAccess> customer({bool refresh = false});
  Future<List<SubscriptionOffer>> offers();
  Future<SubscriptionAccess> purchase(String offerId);
  Future<SubscriptionAccess> restore();
  void dispose();
}

/// Optional identity capability; no auth SDK dependency in billing models.
abstract interface class SubscriptionIdentityGateway {
  Future<SubscriptionAccess> identify(String? uid);
}
