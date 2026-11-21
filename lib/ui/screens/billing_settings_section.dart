import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../billing/subscription_controller.dart';
import '../design.dart';
import 'paywall_screen.dart';

Future<void> showPro(BuildContext context, SubscriptionController billing) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PaywallScreen(billing: billing)),
    );

class BillingSettingsSection extends StatelessWidget {
  const BillingSettingsSection({super.key, required this.billing});
  final SubscriptionController billing;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: billing,
    builder: (context, _) {
      final l = context.l;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(CupertinoIcons.sparkles, color: context.c.accent),
            title: Text(billing.hasPro ? l.proActive : l.freePlan),
            subtitle: Text(l.freeAlways),
            trailing: billing.hasPro ? Text(l.proBadge) : null,
            onTap: () => showPro(context, billing),
          ),
          if (!billing.hasPro)
            TextButton(
              onPressed: () => showPro(context, billing),
              child: Text(l.upgradePro),
            ),
          TextButton(
            onPressed: billing.busy
                ? null
                : () async {
                    if (!billing.ready) {
                      await showPro(context, billing);
                      return;
                    }
                    await billing.restore();
                    if (context.mounted && billing.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(billingMessage(billing.message!, l)),
                        ),
                      );
                    }
                  },
            child: Text(l.restorePurchases),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(
                Platform.isIOS
                    ? 'https://apps.apple.com/account/subscriptions'
                    : 'https://play.google.com/store/account/subscriptions',
              );
              try {
                if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    ) &&
                    context.mounted) {
                  showError(context, l.linkError);
                }
              } catch (_) {
                if (context.mounted) showError(context, l.linkError);
              }
            },
            child: Text(l.manageSubscription),
          ),
        ],
      );
    },
  );
}
