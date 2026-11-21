import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entry.dart';
import '../../domain/review.dart';
import '../design.dart';
import '../widgets.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.entries,
    required this.now,
    required this.onEntry,
    required this.onFilter,
    required this.onAdd,
    this.onRefresh,
  });
  final List<Entry> entries;
  final DateTime now;
  final ValueChanged<Entry> onEntry;
  final void Function(EntryCategory?, EntryStatus?, bool) onFilter;
  final VoidCallback onAdd;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final review = DailyReview(entries, now);
    final suggestion = review.suggestion;
    final stackStats = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    final stats = [
      _Stat(
        value: review.savedToday,
        label: l.savedToday,
        onTap: () => onFilter(null, null, true),
      ),
      _Stat(
        value: review.todo.length,
        label: l.uncompleted,
        onTap: () => onFilter(null, EntryStatus.todo, false),
      ),
      _Stat(
        value: review.completed,
        label: l.completed,
        onTap: () => onFilter(null, EntryStatus.completed, false),
      ),
    ];
    return PageBody(
      onRefresh: onRefresh,
      topBar: AppSliverBar(
        collapsedTitle: l.review,
        actions: [
          IconButton(
            tooltip: l.addEntry,
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add, size: 23),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 4),
        Eyebrow(DateFormat.MMMMEEEEd(l.localeName).format(now).toUpperCase()),
        const SizedBox(height: 16),
        Text(l.reviewTitle, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(l.reviewSubtitle, style: TextStyle(color: c.muted, fontSize: 13)),
        const SizedBox(height: 28),
        if (stackStats)
          for (final stat in stats)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: stat)
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: stats[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: c.accentTint,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: c.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Eyebrow(l.suggestionLabel)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                suggestion != null
                    ? l.suggestion(
                        suggestion.title,
                        suggestion.category.label(l),
                      )
                    : review.completed > 0
                    ? l.doneSuggestion(review.completed)
                    : review.archived > 0
                    ? l.archivedSuggestion
                    : l.emptySuggestion,
                style: const TextStyle(fontSize: 15, height: 1.75),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: suggestion != null
                    ? () => onEntry(suggestion)
                    : review.archived > 0
                    ? () => onFilter(null, EntryStatus.archived, false)
                    : onAdd,
                label: Text(
                  suggestion != null
                      ? l.viewEntry
                      : review.archived > 0
                      ? l.archived
                      : l.addEntry,
                ),
                icon: const Icon(CupertinoIcons.chevron_right, size: 14),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(l.distribution, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          EmptyState(
            title: l.reviewEmpty,
            body: l.reviewEmptyBody,
            icon: CupertinoIcons.chart_bar,
          )
        else
          ...EntryCategory.values.map((cat) {
            final count = review.distribution[cat]!;
            final tone = cat.tone(context);
            return Semantics(
              button: true,
              label: '${cat.label(l)}, ${l.itemCount(count)}',
              excludeSemantics: true,
              onTap: () => onFilter(cat, null, false),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onFilter(cat, null, false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 20, color: tone),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.label(l),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: count / entries.length,
                                minHeight: 4,
                                color: tone,
                                backgroundColor: tone.withValues(alpha: .12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: c.muted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 26),
        Text(l.revisit, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l.revisitHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        if (review.revisit.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l.noRevisit, style: TextStyle(color: c.muted)),
          )
        else
          ...review.revisit
              .take(5)
              .map(
                (e) =>
                    EntryTile(entry: e, hero: false, onTap: () => onEntry(e)),
              ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.onTap});
  final int value;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, height: 1.3, color: c.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
