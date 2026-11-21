import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/sync/import_media_store.dart';
import '../domain/entry.dart';
import 'design.dart';
import 'entry_actions.dart';

/// Loads a local screenshot copy once per file name (the future is cached in
/// state so rebuilds never restart the load).
class EntryImage extends StatefulWidget {
  const EntryImage({
    super.key,
    required this.name,
    required this.store,
    required this.builder,
    this.loading,
    this.fallback,
  });
  final String? name;
  final ImportMediaStore store;
  final Widget Function(BuildContext context, File file) builder;
  final Widget? loading, fallback;
  @override
  State<EntryImage> createState() => _EntryImageState();
}

class _EntryImageState extends State<EntryImage> {
  late Future<File?> future = _load();
  Future<File?> _load() async {
    try {
      return await widget.store.image(widget.name);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(EntryImage old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name || old.store != widget.store) {
      future = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return widget.loading ?? const SizedBox.shrink();
      }
      final file = snapshot.data;
      if (file == null) return widget.fallback ?? const SizedBox.shrink();
      return widget.builder(context, file);
    },
  );
}

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.hero = true,
  });
  final Entry entry;
  final VoidCallback onTap;

  /// Hero tags must be unique per route, so only one list per route sets this.
  final bool hero;
  static const double _leading = 52;

  Widget _leadingBox(BuildContext context) {
    final tone = entry.category.tone(context);
    final icon = Container(
      width: _leading,
      height: _leading,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(entry.category.icon, color: tone, size: 22),
    );
    final child = entry.imagePath == null
        ? icon
        : EntryImage(
            name: entry.imagePath,
            store: AppScope.of(context).media,
            loading: icon,
            fallback: icon,
            builder: (_, file) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                file,
                width: _leading,
                height: _leading,
                cacheWidth: 160,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => icon,
              ),
            ),
          );
    return hero ? Hero(tag: 'entry-${entry.id}', child: child) : child;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c, l = context.l;
    final done = entry.status == EntryStatus.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Dismissible(
          key: ValueKey('entry-${entry.id}'),
          background: _SwipeBackground(
            color: c.accentTint,
            foreground: c.accent,
            icon: done
                ? CupertinoIcons.arrow_counterclockwise
                : CupertinoIcons.checkmark_alt,
            label: done ? l.markTodo : l.markDone,
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _SwipeBackground(
            color: c.danger,
            foreground: c.onAccent,
            icon: CupertinoIcons.trash,
            label: l.deleteConfirm,
            alignment: Alignment.centerRight,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await toggleDone(context, entry);
              return false;
            }
            return true;
          },
          onDismissed: (_) => deleteWithUndo(context, entry),
          child: Material(
            color: c.card,
            child: InkWell(
              onTap: onTap,
              onLongPress: () => showEntryMenu(context, entry),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _leadingBox(context),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.category.label(l)} · ${entry.status.label(l)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: c.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.alignment,
  });
  final Color color, foreground;
  final IconData icon;
  final String label;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Container(
    color: color,
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

/// Placeholder rows shown while entries load.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 6});
  final int count;
  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  @override
  void initState() {
    super.initState();
    pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.line,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    final rows = Column(
      children: List.generate(
        widget.count,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(160, 14),
                    const SizedBox(height: 10),
                    bar(96, 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      label: context.l.appName,
      excludeSemantics: true,
      child: still
          ? rows
          : FadeTransition(
              opacity: Tween(begin: .55, end: 1.0).animate(pulse),
              child: rows,
            ),
    );
  }
}
