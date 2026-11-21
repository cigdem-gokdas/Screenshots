import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../billing/subscription_controller.dart';
import '../../billing/subscription_models.dart';
import '../../l10n/app_localizations.dart';
import '../design.dart';
import 'legal_screen.dart';

String billingMessage(BillingMessage message, AppLocalizations l) =>
    switch (message) {
      BillingMessage.purchased => l.purchaseSuccess,
      BillingMessage.restored => l.restoreSuccess,
      BillingMessage.noPurchases => l.restoreEmpty,
      BillingMessage.cancelled => l.purchaseCancelled,
      BillingMessage.pending => l.purchasePending,
      BillingMessage.failed => l.purchaseFailed,
      BillingMessage.unavailable => l.billingUnavailable,
    };

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.billing});
  final SubscriptionController billing;
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionPeriod selected = SubscriptionPeriod.yearly;
  SubscriptionController get billing => widget.billing;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: billing,
    builder: (context, _) {
      final l = context.l;
      final selectedOffer =
          billing.offers.where((o) => o.period == selected).firstOrNull ??
          billing.offers.firstOrNull;
      return Scaffold(
        appBar: AppBar(title: Text(l.proTitle)),
        body: SafeArea(
          child: PageBody(
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  CupertinoIcons.sparkles,
                  size: 34,
                  color: context.c.accent,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l.proHeadline,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 18),
              Text(l.proBenefits, style: const TextStyle(height: 1.9)),
              const SizedBox(height: 18),
              Text(l.freeAlways, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              if (billing.hasPro)
                Text(
                  l.proActive,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (!billing.consented) ...[
                Text(l.billingDisclosure, style: const TextStyle(height: 1.8)),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('billing-consent'),
                  onPressed: billing.busy
                      ? null
                      : () => billing.start(userConsented: true),
                  child: Text(l.viewPlans),
                ),
              ] else ...[
                for (final offer in [
                  ...billing.offers.where(
                    (o) => o.period == SubscriptionPeriod.yearly,
                  ),
                  ...billing.offers.where(
                    (o) => o.period != SubscriptionPeriod.yearly,
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlanCard(
                      key: Key('purchase-${offer.period.name}'),
                      selected: selectedOffer?.period == offer.period,
                      label: offer.period == SubscriptionPeriod.monthly
                          ? l.monthlyPrice(offer.localizedPrice)
                          : l.yearlyPrice(offer.localizedPrice),
                      badge: offer.period == SubscriptionPeriod.yearly
                          ? l.bestValue
                          : null,
                      onTap: () => setState(() => selected = offer.period),
                    ),
                  ),
                if (selectedOffer != null) ...[
                  const SizedBox(height: 6),
                  FilledButton(
                    key: const Key('purchase-continue'),
                    onPressed:
                        billing.busy ||
                            billing.purchasePending ||
                            billing.hasPro ||
                            !billing.config.canSell
                        ? null
                        : () => billing.purchase(selectedOffer),
                    child: Text(l.continueLabel),
                  ),
                ],
                if (billing.offers.isEmpty && !billing.busy)
                  TextButton(
                    onPressed: () => billing.start(),
                    child: Text(l.retry),
                  ),
              ],
              if (billing.busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (billing.message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(billingMessage(billing.message!, l)),
                  ),
                ),
              if (!billing.config.canSell)
                Text(
                  l.billingUnavailable,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              Text(
                l.subscriptionTerms,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                children: [
                  for (final item in [
                    (
                      const Key('restore-purchases'),
                      l.restorePurchases,
                      billing.busy
                          ? null
                          : () async {
                              if (!billing.ready) {
                                await billing.start(userConsented: true);
                              }
                              if (billing.ready) await billing.restore();
                            },
                    ),
                    (
                      const Key('paywall-privacy'),
                      l.privacyPolicy,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LegalScreen(
                            privacy: true,
                            config: billing.config,
                          ),
                        ),
                      ),
                    ),
                    (
                      const Key('paywall-terms'),
                      l.termsOfUse,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LegalScreen(
                            privacy: false,
                            config: billing.config,
                          ),
                        ),
                      ),
                    ),
                    (
                      const Key('paywall-close'),
                      l.notNow,
                      () => Navigator.pop(context),
                    ),
                  ])
                    Expanded(
                      child: TextButton(
                        key: item.$1,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                        onPressed: item.$3,
                        child: Text(
                          item.$2,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Selectable plan: a tinted card with a radio mark, no borders.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.selected,
    required this.label,
    required this.badge,
    required this.onTap,
  });
  final bool selected;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.accentTint : c.card,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: selected ? c.accent : c.muted,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
