import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/sync/photo_manager_library.dart';
import '../../sync/screenshot_sync.dart';
import '../../sync/sync_models.dart';
import '../design.dart';
import '../sync_presentation.dart';

Future<bool?> photoPrePrompt(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(CupertinoIcons.photo_on_rectangle, size: 30),
                ),
                const SizedBox(height: 22),
                Text(
                  c.l.photoPromptTitle,
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(c.l.photoPromptBody),
                const SizedBox(height: 14),
                Text(c.l.localAnalysis, style: Theme.of(c).textTheme.bodySmall),
                const SizedBox(height: 22),
                FilledButton(
                  key: const Key('photo-permission-primary'),
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(c.l.findScreenshots),
                ),
                TextButton(
                  key: const Key('photo-permission-manual'),
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(c.l.pickMyself),
                ),
              ],
            ),
          ),
        ),
      ),
    );

class PhotoAccessSection extends StatefulWidget {
  const PhotoAccessSection({
    super.key,
    required this.sync,
    required this.onManual,
    this.compact = false,
  });
  final ScreenshotSync sync;
  final VoidCallback onManual;
  final bool compact;
  @override
  State<PhotoAccessSection> createState() => _PhotoAccessSectionState();
}

class _PhotoAccessSectionState extends State<PhotoAccessSection> {
  bool busy = false;
  Future<void> action(Future<void> Function() work) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await work();
    } catch (_) {
      if (mounted) showError(context, context.l.actionError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> manage() async {
    final sync = widget.sync;
    if (sync.permission == PhotoAccess.limited &&
        sync.library is LimitedPhotoAccessManager) {
      await (sync.library as LimitedPhotoAccessManager).manageLimitedAccess();
      await sync.refreshPermission();
      await sync.reconcile();
    } else if (sync.permission == PhotoAccess.notDetermined) {
      final accepted = await photoPrePrompt(context);
      if (accepted == true) {
        await sync.enable(includeExisting: true);
      } else if (accepted == false) {
        widget.onManual();
      }
    } else {
      if (sync.permission == PhotoAccess.denied) {
        // The explicit Settings action opts into discovery after an OS grant;
        // enable reads denied status and never requests the native popup again.
        await sync.enable(includeExisting: true);
      }
      await sync.library.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.sync,
    builder: (context, _) {
      final l = context.l, sync = widget.sync;
      if (!sync.supported || !sync.initialized) return const SizedBox.shrink();
      if (widget.compact &&
          sync.permissionKnown &&
          sync.permission == PhotoAccess.authorized) {
        return const SizedBox.shrink();
      }
      final body = !sync.permissionKnown
          ? l.photoAccessUnavailable
          : switch (sync.permission) {
              PhotoAccess.limited => l.photoLimitedBody,
              PhotoAccess.denied => l.photoDeniedBody,
              PhotoAccess.restricted => l.photoRestrictedBody,
              PhotoAccess.notDetermined => l.photoPromptBody,
              PhotoAccess.authorized => l.photoFullBody,
            };
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.compact) ...[
              Text(
                l.photoAccessSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                sync.permissionKnown
                    ? permissionLabel(sync.permission, l)
                    : l.photoAccessUnavailable,
              ),
              const SizedBox(height: 8),
            ],
            Text(body, style: const TextStyle(fontSize: 13, height: 1.65)),
            const SizedBox(height: 14),
            if (!sync.permissionKnown)
              FilledButton(
                onPressed: busy ? null : () => action(sync.refreshPermission),
                child: Text(l.retry),
              )
            else if (sync.permission != PhotoAccess.restricted)
              FilledButton(
                onPressed: busy ? null : () => action(manage),
                child: Text(switch (sync.permission) {
                  PhotoAccess.limited => l.manageAccess,
                  PhotoAccess.notDetermined => l.findScreenshots,
                  _ => widget.compact ? l.allowInSettings : l.openSettings,
                }),
              ),
            if (!sync.permissionKnown ||
                sync.permission != PhotoAccess.restricted)
              const SizedBox(height: 8),
            sync.permissionKnown && sync.permission == PhotoAccess.restricted
                ? FilledButton(
                    onPressed: busy ? null : widget.onManual,
                    child: Text(l.selectPhotos),
                  )
                : FilledButton.tonal(
                    onPressed: busy ? null : widget.onManual,
                    child: Text(l.selectPhotos),
                  ),
          ],
        ),
      );
    },
  );
}
