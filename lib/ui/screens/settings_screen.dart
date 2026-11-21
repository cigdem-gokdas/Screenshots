import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/app_info.dart';
import '../design.dart';
import 'sync_settings_section.dart';
import 'billing_settings_section.dart';
import 'legal_screen.dart';
import 'photo_access_section.dart';
import 'account_section.dart';
import 'import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;
  Future<void> change(String? value) async {
    setState(() => busy = true);
    try {
      await widget.controller.changeLanguage(value);
    } catch (_) {
      if (mounted) showError(context, context.l.actionError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, c = context.c;
    final controller = widget.controller;
    return PageBody(
      topBar: AppSliverBar(title: l.settings),
      children: [
        const SizedBox(height: 8),
        if (controller.sync != null)
          PhotoAccessSection(
            sync: controller.sync!,
            onManual: () {
              if (controller.importer == null) return;
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ImportScreen(
                    service: controller.importer!,
                    autoSelect: true,
                  ),
                ),
              );
            },
          ),
        if (controller.sync != null)
          SettingsGroup(
            child: SyncSettingsSection(
              sync: controller.sync!,
              onRequirePro: controller.billing == null
                  ? null
                  : () => showPro(context, controller.billing!),
            ),
          ),
        if (controller.billing != null)
          SettingsGroup(
            child: BillingSettingsSection(billing: controller.billing!),
          ),
        SettingsGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.language, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                l.languageSubtitle,
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ...<String?, String>{
                null: l.systemLanguage,
                'tr': l.turkish,
                'en': l.english,
              }.entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 48,
                  title: Text(e.value, style: const TextStyle(fontSize: 14)),
                  onTap: busy ? null : () => change(e.key),
                  trailing: controller.language == e.key
                      ? Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: c.accent,
                          size: 22,
                        )
                      : Icon(CupertinoIcons.circle, color: c.muted, size: 22),
                ),
              ),
            ],
          ),
        ),
        if (controller.auth != null)
          SettingsGroup(child: AccountSection(auth: controller.auth!)),
        SettingsGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.privacyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                l.privacyBody,
                style: TextStyle(color: c.muted, height: 1.7),
              ),
              const SizedBox(height: 10),
              Text(
                l.privacyNote,
                style: TextStyle(color: c.muted, height: 1.7),
              ),
              const SizedBox(height: 22),
              Text(
                l.storageTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                l.storageBody,
                style: TextStyle(color: c.muted, height: 1.7),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                title: Text(l.privacyPolicy),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: c.muted,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalScreen(privacy: true),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                title: Text(l.termsOfUse),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: c.muted,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalScreen(privacy: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.appName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          l.versionLabel(appVersion),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
