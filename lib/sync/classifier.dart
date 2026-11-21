import '../domain/entry.dart';
import 'sync_models.dart';

/// Conservative, inspectable bilingual rules. Ambiguity always goes to Other.
class RuleBasedClassifier implements ScreenshotClassifier {
  static const rules = <EntryCategory, List<String>>{
    EntryCategory.watchlist: [
      r'\bimdb\b',
      r'\bletterboxd\b',
      r'\bnetflix\b',
      r'\bdirector\b',
      r'\byonetmen\b',
      r'\bfilm suresi\b',
      r'\bwatchlist\b',
    ],
    EntryCategory.recipes: [
      r'\bingredients\b',
      r'\bmalzemeler\b',
      r'\btarifi\b',
      r'\brecipe\b',
      r'\btablespoons?\b',
      r'\byemek kasigi\b',
      r'\bpreheat\b',
      r'\bfirinda\b',
    ],
    EntryCategory.reading: [
      r'\bisbn\b',
      r'\bgoodreads\b',
      r'\bauthor\b',
      r'\byayinevi\b',
      r'\bkitap\b',
      r'\bpaperback\b',
      r'\breading list\b',
    ],
    EntryCategory.gaming: [
      r'\bsteam\b',
      r'\bplaystation\b',
      r'\bxbox\b',
      r'\bnintendo\b',
      r'\bgameplay\b',
      r'\bsystem requirements\b',
      r'\bsistem gereksinimleri\b',
      r'\bvideo game\b',
    ],
    EntryCategory.places: [
      r'\btripadvisor\b',
      r'\bgoogle maps\b',
      r'\bcheck.in\b',
      r'\bgezilecek\b',
      r'\bkonaklama\b',
      r'\bhotel\b',
      r'\brestoran\b',
      r'\bvisit\b',
    ],
    EntryCategory.wishlist: [
      r'\badd to cart\b',
      r'\bsepete ekle\b',
      r'\btrendyol\b',
      r'\bhepsiburada\b',
      r'\bbuy now\b',
      r'\bsatin al\b',
      r'\bin stock\b',
      r'\bprice\b',
    ],
    EntryCategory.ideas: [
      r'\bbrainstorm\b',
      r'\bproject idea\b',
      r'\bproje fikri\b',
      r'\bfikirler\b',
      r'\bdesign concept\b',
      r'\btasarim fikri\b',
      r'\bidea:\b',
    ],
  };
  static String normalize(String text) =>
      searchKey(text)
          .replaceAll('ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c')
          .replaceAll('â', 'a');
  @override
  Classification classify(String text) {
    final normalized = normalize(text);
    final scores = {
      for (final entry in rules.entries)
        entry.key: entry.value
            .where((pattern) => RegExp(pattern).hasMatch(normalized))
            .length,
    };
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Two distinct cues and an unambiguous lead; title must also be reliable.
    if (ranked.first.value < 2 || ranked.first.value <= ranked[1].value) {
      return const Classification(category: EntryCategory.other);
    }
    final title = _title(text);
    if (title == null) {
      return const Classification(category: EntryCategory.other);
    }
    final links = RegExp(r'https?://[^\s<>]+')
        .allMatches(text)
        .map((m) => m.group(0)!.replaceFirst(RegExp(r'[.,;)]$'), ''))
        .where(EntryDraft.validUrl);
    return Classification(
      category: ranked.first.key,
      title: title,
      url: links.firstOrNull ?? '',
    );
  }

  String? _title(String text) {
    const chrome = [
      'ingredients',
      'malzemeler',
      'recipe',
      'tarif',
      'imdb',
      'netflix',
      'steam',
      'goodreads',
      'add to cart',
      'sepete ekle',
      'home',
      'back',
      'share',
      'paylas',
      'geri',
      'login',
      'sign in',
      'giris',
      'menu',
      'search',
      'ara',
      'for you',
      'sponsored',
      'reklam',
    ];
    for (final raw in text.split('\n')) {
      final line = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      final normalized = normalize(line);
      if (line.length < 4 ||
          line.length > 120 ||
          !RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(line)) {
        continue;
      }
      if (line.contains('://') ||
          RegExp(r'^[@#\d]|\b\d{1,2}:\d{2}\b').hasMatch(line)) {
        continue;
      }
      if (chrome.contains(normalized) ||
          RegExp(
            r'^(ingredients|malzemeler|isbn|director|yonetmen|price|fiyat)\b',
          ).hasMatch(normalized)) {
        continue;
      }
      return line;
    }
    return null;
  }
}

/// Minimize retention: this runs immediately after OCR, before hashing,
/// classification, copying or persisting any screenshot content.
class SensitiveScreenshotDetector {
  bool isSensitive(String text) {
    final normalized = RuleBasedClassifier.normalize(text);
    final signals = [
      r'\b(code|kod(?:u)?)[: \n]+\d{4,8}\b',
      r'\b(otp|one.time password|one.time code|verification code|security code|authentication code|recovery codes?|backup codes?|seed phrase|private key|secret key|password reset)\b',
      r'\b(dogrulama kodu|tek kullanimlik|guvenlik kodu|kurtarma kod\w*|yedek kod\w*|sifre sifirla|giris kodu|kurtarma anahtari|hesap bakiyesi|kullanilabilir bakiye|hesap numarasi|kredi karti|kart numarasi)\b',
      r'\b(iban|account balance|available balance|account number|credit card|card number|bank statement|routing number|swift code|cvv|cvc)\b',
      r'\b(bankasi|bankacilik|banking|garanti bbva|isbank|akbank|yapi kredi|ziraat|vakifbank|halkbank|chase bank|revolut|wise account)\b',
      r'\b\d{4}[ -]\d{4}[ -]\d{4}[ -]\d{4}\b',
      r'\b[a-z]{2}\d{2}[ ]?(?:[a-z0-9][ ]?){11,30}\b',
    ];
    return signals.any((pattern) => RegExp(pattern).hasMatch(normalized));
  }
}
