import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../sync/screenshot_sync.dart';
import '../../sync/sync_models.dart';
import '../design.dart';
import '../sync_presentation.dart';
import 'photo_access_section.dart';

class SyncSettingsSection extends StatefulWidget {
  const SyncSettingsSection({super.key, required this.sync, this.onRequirePro});
  final ScreenshotSync sync;
  final Future<void> Function()? onRequirePro;
  @override
  State<SyncSettingsSection> createState() => _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends State<SyncSettingsSection> {
  bool actionBusy = false;
  Future<void> _perform(Future<void> Function() action) async {
    if (actionBusy) return;
    setState(() => actionBusy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showError(context, context.l.actionError);
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Future<void> toggle(bool value) async {
    if (!value) {
      await _perform(widget.sync.disable);
      return;
    }
    if (!widget.sync.automationAllowed) {
      await widget.onRequirePro?.call();
      return;
    }
    final accepted = await photoPrePrompt(context);
    if (accepted == true && mounted) {
      await _perform(() => widget.sync.enable(includeExisting: true));
    }
  }

  Future<void> history() async {
    final l = context.l;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.importExistingTitle),
        content: Text(l.importExistingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.importExisting),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) await _perform(widget.sync.importExisting);
  }

  Future<void> erase() async {
    final l = context.l;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteImportedTitle),
        content: Text(l.deleteImportedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              l.deleteConfirm,
              style: TextStyle(color: context.c.danger),
            ),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await _perform(widget.sync.deleteImportedData);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.sync,
    builder: (context, _) {
      final l = context.l;
      final sync = widget.sync;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            key: const Key('automatic-sync-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.autoSync,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            value: sync.config.enabled,
            onChanged: actionBusy || !sync.initialized || !sync.supported
                ? null
                : toggle,
          ),
          if (!sync.automationAllowed)
            Text(l.autoSyncPro, style: Theme.of(context).textTheme.bodySmall),
          if (!sync.supported)
            Text(l.syncIOSOnly, style: Theme.of(context).textTheme.bodySmall)
          else ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  sync.busy
                      ? CupertinoIcons.arrow_2_circlepath
                      : CupertinoIcons.circle,
                  size: 15,
                  color: context.c.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.syncStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          syncLabel(sync, l),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              l.lastSync,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              sync.config.lastSuccess == null
                  ? l.neverSynced
                  : DateFormat.yMMMd(l.localeName)
                        .add_Hm()
                        .format(sync.config.lastSuccess!.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Text(
              l.photoPermission,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              sync.permissionKnown
                  ? permissionLabel(sync.permission, l)
                  : l.photoAccessUnavailable,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (sync.config.enabled &&
                sync.permission != PhotoAccess.authorized)
              TextButton(
                onPressed: actionBusy
                    ? null
                    : () => _perform(sync.library.openSettings),
                child: Text(l.openPhotoSettings),
              ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle,
                  size: 17,
                  color: context.c.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.newOnly,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.newOnlyBody, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: sync.config.enabled && !actionBusy ? history : null,
              icon: const Icon(CupertinoIcons.clock, size: 16),
              label: Text(
                l.importExisting,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (sync.config.historyRequested)
              Text(
                l.syncHistoryPending,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (sync.activity == SyncActivity.error ||
                sync.activity == SyncActivity.waiting)
              TextButton(
                onPressed: actionBusy ? null : () => _perform(sync.retry),
                child: Text(l.retry),
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('delete-imported-data'),
              onPressed: actionBusy ? null : erase,
              style: TextButton.styleFrom(foregroundColor: context.c.danger),
              icon: const Icon(CupertinoIcons.trash, size: 16),
              label: Text(
                l.deleteImported,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      );
    },
  );
}
