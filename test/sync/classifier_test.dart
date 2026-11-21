import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_cehennemi/domain/entry.dart';
import 'package:screenshot_cehennemi/sync/classifier.dart';

void main() {
  final classifier = RuleBasedClassifier();
  test('confident English and Turkish examples map to each collection', () {
    final examples = {
      EntryCategory.watchlist: 'Arrival\nIMDb 8.0\nDirector Denis Villeneuve',
      EntryCategory.recipes:
          'Mercimek Çorbası\nMalzemeler\nYemek kaşığı zeytinyağı',
      EntryCategory.reading: 'Kürk Mantolu Madonna\nKitap\nYayınevi Yapı Kredi',
      EntryCategory.gaming: 'Hollow Knight\nSteam\nSystem Requirements',
      EntryCategory.places: 'Cappadocia\nTripadvisor\nHotel',
      EntryCategory.wishlist: 'Wool jacket\nAdd to cart\nIn stock',
      EntryCategory.ideas: 'A weekend project\nBrainstorm\nProject idea',
    };
    for (final entry in examples.entries) {
      expect(
        classifier.classify(entry.value).category,
        entry.key,
        reason: entry.key.name,
      );
      expect(
        classifier.classify(entry.value).title,
        entry.value.split('\n').first,
      );
    }
  });
  test(
    'ambiguous, weak or titleless text uses Other without inventing titles',
    () {
      for (final text in [
        '',
        'Some words',
        'Recipe',
        'Ingredients\nRecipe',
        'A find\nRecipe Ingredients\nIMDb Director',
      ]) {
        final result = classifier.classify(text);
        expect(result.category, EntryCategory.other, reason: text);
        expect(result.title, isNull);
      }
    },
  );
  test('only an actually present, validated web link is extracted', () {
    expect(
      classifier
          .classify('Lemon Pasta\nRecipe Ingredients\nhttps://example.org/food')
          .url,
      'https://example.org/food',
    );
    expect(
      classifier
          .classify('Lemon Pasta\nRecipe Ingredients\njavascript:alert(1)')
          .url,
      '',
    );
  });
  test('sensitive detection covers Turkish/English authentication and financial signals', () {
    final detector = SensitiveScreenshotDetector();
    for (final text in [
      'Verification code: 123456',
      'Doğrulama kodu 123456',
      'Recovery codes',
      'Kurtarma kodu',
      'IBAN TR12345678901234567890',
      'Account balance 500',
      'Kullanılabilir bakiye 500',
      '1234 5678 1234 5678',
      'Your private key',
    ]) {
      expect(detector.isSensitive(text), isTrue, reason: text);
    }
    expect(detector.isSensitive('Lemon pasta recipe\nIngredients'), isFalse);
  });
}
