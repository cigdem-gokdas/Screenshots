import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/release_config.dart';
import '../design.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.privacy,
    this.config = const ReleaseConfig(),
  });
  final bool privacy;
  final ReleaseConfig config;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final url = privacy ? config.privacyUrl : config.termsUrl;
    return Scaffold(
      appBar: AppBar(title: Text(privacy ? l.privacyPolicy : l.termsOfUse)),
      body: SafeArea(
        child: PageBody(
          children: [
            const SizedBox(height: 20),
            Text(
              privacy ? l.privacyPolicy : l.termsOfUse,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            SelectableText(
              privacy ? l.privacyPolicyBody : l.termsBody,
              style: const TextStyle(height: 1.9),
            ),
            const SizedBox(height: 24),
            if (ReleaseConfig.publicHttps(url))
              FilledButton(
                onPressed: () async {
                  try {
                    if (!await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        ) &&
                        context.mounted) {
                      showError(context, l.linkError);
                    }
                  } catch (_) {
                    if (context.mounted) showError(context, l.linkError);
                  }
                },
                child: Text(l.readPublishedPolicy),
              )
            else
              Text(
                l.legalDraftNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
