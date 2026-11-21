import 'entry.dart';

/// Entries created on the local calendar day of [now]. Shared by the daily
/// review and the library "saved today" filter so both use one clock.
List<Entry> savedOnDay(List<Entry> entries, DateTime now) {
  final localNow = now.toLocal();
  final start = DateTime(localNow.year, localNow.month, localNow.day);
  final end = DateTime(localNow.year, localNow.month, localNow.day + 1);
  return entries
      .where(
        (e) =>
            !e.createdAt.toLocal().isBefore(start) &&
            e.createdAt.toLocal().isBefore(end),
      )
      .toList();
}

/// Pure local-calendar calculation. The clock is supplied for deterministic tests.
class DailyReview {
  DailyReview(List<Entry> entries, DateTime now) {
    final localNow = now.toLocal();
    savedToday = savedOnDay(entries, now).length;
    todo = entries.where((e) => e.status == EntryStatus.todo).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    completed = entries.where((e) => e.status == EntryStatus.completed).length;
    archived = entries.where((e) => e.status == EntryStatus.archived).length;
    distribution = {
      for (final c in EntryCategory.values)
        c: entries.where((e) => e.category == c).length,
    };
    final cutoff = DateTime(localNow.year, localNow.month, localNow.day - 7);
    revisit = todo.where((e) => !e.updatedAt.toLocal().isAfter(cutoff)).toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    suggestion = revisit.isNotEmpty
        ? revisit.first
        : (todo.isEmpty ? null : todo.first);
    total = entries.length;
  }
  late final int savedToday, completed, archived, total;
  late final List<Entry> todo, revisit;
  late final Map<EntryCategory, int> distribution;
  late final Entry? suggestion;
}
