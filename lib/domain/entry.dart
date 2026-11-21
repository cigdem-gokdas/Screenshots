import '../config/release_config.dart';

enum EntryCategory {
  watchlist,
  recipes,
  reading,
  gaming,
  places,
  wishlist,
  ideas,
  other,
}

enum EntryStatus { todo, completed, archived }

class Entry {
  const Entry({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.url,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourceAssetKey,
    this.imagePath,
    this.capturedAt,
  });
  final String? sourceAssetKey, imagePath;
  final DateTime? capturedAt;
  final int id;
  final String title;
  final EntryCategory category;
  final String description;
  final String url;
  final EntryStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class EntryDraft {
  const EntryDraft({
    required this.title,
    required this.category,
    this.description = '',
    this.url = '',
    this.status = EntryStatus.todo,
  });
  final String title;
  final EntryCategory category;
  final String description;
  final String url;
  final EntryStatus status;

  bool get isValid =>
      validTitle(title) && description.trim().length <= 5000 && validUrl(url);
  static bool validTitle(String value) =>
      value.trim().isNotEmpty && value.trim().length <= 120;
  static bool validUrl(String value) {
    if (value.trim().isEmpty) return true;
    if (value.length > 2048 || RegExp(r'\s').hasMatch(value.trim())) {
      return false;
    }
    return ReleaseConfig.publicHttps(value.trim());
  }
}

String searchKey(String text) => text
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .replaceAll('ı', 'i')
    .toLowerCase();

List<Entry> filterEntries(
  List<Entry> entries, {
  String query = '',
  EntryCategory? category,
  EntryStatus? status,
}) {
  final term = searchKey(query.trim());
  return entries
      .where(
        (entry) =>
            (category == null || entry.category == category) &&
            (status == null || entry.status == status) &&
            (term.isEmpty ||
                searchKey('${entry.title} ${entry.description} ${entry.url}')
                    .contains(term)),
      )
      .toList();
}

enum EntrySort { newest, oldest, title }

const _alphabet = 'abcçdefgğhıijklmnoöpqrsştuüvwxyz';

List<int> _collationKey(String text) => [
  for (final unit in searchKeyForSort(text).runes)
    _alphabet.contains(String.fromCharCode(unit))
        ? _alphabet.indexOf(String.fromCharCode(unit)) + 1
        : 1000 + unit,
];

/// Lower-cases while keeping the Turkish dotless ı distinct.
String searchKeyForSort(String text) =>
    text.replaceAll('İ', 'i').replaceAll('I', 'i').toLowerCase();

int _compareKeys(List<int> a, List<int> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return a.length.compareTo(b.length);
}

List<Entry> sortEntries(List<Entry> entries, EntrySort sort) {
  final list = [...entries];
  switch (sort) {
    case EntrySort.newest:
      list.sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    case EntrySort.oldest:
      list.sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    case EntrySort.title:
      list.sort((a, b) {
        final byTitle = _compareKeys(
          _collationKey(a.title),
          _collationKey(b.title),
        );
        return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
      });
  }
  return list;
}
