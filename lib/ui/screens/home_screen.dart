import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/entry.dart';
import '../design.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.entries,
    required this.onCategory,
    required this.onReview,
    required this.onAdd,
    this.onImport,
    this.onRefresh,
    this.syncStatus,
  });
  final Widget? syncStatus;
  final List<Entry> entries;
  final ValueChanged<EntryCategory> onCategory;
  final VoidCallback onReview, onAdd;
  final VoidCallback? onImport;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    return PageBody(
      onRefresh: onRefresh,
      topBar: AppSliverBar(
        actions: [
          if (onImport != null)
            IconButton(
              tooltip: l.importScreenshots,
              onPressed: onImport,
              icon: const Icon(CupertinoIcons.photo, size: 21),
            ),
          IconButton(
            tooltip: l.addEntry,
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add, size: 23),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 4),
        Eyebrow(l.homeEyebrow),
        const SizedBox(height: 16),
        Text(l.homeTitle, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          l.homeSubtitle,
          style: TextStyle(color: c.muted, fontSize: 13, height: 1.65),
        ),
        if (syncStatus != null) ...[const SizedBox(height: 12), syncStatus!],
        const SizedBox(height: 28),
        if (entries.isEmpty)
          _StarterCard(onImport: onImport, onAdd: onAdd)
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l.yourCollections,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${entries.length}',
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CollectionGrid(entries: entries, onCategory: onCategory),
          const SizedBox(height: 20),
          _ReviewLink(onTap: onReview),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: Text(l.addEntry),
          ),
        ],
      ],
    );
  }
}

/// Shown instead of the empty collection grid.
class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.onImport, required this.onAdd});
  final VoidCallback? onImport;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final l = context.l, c = context.c;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.noEntries, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l.noEntriesBody,
            style: TextStyle(color: c.muted, fontSize: 13, height: 1.65),
          ),
          const SizedBox(height: 22),
          if (onImport != null) ...[
            FilledButton(
              key: const Key('starter-import'),
              onPressed: onImport,
              child: Text(l.starterImport),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              key: const Key('starter-add'),
              onPressed: onAdd,
              child: Text(l.addManually),
            ),
          ] else
            FilledButton(
              key: const Key('starter-add'),
              onPressed: onAdd,
              child: Text(l.addManually),
            ),
        ],
      ),
    );
  }
}

class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({required this.entries, required this.onCategory});
  final List<Entry> entries;
  final ValueChanged<EntryCategory> onCategory;
  @override
  Widget build(BuildContext context) {
    final l = context.l, c = context.c;
    final scaler = MediaQuery.textScalerOf(context);
    // One column at large text sizes so labels never wrap awkwardly; the tile
    // height follows the scaled text instead of a fixed guess.
    final single = scaler.scale(14) / 14 > 1.35;
    final labelHeight = scaler.scale(14) * 1.3;
    final countHeight = scaler.scale(12) * 1.4;
    final extent =
        34 + 26 + 10 + labelHeight * (single ? 1 : 2) + 4 + countHeight;
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: EntryCategory.values.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: single ? 1 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: extent < 148 ? 148 : extent,
      ),
      itemBuilder: (context, index) {
        final category = EntryCategory.values[index];
        final tone = category.tone(context);
        final count = entries.where((e) => e.category == category).length;
        final label = category.label(l);
        return Semantics(
          button: true,
          label: '$label, ${l.itemCount(count)}',
          excludeSemantics: true,
          onTap: () => onCategory(category),
          child: Material(
            color: tone.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onCategory(category),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(category.icon, size: 26, color: tone),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: c.muted,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      label,
                      maxLines: single ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.itemCount(count),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReviewLink extends StatelessWidget {
  const _ReviewLink({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l = context.l, c = context.c;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(CupertinoIcons.sun_max, size: 25, color: c.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.reviewTeaser,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.reviewTeaserBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(CupertinoIcons.chevron_right, size: 14, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}
