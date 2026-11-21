import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/application/app_controller.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/domain/review.dart';

Entry entry(
  int id, {
  EntryStatus status = EntryStatus.todo,
  EntryCategory category = EntryCategory.reading,
  DateTime? created,
  DateTime? updated,
  String title = 'İstanbul',
}) => Entry(
  id: id,
  title: title,
  category: category,
  description: 'book notes',
  url: '',
  status: status,
  createdAt: created ?? DateTime(2026, 10, 15, 12),
  updatedAt: updated ?? created ?? DateTime(2026, 10, 15, 12),
);
void main() {
  test('locale resolves language variants and falls back to Turkish', () {
    expect(resolveLocale([const Locale('en', 'GB')]), const Locale('en'));
    expect(resolveLocale([const Locale('de')]), const Locale('tr'));
    expect(resolveLocale(null), const Locale('tr'));
    expect(
      resolveLocale([const Locale('fr'), const Locale('tr')]),
      const Locale('tr'),
    );
  });
  test('URL validation rejects unsafe schemes, credentials, malformed URLs and whitespace', () {
    for (final value in [
      '',
      'https://example.org/a?q=1',
      'https://örnek.com',
    ]) {
      expect(EntryDraft.validUrl(value), isTrue, reason: value);
    }
    for (final value in [
      'javascript:alert(1)',
      'http://example.com',
      'https://localhost',
      'https://127.0.0.1',
      'https://[::1]',
      'file:///etc/passwd',
      'https://user:pass@example.com',
      'https://',
      'example.com',
      'https://bad host.com',
      'https://.example.com',
    ]) {
      expect(EntryDraft.validUrl(value), isFalse, reason: value);
    }
  });
  test('search combines notes, Turkish casing, category and status', () {
    final entries = [
      entry(1),
      entry(2, status: EntryStatus.completed, category: EntryCategory.places),
    ];
    expect(
      filterEntries(
        entries,
        query: 'istanbul',
        status: EntryStatus.todo,
      ).map((e) => e.id),
      [1],
    );
    expect(
      filterEntries(
        entries,
        query: 'NOTES',
        category: EntryCategory.places,
      ).map((e) => e.id),
      [2],
    );
    expect(filterEntries(entries, query: 'missing'), isEmpty);
  });
  test(
    'daily review respects local day boundaries and excludes future saves',
    () {
      final review = DailyReview([
        entry(1, created: DateTime(2026, 10, 14, 23, 59)),
        entry(2, created: DateTime(2026, 10, 15)),
        entry(3, created: DateTime(2026, 10, 16)),
        entry(4, status: EntryStatus.completed),
        entry(5, status: EntryStatus.archived),
      ], DateTime(2026, 10, 15, 16));
      expect(review.savedToday, 3);
      expect(review.todo.length, 3);
      expect(review.completed, 1);
      expect(review.archived, 1);
      expect(review.distribution[EntryCategory.reading], 5);
    },
  );
  test('revisit excludes archived, completed and recently touched entries', () {
    final old = DateTime(2026, 9, 1);
    final review = DailyReview([
      entry(1, created: old),
      entry(2, created: old, status: EntryStatus.archived),
      entry(3, created: old, status: EntryStatus.completed),
      entry(4, created: old, updated: DateTime(2026, 10, 14)),
    ], DateTime(2026, 10, 15));
    expect(review.revisit.map((e) => e.id), [1]);
    expect(review.suggestion?.id, 1);
  });
  test('empty and completed-only review produce no invented suggestion', () {
    expect(DailyReview([], DateTime.now()).suggestion, isNull);
    expect(
      DailyReview([
        entry(1, status: EntryStatus.completed),
      ], DateTime.now()).suggestion,
      isNull,
    );
  });
}
