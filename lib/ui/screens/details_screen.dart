import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/app_controller.dart';
import '../../domain/entry.dart';
import '../../domain/link_host.dart';
import '../design.dart';
import '../entry_actions.dart';
import '../widgets.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.controller, required this.id});
  final AppController controller;
  final int id;
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool busy = false;
  Future<void> changeStatus(EntryStatus value) async {
    setState(() => busy = true);
    HapticFeedback.selectionClick();
    try {
      await widget.controller.repository.setStatus(widget.id, value);
    } catch (_) {
      if (mounted) showError(context, context.l.actionError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete(Entry entry) async {
    final l = context.l;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteTitle),
        content: Text(l.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: c.c.danger),
            child: Text(l.deleteConfirm),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    // The entry disappears at once; the snackbar on the screen below offers Undo.
    unawaited(deleteWithUndo(context, entry));
    Navigator.pop(context);
  }

  /// Links read from a screenshot (OCR) are confirmed with their host first.
  Future<void> open(Entry entry) async {
    final l = context.l;
    if (entry.sourceAssetKey != null) {
      final host = displayHost(entry.url);
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.linkConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.linkConfirmBody),
              const SizedBox(height: 14),
              SelectableText(
                host,
                key: const Key('link-host'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.cancel),
            ),
            TextButton(
              key: const Key('link-open-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.open),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await launch(entry.url);
  }

  Future<void> launch(String url) async {
    try {
      if (!EntryDraft.validUrl(url) ||
          !await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        if (mounted) showError(context, context.l.linkError);
      }
    } catch (_) {
      if (mounted) showError(context, context.l.linkError);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final l = context.l, c = context.c;
      final entry = widget.controller.entries
          .where((e) => e.id == widget.id)
          .firstOrNull;
      final tone = entry?.category.tone(context) ?? c.accent;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l.details,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            if (entry != null) ...[
              Builder(
                builder: (shareContext) => IconButton(
                  tooltip: l.share,
                  onPressed: busy
                      ? null
                      : () => shareEntry(shareContext, entry),
                  icon: const Icon(CupertinoIcons.share, size: 22),
                ),
              ),
              IconButton(
                tooltip: l.edit,
                onPressed: busy
                    ? null
                    : () =>
                          openEditor(context, widget.controller, entry: entry),
                icon: const Icon(CupertinoIcons.pencil, size: 22),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
        body: entry == null
            ? Center(child: Text(l.entryGone))
            : PageBody(
                children: [
                  if (entry.imagePath != null) ...[
                    const SizedBox(height: 6),
                    EntryImage(
                      name: entry.imagePath,
                      store: widget.controller.media,
                      loading: const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      fallback: Text(
                        l.imageUnavailable,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      builder: (_, file) => Semantics(
                        label: l.importedScreenshot,
                        image: true,
                        child: Hero(
                          tag: 'entry-${entry.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              file,
                              cacheWidth: 1000,
                              fit: BoxFit.contain,
                              height: 320,
                              errorBuilder: (_, _, _) =>
                                  Text(l.imageUnavailable),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.importedScreenshot,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (entry.capturedAt != null)
                      Text(
                        l.capturedOn(
                          DateFormat.yMMMd(l.localeName)
                              .add_Hm()
                              .format(entry.capturedAt!),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Hero(
                        tag: 'entry-${entry.id}',
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            entry.category.icon,
                            color: tone,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    entry.category.label(l),
                    style: TextStyle(
                      color: tone,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    entry.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.savedOn(
                      DateFormat.yMMMd(l.localeName).format(entry.createdAt),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    l.updatedOn(
                      DateFormat.yMMMd(l.localeName).format(entry.updatedAt),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l.statusLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EntryStatus.values
                        .map(
                          (s) => ChoiceChip(
                            avatar: Icon(s.icon, size: 15),
                            label: Text(
                              s.label(l),
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected: entry.status == s,
                            showCheckmark: false,
                            onSelected: busy ? null : (_) => changeStatus(s),
                          ),
                        )
                        .toList(),
                  ),
                  if (entry.description.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    Text(
                      l.notes,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      entry.description,
                      style: TextStyle(height: 1.8, color: c.muted),
                    ),
                  ],
                  if (entry.url.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            entry.url,
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            key: const Key('open-link'),
                            onPressed: () => open(entry),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l.openLink),
                                const SizedBox(width: 8),
                                const Icon(
                                  CupertinoIcons.arrow_up_right,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: busy ? null : () => delete(entry),
                      style: TextButton.styleFrom(foregroundColor: c.danger),
                      icon: const Icon(CupertinoIcons.trash, size: 18),
                      label: Text(l.delete),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}
