import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/entry.dart';
import '../../domain/review.dart';
import '../../l10n/app_localizations.dart';
import '../design.dart';
import '../widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.entries,
    required this.onEntry,
    required this.onAdd,
    required this.now,
    this.onRefresh,
    this.barTitle,
    this.initialCategory,
    this.initialStatus,
    this.todayOnly = false,
  });
  final List<Entry> entries;
  final ValueChanged<Entry> onEntry;
  final VoidCallback onAdd;

  /// The shared app clock, so "saved today" matches the Daily Review.
  final DateTime now;
  final Future<void> Function()? onRefresh;

  /// When set the screen is a pushed route: the bar shows this title (with a
  /// back button) instead of the brand and the page heading is omitted.
  final String? barTitle;
  final EntryCategory? initialCategory;
  final EntryStatus? initialStatus;
  final bool todayOnly;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const searchDelay = Duration(milliseconds: 250);
  final search = TextEditingController();
  Timer? debounce;
  String query = '';
  EntryCategory? category;
  EntryStatus? status;
  EntrySort sort = EntrySort.newest;
  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
    status = widget.initialStatus;
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void onQuery(String value) {
    debounce?.cancel();
    debounce = Timer(searchDelay, () {
      if (mounted) setState(() => query = value);
    });
  }

  void clearSearch() {
    debounce?.cancel();
    search.clear();
    setState(() => query = '');
  }

  void clear() {
    debounce?.cancel();
    search.clear();
    setState(() {
      query = '';
      category = null;
      status = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final gutter = pageGutter(context);
    final source = widget.todayOnly
        ? savedOnDay(widget.entries, widget.now)
        : widget.entries;
    final entries = sortEntries(
      filterEntries(source, query: query, category: category, status: status),
      sort,
    );
    final filtered = query.isNotEmpty || category != null || status != null;
    final scaler = MediaQuery.textScalerOf(context);
    final fieldHeight = 28 + scaler.scale(16) * 1.5;
    final pillHeight = 44 + (scaler.scale(13) - 13) * 1.2;
    final headerExtent = 8 + fieldHeight + 10 + pillHeight + 10;
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AppSliverBar(
          title:
              widget.barTitle ??
              (widget.todayOnly ? l.savedToday : l.allEntries),
          actions: [
            IconButton(
              tooltip: l.addEntry,
              onPressed: widget.onAdd,
              icon: const Icon(CupertinoIcons.add, size: 23),
            ),
          ],
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeader(
            extent: headerExtent,
            color: context.c.background,
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: fieldHeight,
                    child: TextField(
                      controller: search,
                      onChanged: onQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l.searchHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 17,
                        ),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 19),
                        suffixIcon: ListenableBuilder(
                          listenable: search,
                          builder: (_, _) => search.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: l.clearFilters,
                                  onPressed: clearSearch,
                                  icon: const Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: pillHeight,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            clipBehavior: Clip.none,
                            children: [
                              PopupMenuButton<EntryCategory?>(
                                tooltip: l.categoryLabel,
                                initialValue: category,
                                onSelected: (v) => setState(() => category = v),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: null,
                                    onTap: () =>
                                        setState(() => category = null),
                                    child: Text(l.allCategories),
                                  ),
                                  ...EntryCategory.values.map(
                                    (c) => PopupMenuItem(
                                      value: c,
                                      child: Text(c.label(l)),
                                    ),
                                  ),
                                ],
                                child: _FilterPill(
                                  text: category?.label(l) ?? l.allCategories,
                                  active: category != null,
                                  height: pillHeight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<EntryStatus?>(
                                tooltip: l.statusLabel,
                                initialValue: status,
                                onSelected: (v) => setState(() => status = v),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: null,
                                    onTap: () => setState(() => status = null),
                                    child: Text(l.allStatuses),
                                  ),
                                  ...EntryStatus.values.map(
                                    (s) => PopupMenuItem(
                                      value: s,
                                      child: Text(s.label(l)),
                                    ),
                                  ),
                                ],
                                child: _FilterPill(
                                  text: status?.label(l) ?? l.allStatuses,
                                  active: status != null,
                                  height: pillHeight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<EntrySort>(
                        tooltip: l.sortLabel,
                        initialValue: sort,
                        onSelected: (v) => setState(() => sort = v),
                        itemBuilder: (_) => [
                          for (final s in EntrySort.values)
                            PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Expanded(child: Text(_sortLabel(s, l))),
                                  if (s == sort)
                                    Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 18,
                                      color: context.c.accent,
                                    ),
                                ],
                              ),
                            ),
                        ],
                        child: _FilterPill(
                          icon: CupertinoIcons.arrow_up_arrow_down,
                          active: sort != EntrySort.newest,
                          height: pillHeight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 6),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.itemCount(entries.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (filtered)
                  TextButton(onPressed: clear, child: Text(l.clearFilters)),
              ],
            ),
          ),
        ),
        if (entries.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                title: filtered ? l.noResults : l.noEntries,
                body: filtered ? l.noResultsBody : l.noEntriesBody,
                action: FilledButton(
                  onPressed: filtered ? clear : widget.onAdd,
                  child: Text(filtered ? l.clearFilters : l.addEntry),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) => EntryTile(
                entry: entries[i],
                onTap: () => widget.onEntry(entries[i]),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: pageBottomPadding(context))),
      ],
    );
    return refreshable(context, widget.onRefresh, scroll);
  }
}

String _sortLabel(EntrySort sort, AppLocalizations l) => switch (sort) {
  EntrySort.newest => l.sortNewest,
  EntrySort.oldest => l.sortOldest,
  EntrySort.title => l.sortTitle,
};

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  _PinnedHeader({
    required this.extent,
    required this.color,
    required this.child,
  });
  final double extent;
  final Color color;
  final Widget child;
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: color, child: child);
  @override
  bool shouldRebuild(_PinnedHeader old) => true;
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    this.text,
    required this.active,
    required this.height,
    this.icon = CupertinoIcons.chevron_down,
  });

  /// Without text the pill is an icon-only round button.
  final String? text;
  final bool active;
  final double height;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = active ? c.accent : c.ink;
    return Container(
      height: height,
      width: text == null ? height : null,
      padding: EdgeInsets.symmetric(horizontal: text == null ? 0 : 16),
      decoration: BoxDecoration(
        color: active ? c.accentTint : c.card,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: text == null
          ? Icon(icon, size: 17, color: fg)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 13, color: fg),
              ],
            ),
    );
  }
}
