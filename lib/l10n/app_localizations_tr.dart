// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Unuttuğum Screenshotlar';

  @override
  String get home => 'Koleksiyonlar';

  @override
  String get library => 'Arşivim';

  @override
  String get review => 'Günlük bakış';

  @override
  String get settings => 'Ayarlar';

  @override
  String get homeEyebrow => 'ARTIK DAHA AZ UNUTULAN';

  @override
  String get homeTitle => 'Kaydettiklerin,\nhayata karışsın.';

  @override
  String get homeSubtitle =>
      'Güzel keşifler bir ekran görüntüsünden fazlasını hak eder.';

  @override
  String get yourCollections => 'Koleksiyonların';

  @override
  String get allEntries => 'Tüm kayıtlar';

  @override
  String get addEntry => 'Yeni kayıt';

  @override
  String get watchlist => 'İzleyeceklerim';

  @override
  String get recipes => 'Deneyeceklerim';

  @override
  String get reading => 'Okuyacaklarım';

  @override
  String get gaming => 'Oynayacaklarım';

  @override
  String get places => 'Gideceklerim';

  @override
  String get wishlist => 'Alacaklarım';

  @override
  String get ideas => 'Fikirlerim';

  @override
  String get other => 'Diğer';

  @override
  String get watchHint => 'Bir sonraki film gecene';

  @override
  String get recipesHint => 'Yeni bir lezzet keşfine';

  @override
  String get readingHint => 'Sıradaki güzel hikâyene';

  @override
  String get gamingHint => 'Yeni bir dünyaya';

  @override
  String get placesHint => 'Bir sonraki yolculuğuna';

  @override
  String get wishlistHint => 'Aklında kalan şeylere';

  @override
  String get ideasHint => 'Bir kıvılcım yeter';

  @override
  String get otherHint => 'Geri kalan güzelliklere';

  @override
  String get reviewTeaser => 'Bir gün değil, yakında';

  @override
  String get reviewTeaserBody => 'Aklında kalanlara küçük bir bakış.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt',
      zero: 'Henüz kayıt yok',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Keşiflerinde ara';

  @override
  String get allCategories => 'Tüm kategoriler';

  @override
  String get allStatuses => 'Tüm durumlar';

  @override
  String get filter => 'Filtrele';

  @override
  String get todo => 'Yapılacak';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get archived => 'Arşivlendi';

  @override
  String get noEntries => 'Yeni keşiflere yer aç';

  @override
  String get noEntriesBody =>
      'İzlemek, denemek, okumak ya da keşfetmek istediğin bir şey ekle.';

  @override
  String get noResults => 'Eşleşen kayıt yok';

  @override
  String get noResultsBody => 'Başka bir arama dene veya filtrelerini temizle.';

  @override
  String get clearFilters => 'Filtreleri temizle';

  @override
  String get newEntry => 'Güzel bir keşif';

  @override
  String get editEntry => 'Kaydı düzenle';

  @override
  String get editorSubtitle => 'O “bir gün” için küçük bir başlangıç.';

  @override
  String get titleLabel => 'Başlık';

  @override
  String get titleHint => 'Aklında ne kaldı?';

  @override
  String get categoryLabel => 'Koleksiyon';

  @override
  String get descriptionLabel => 'Notlar (isteğe bağlı)';

  @override
  String get descriptionHint => 'Hatırlamak istediğin küçük bir detay…';

  @override
  String get urlLabel => 'Bağlantı (isteğe bağlı)';

  @override
  String get urlHint => 'https://…';

  @override
  String get statusLabel => 'Durum';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get titleError => '1–120 karakter arasında bir başlık gir.';

  @override
  String get descriptionError => 'Notlar 5.000 karakteri geçmemeli.';

  @override
  String get urlError =>
      'Giriş bilgisi içermeyen, herkese açık bir https bağlantısı gir.';

  @override
  String get saveError =>
      'Kaydedilemedi. Değişikliklerin burada duruyor. Tekrar dene.';

  @override
  String get details => 'Keşfin';

  @override
  String get edit => 'Düzenle';

  @override
  String get delete => 'Kaydı sil';

  @override
  String get deleteTitle => 'Bu kaydı silelim mi?';

  @override
  String get deleteBody => 'Bu kayıt cihazdan kalıcı olarak silinecek.';

  @override
  String get deleteConfirm => 'Sil';

  @override
  String get actionError => 'İşlem tamamlanamadı. Lütfen tekrar dene.';

  @override
  String get openLink => 'Bağlantıyı aç';

  @override
  String get linkError => 'Bu bağlantı açılamadı.';

  @override
  String savedOn(String date) {
    return 'Kayıt tarihi: $date';
  }

  @override
  String updatedOn(String date) {
    return 'Güncelleme: $date';
  }

  @override
  String get notes => 'Aklında kalsın';

  @override
  String get entryGone => 'Bu kayıt artık mevcut değil.';

  @override
  String get reviewEyebrow => 'YENİDEN KEŞFETME ZAMANI';

  @override
  String get reviewTitle => 'Küçük bir adım,\nyeni bir deneyim.';

  @override
  String get reviewSubtitle => 'Koleksiyonlarına farklı bir açıdan bak.';

  @override
  String get savedToday => 'Bugün kaydedilen';

  @override
  String get uncompleted => 'Seni bekleyen';

  @override
  String get completedItems => 'Tamamlananlar';

  @override
  String get distribution => 'Merakının peşinde';

  @override
  String get revisit => 'Yeniden bakmaya değer';

  @override
  String get revisitHint =>
      'En az 7 gündür dokunmadığın, tamamlanmamış keşifler.';

  @override
  String get noRevisit => 'Şimdilik her şey güncel.';

  @override
  String get suggestionLabel => 'KÜÇÜK BİR ÖNERİ';

  @override
  String suggestion(String title, String category) {
    return '$category koleksiyonundaki “$title” ile başla. Bugün için güzel bir keşif yeter.';
  }

  @override
  String get emptySuggestion =>
      'Yeni keşfin burada başlıyor. Merak ettiğin bir şey kaydet.';

  @override
  String doneSuggestion(int count) {
    return '$count kaydı tamamladın. Yeni bir keşfe yer aç.';
  }

  @override
  String get archivedSuggestion =>
      'Keşiflerin arşivinde duruyor. Merak ettiğinde bir kaydı yeniden açabilirsin.';

  @override
  String get viewEntry => 'Göz at';

  @override
  String get reviewEmpty => 'Hikâyen bir keşifle başlar';

  @override
  String get reviewEmptyBody =>
      'Kayıt ekledikçe gerçek etkinliğin burada görünecek.';

  @override
  String get language => 'Dil';

  @override
  String get languageSubtitle => 'Kendini en rahat hissettiğin dil.';

  @override
  String get systemLanguage => 'Cihaz dili';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get privacyTitle => 'Sen ve keşiflerin';

  @override
  String get privacyBody =>
      'Screenshot analizi bu cihazda, Apple Vision ve yerel kurallarla yapılır. Görseller ve OCR metni sunucuya gönderilmez. İsteğe bağlı hesap girişi kimlik bilgilerini Firebase ve seçtiğin sağlayıcıyla; Pro aboneliği satın alma bilgilerini RevenueCat ve mağazayla paylaşır.';

  @override
  String get storageTitle => 'Bu cihazda';

  @override
  String get storageBody =>
      'Uygulamayı kaldırmak veya depolamayı temizlemek kayıtlarını silebilir. iOS’ta yerel veritabanı ve içe aktarılan kopyalar için yedekleme dışında tutma ayarı istenir. Önceden oluşturulan yedekler değiştirilmez.';

  @override
  String get loadError => 'Koleksiyonun yüklenemedi.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get close => 'Kapat';

  @override
  String get discardTitle => 'Değişikliklerden vazgeçilsin mi?';

  @override
  String get discardBody => 'Kaydedilmemiş değişikliklerin kaybolacak.';

  @override
  String get discard => 'Vazgeç';

  @override
  String get keepEditing => 'Düzenlemeye devam et';

  @override
  String get autoSync => 'Otomatik Ekran Görüntüsü Eşzamanlama';

  @override
  String get syncIntroTitle => 'Ekran görüntülerin,\nbiraz daha düzenli.';

  @override
  String get syncIntroBody =>
      'Otomatik eşzamanlamayı bir kez aç. Yeni ekran görüntülerin seçme, onaylama veya kategorize etme adımı olmadan kayda dönüşür. İstediğin kaydı sonradan düzenleyebilirsin.';

  @override
  String get syncAccessTitle => 'Fotoğraf erişimi senin kontrolünde';

  @override
  String get syncAccessBody =>
      'iOS tüm fotoğraf arşivine veya yalnızca seçili fotoğraflara erişim verebilir. İşletim sistemi erişimi Ekran Görüntüleri albümüyle sınırlamaz. Uygulama tür denetimi yaparak yalnızca ekran görüntülerini işler. Sınırlı erişimde bazıları görünmeyebilir. Erişimi daha sonra iOS Ayarlarından değiştirebilir veya kaldırabilirsin.';

  @override
  String get syncLocalTitle => 'Bu cihazda düzenlenir';

  @override
  String get syncLocalBody =>
      'Ekran görüntüleri ve okunan metin uygulamanın yerel depolamasında kalır. Olası şifreler, banka bilgileri ve kurtarma kodları kısa bir yerel kontrolden sonra atlanır. Algılama ve sınıflandırma hata yapabilir. Metin tanıma Apple Vision ve yerel sınıflandırma kuralları kullanır; bulut yapay zekâsı kullanmaz.';

  @override
  String get syncForegroundTitle => 'Geri döndüğünde kaldığı yerden';

  @override
  String get syncForegroundBody =>
      'Eşzamanlama uygulama etkinken çalışır, tekrar açtığında eksikleri tamamlar. iOS uygulamayı askıya alabilir veya kapatabilir; sürekli arka plan takibi yoktur. Yalnızca iCloud’da bulunan görüntüler cihazda kullanılabilir olana kadar bekler.';

  @override
  String get syncEnable => 'Otomatik eşzamanlamayı aç';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get newOnly => 'Önce arşivin, sonra yenileri';

  @override
  String get newOnlyBody =>
      'Erişim verdiğinde mevcut ekran görüntülerin bulunur. Sonrasında yeni screenshotlar uygulama açıkken eklenir. Aynı içerik tekrar kaydedilmez.';

  @override
  String get importExisting => 'Mevcut Ekran Görüntülerini İçe Aktar';

  @override
  String get importExistingTitle => 'Eski ekran görüntüleri de eklensin mi?';

  @override
  String get importExistingBody =>
      'Eşzamanlama açılmadan önce çekilen erişilebilir ekran görüntülerini otomatik düzenle. Hassas görüntüler yine atlanır. Fotoğraflar arşivindeki orijinaller değiştirilmez.';

  @override
  String get syncStatus => 'Eşzamanlama Durumu';

  @override
  String get lastSync => 'Son Başarılı Eşzamanlama';

  @override
  String get neverSynced => 'Henüz yok';

  @override
  String get photoPermission => 'Fotoğraf erişimi';

  @override
  String get accessNotDetermined => 'İstenmedi';

  @override
  String get accessAuthorized => 'Tam Erişim';

  @override
  String get accessLimited => 'Sınırlı Erişim';

  @override
  String get accessDenied => 'İzin Verilmedi';

  @override
  String get accessRestricted => 'Erişim cihaz denetimleriyle kısıtlı';

  @override
  String get syncOff => 'Otomatik eşzamanlama kapalı';

  @override
  String get syncChecking => 'Fotoğraf erişimi kontrol ediliyor…';

  @override
  String get syncScanning => 'Ekran görüntüleri bulunuyor…';

  @override
  String get syncProcessing => 'Bu cihazda düzenleniyor…';

  @override
  String get syncIdle => 'Güncel';

  @override
  String get syncWaiting =>
      'Bazı görüntüler bekliyor — buluttakiler cihazda kullanılabilir olunca yeniden denenir';

  @override
  String get syncPaused => 'Uygulama etkin değilken duraklatıldı';

  @override
  String get syncError =>
      'Eşzamanlama tamamlanamadı. Kayıtların burada duruyor.';

  @override
  String get syncIOSOnly =>
      'Otomatik kitaplık eşzamanlaması iOS’te kullanılabilir. Android’de seçerek içe aktarma ve elle düzenlemeyi kullanabilirsin.';

  @override
  String get openPhotoSettings => 'iOS Ayarlar’ı aç';

  @override
  String get deleteImported => 'İçe Aktarılan Ekran Görüntüsü Verilerini Sil';

  @override
  String get deleteImportedTitle =>
      'İçe aktarılan veriler uygulamadan silinsin mi?';

  @override
  String get deleteImportedBody =>
      'Eşzamanlamayı kapatır; içe aktarılan kayıtları, yerel görüntü kopyalarını, okunan metni ve içe aktarma geçmişini siler. Manuel kayıtlar ve Fotoğraflar’daki orijinaller korunur. Tekrar açmak yalnızca yeni görüntülerle başlar.';

  @override
  String screenshotFallback(String date) {
    return 'Ekran görüntüsü · $date';
  }

  @override
  String get importedScreenshot => 'İçe aktarılan ekran görüntüsü';

  @override
  String capturedOn(String date) {
    return 'Çekilme tarihi: $date';
  }

  @override
  String get imageUnavailable => 'Yerel ekran görüntüsü kopyası bulunamıyor.';

  @override
  String get syncHistoryPending =>
      'Erişim sağlandığında mevcut ekran görüntüleri de eklenecek.';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfUse => 'Kullanım Koşulları';

  @override
  String get readPublishedPolicy => 'Yayımlanan metni oku';

  @override
  String get legalDraftNotice =>
      'Bu özet taslaktır. Abonelikler sunulmadan önce geliştiricinin tam yasal metinleri onaylayıp yayımlaması gerekir.';

  @override
  String get privacyPolicyBody =>
      'Seçtiğin ekran görüntüleri, çıkarılan metinler ve koleksiyonların bu cihazda işlenir ve uygulamanın özel alanında saklanır. Ekran görüntüleri ve OCR metinleri bir sunucuya veya yapay zekâ sağlayıcısına gönderilmez. Otomatik eşzamanlama isteğe bağlıdır ve ayrıca Fotoğraflar erişimi ister; erişimi cihaz Ayarlarından değiştirebilirsin.\n\nİsteğe bağlı Pro abonelikleri Apple/Google ve RevenueCat kullanır. Bağlanmayı seçtikten sonra aboneliği doğrulamak için anonim satın alma kimliği ve satın alma geçmişi paylaşılır. SDK tanılama ve otomatik reklam ilişkilendirme kimliği toplama kapalıdır. RevenueCat, geliştiriciye satın alma raporları sunar. Reklam, takip veya uygulama analiz SDK’sı eklemiyoruz.\n\nTek tek kayıtları silebilir veya Ayarlardaki İçe Aktarılan Ekran Görüntüsü Verilerini Sil seçeneğiyle içe aktarılan kayıtları, kopyaları ve geçmişi kaldırabilirsin. Elle oluşturulan kayıtlar sen silene kadar kalır. Fotoğraflardaki asıllar silinmez. Geçici işleme kopyaları her denemeden sonra, işlem kesilirse sonraki açılışta temizlenir. Satın alma kayıtları mağaza ve RevenueCat tarafından ayrı tutulur; yerel ekran görüntülerini silmek aboneliği iptal etmez veya saklamak zorunda oldukları kayıtları silmez.\n\nUygulamayı kaldırmak yerel verileri silebilir. Uygulama, veritabanı ve içe aktarılan kopyalar için iOS dosya koruması ve yedekleme dışında tutma ister; önceki yedeklerde veya dosya sistemi kopyalarında veri kalabilir. Hassas içerik denetimi bazı içerikleri kaçırabilir; silme, adli düzeyde güvenli silme garantisi değildir. Kayıtlı dış bağlantılar yalnızca sen seçtiğinde açılır. Kullanıcı hesabı gerekmez.\n\nGoogle veya Apple ile giriş isteğe bağlıdır. Seçersen Firebase Authentication ve seçtiğin sağlayıcı giriş kimliğini (UID, varsa ad/e-posta veya Apple gizli e-postası, oturum ve bağlantı bilgileri) işler. Screenshot ve OCR metni gönderilmez. Oturum bilgilerini SDK yönetir; uygulama veritabanında saklanmaz. Abonelik bağlantısına onay verdiysen Firebase UID, RevenueCat kimliği olarak kullanılır. Hesabı Sil yeniden doğrulama ister; Firebase hesabını ve bu cihazdaki oturumu kaldırır, yerel koleksiyonları korur. Mağaza ve RevenueCat satın alma kayıtları ayrıdır; hesap silmek aboneliği iptal etmez. Screenshot bulut yedeği veya cihazlar arası koleksiyon eşitlemesi yoktur.\n\nGoogle Sign-In ve Firebase Auth, hizmetlerinin çalışması için tanılama, cihaz/kullanıcı kimliği ve kullanım bilgileri işleyebilir. SDK gizlilik bildirimleri daha geniş kategoriler de içerir. Uygulama telefon numarası veya konum izni istemez; bu sağlayıcı verileri screenshot içeriğinden ayrıdır. Ayrı bir reklam veya uygulama analiz servisi eklenmemiştir; sağlayıcıların operasyonel ölçümlerinin tümünün kapalı olduğu iddia edilmez.';

  @override
  String get termsBody =>
      'Seçerek içe aktarma, yerel düzenleme, görüntüleme, silme ve iOS üzerinde uygulama açıkken otomatik screenshot keşfi ücretsizdir. Pro, iOS üzerinde tek seferde seçilebilen fotoğraf sayısını 10’dan 50’ye çıkarır. Sürekli arka plan takibi veya sınırsız bulut yapay zekâ sunmaz. Apple Vision ve yerel kurallar cihazında çalışır. Android görselleri elle düzenlemek için saklar; OCR şu an iOS’a özeldir.\n\nAylık ve yıllık abonelikler, mağazadan dönem bitiminden en az 24 saat önce iptal edilmedikçe otomatik yenilenir. Gerçek fiyatı mağaza gösterir ve ödemeyi onaylatır. Uygulamayı veya hesabı silmek aboneliği iptal etmez. Aboneliğini mağaza ayarlarından yönetebilirsin.\n\nPro bittiğinde mevcut verilerin ve ücretsiz keşif kullanılabilir kalır. Doğrulanmış erişim en fazla 72 saat, bilinen bitiş tarihini aşmadan çevrimdışı sürebilir. İade, erişim iptali veya süre sonu doğrulandığında büyük toplu seçim hakkı sona erer.\n\nHesap açmak isteğe bağlıdır; giriş ve çıkış bu cihazdaki koleksiyonları değiştirmez. Hesap silme onayı yerel koleksiyonlarının korunacağını açıklar. Bulut yedeği sunulmaz. Sınıflandırma ve hassas içerik kontrolleri hata yapabilir. Bu taslak, yayıncı/iletişim bilgileri ve hukuki onay tamamlanmadan yayımlanmamalıdır.';

  @override
  String get proTitle => 'Unuttuğum Screenshotlar Pro';

  @override
  String get proBadge => 'Pro';

  @override
  String get proHeadline => 'Daha büyük bir yığını düzenle.';

  @override
  String get proBenefits =>
      'Tek seçimde 50 fotoğrafa kadar içe aktar. Analiz cihazında yapılır. Otomatik screenshot keşfi ve temel özellikler herkes için açık.';

  @override
  String get freeAlways =>
      'Seçerek içe aktarma (10 fotoğraf), otomatik keşif, görüntüleme, düzenleme, silme, arama ve günlük bakış ücretsiz kalır.';

  @override
  String get proActive => 'Pro etkin';

  @override
  String get freePlan => 'Ücretsiz plan';

  @override
  String get upgradePro => 'Pro’yu keşfet';

  @override
  String get billingDisclosure =>
      'Planları görmek veya satın almalarını geri yüklemek için RevenueCat ve mağazaya bağlanırsın. Aboneliğini doğrulamak için satın alma kimliği ve geçmişi paylaşılır; giriş yaptıysan Firebase UID ile ilişkilendirilir. Screenshot ve OCR metni paylaşılmaz. Hesap açmak gerekmez.';

  @override
  String get viewPlans => 'Bağlan ve planları gör';

  @override
  String monthlyPrice(String price) {
    return '$price / ay';
  }

  @override
  String yearlyPrice(String price) {
    return '$price / yıl';
  }

  @override
  String get subscriptionTerms =>
      'Otomatik yenilenen abonelik. Fiyatı ve ödemeyi mağaza onaylar. Yenilemeden en az 24 saat önce mağaza abonelik ayarlarından iptal edebilirsin. İptalden sonra kayıtlı verilerine erişimin sürer.';

  @override
  String get restorePurchases => 'Satın almaları geri yükle';

  @override
  String get manageSubscription => 'Aboneliği yönet';

  @override
  String get purchaseSuccess =>
      'Pro hazır. Düzenlemeye biraz ara verebilirsin.';

  @override
  String get restoreSuccess => 'Pro aboneliğin geri yüklendi.';

  @override
  String get restoreEmpty =>
      'Bu mağaza hesabında etkin Pro aboneliği bulunamadı.';

  @override
  String get purchaseCancelled =>
      'Satın alma iptal edildi. Ücretsiz özellikleri kullanmaya devam edebilirsin.';

  @override
  String get purchasePending =>
      'Mağaza onayı bekleniyor. Yeniden satın alma; onaydan sonra erişimin güncellenir.';

  @override
  String get purchaseFailed =>
      'Satın alma tamamlanamadı. Bağlantını ve mağaza hesabını kontrol edip yeniden dene.';

  @override
  String get billingUnavailable =>
      'Abonelik seçenekleri şu anda kullanılamıyor. Kayıtlı verilerin ve ücretsiz özellikler kullanılabilir.';

  @override
  String get autoSyncPro =>
      'Kitaplığı otomatik düzenleme bir Pro özelliğidir. Mevcut kayıtlarına her planda erişebilirsin.';

  @override
  String get importScreenshots => 'Ekran görüntüsü içe aktar';

  @override
  String get pickerHeadline => 'Birkaç iyi\nkeşif seç.';

  @override
  String get pickerExplanation =>
      'Sistem seçicisinden ekran görüntülerini veya fotoğrafları seç. Uygulama yalnızca seçtiklerini alır; tüm fotoğraf kitaplığına erişim gerekmez. iOS’te metin tanıma ve sınıflandırma bu cihazda yapılır. Yapay zekâ servisine yükleme yapılmaz. Her sonucu düzenleyebilir veya silebilirsin.';

  @override
  String get pickerLimits =>
      'Her seferinde en fazla 10 fotoğraf; Pro ile 50. Görseller cihazında küçültülür ve konum metaverisi tutulmaz.';

  @override
  String get chooseScreenshots => 'Görselleri seç';

  @override
  String get importWorking =>
      'Bu cihazda düzenleniyor… Güvenle iptal edebilirsin.';

  @override
  String importSummary(int imported, int duplicates, int skipped, int failed) {
    return '$imported kaydedildi · $duplicates zaten kayıtlı · $skipped gizlilik için atlandı · $failed işlenemedi.';
  }

  @override
  String get photoAccessSection => 'Fotoğraf Erişimi';

  @override
  String get photoPromptTitle => 'Screenshotlarını bulalım mı?';

  @override
  String get photoPromptBody =>
      'Tam erişimle ekran görüntülerini otomatik bulup düzenleriz; istersen sadece seçtiklerini ekleyebilirsin.';

  @override
  String get localAnalysis => 'Analiz cihazında yapılır.';

  @override
  String get findScreenshots => 'Ekran Görüntülerimi Bul';

  @override
  String get pickMyself => 'Kendim Seçerim';

  @override
  String get selectPhotos => 'Fotoğraf Seç';

  @override
  String get manageAccess => 'Erişimi Yönet';

  @override
  String get openSettings => 'Ayarları Aç';

  @override
  String get allowInSettings => 'Ayarlardan İzin Ver';

  @override
  String get photoLimitedBody =>
      'Yalnızca seçtiğin fotoğrafları görebiliyoruz.';

  @override
  String get photoDeniedBody =>
      'Galeri erişimi kapalı. İstersen ekran görüntülerini kendin seçebilirsin.';

  @override
  String get photoRestrictedBody =>
      'Fotoğraf erişimi bu cihazda kısıtlı. Bu izin uygulamadan değiştirilemiyor. Fotoğraf seçmeyi yine deneyebilirsin.';

  @override
  String get photoFullBody =>
      'Ekran görüntülerin uygulama açıkken otomatik bulunur. Diğer fotoğrafların analiz edilmez.';

  @override
  String get onboardingSaved => 'Kaydettin.';

  @override
  String get onboardingLost => 'Sonra kayboldu.';

  @override
  String get onboardingRecognition =>
      'Screenshotların aslında bir yapılacaklar listesi.';

  @override
  String get onboardingResolution =>
      'Kaydetmek yetmiyor.\nBulabilmek gerekiyor.';

  @override
  String get onboardingNext => 'Devam';

  @override
  String get organizeHell => 'Cehennemi Düzenle';

  @override
  String get onboardingGuest => 'Hesap açmadan başlayabilirsin.';

  @override
  String get semanticWatch => 'İzle';

  @override
  String get semanticRead => 'Oku';

  @override
  String get semanticGo => 'Git';

  @override
  String get semanticEat => 'Ye';

  @override
  String get semanticDo => 'Yap';

  @override
  String get accountTitle => 'Hesap';

  @override
  String get guestMode => 'Bu cihazda, sana ait.';

  @override
  String get accountConnected => 'Hesabın bağlı';

  @override
  String get accountExplanation =>
      'Giriş isteğe bağlı. Abonelik kimliğini aynı tutar; ekran görüntülerin buluta yüklenmez.';

  @override
  String get continueLabel => 'Devam et';

  @override
  String get continueGoogle => 'Google ile devam et';

  @override
  String get continueApple => 'Apple ile devam et';

  @override
  String get linkGoogle => 'Google hesabını bağla';

  @override
  String get linkApple => 'Apple hesabını bağla';

  @override
  String get linkAccountExplanation =>
      'Diğer hesabı bağlamak için önce mevcut hesabını doğrularız. Aynı e-posta adresi hesapları otomatik birleştirmez.';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountBody =>
      'Hesabın silinecek ve bu cihazdaki giriş bilgilerin temizlenecek. Yerel screenshotların ve koleksiyonların korunacak. Aboneliğin otomatik iptal olmaz; Apple abonelik ayarlarından yönetebilirsin. Hesabını yeniden doğrulaman istenecek.';

  @override
  String get authDisabled =>
      'Hesap girişi bu sürümde kapalı. Tüm özellikler hesapsız çalışır.';

  @override
  String get authUnavailable =>
      'Hesapla giriş henüz kullanıma hazır değil. Hesap açmadan tüm temel özellikleri kullanabilirsin.';

  @override
  String get authCancelled => 'Giriş iptal edildi. Koleksiyonların burada.';

  @override
  String get authFailed =>
      'Giriş tamamlanamadı. Biraz sonra tekrar deneyebilirsin.';

  @override
  String get authNetwork =>
      'Hesabına şu an ulaşılamıyor. İnternet bağlantını kontrol edebilirsin; yerel koleksiyonların kullanılabilir.';

  @override
  String get authConflict =>
      'Bu giriş başka bir hesaba bağlı. Önce daha önce kullandığın yöntemle giriş yapıp diğer hesabını buradan bağlayabilirsin. Hesaplarını otomatik birleştirmedik.';

  @override
  String get authRevoked =>
      'Hesap erişimin sona erdi. Koleksiyonlarını kullanabilir, istersen yeniden giriş yapabilirsin.';

  @override
  String get authDeleted =>
      'Hesabın silindi. Bu cihazdaki koleksiyonların korunuyor.';

  @override
  String get authSignedOut =>
      'Çıkış yapıldı. Koleksiyonların bu cihazda duruyor.';

  @override
  String get authBillingSync =>
      'Hesabın açık, ancak abonelik durumuna ulaşılamadı. Bağlantı geldiğinde yeniden kontrol edeceğiz.';

  @override
  String get photoAccessUnavailable =>
      'Fotoğraf erişim durumunu şu an okuyamıyoruz. İstersen fotoğraf seçebilir veya yeniden deneyebilirsin.';

  @override
  String get sortLabel => 'Sırala';

  @override
  String get sortNewest => 'Önce en yeni';

  @override
  String get sortOldest => 'Önce en eski';

  @override
  String get sortTitle => 'A–Z';

  @override
  String get starterImport => 'Ekran görüntülerini içe aktar';

  @override
  String get addManually => 'Elle ekle';

  @override
  String get undo => 'Geri al';

  @override
  String get entryDeleted => 'Kayıt silindi';

  @override
  String get markDone => 'Tamamla';

  @override
  String get markTodo => 'Yeniden aç';

  @override
  String get share => 'Paylaş';

  @override
  String get linkConfirmTitle => 'Bağlantı açılsın mı?';

  @override
  String get linkConfirmBody =>
      'Bu bağlantı bir ekran görüntüsünden okundu. Açmadan önce adresi kontrol et.';

  @override
  String get open => 'Aç';

  @override
  String get bestValue => 'En avantajlı';

  @override
  String get privacyNote =>
      'Veriler cihaz yedeklerine dahil edilmez; cihaz değiştirdiğinde kayıtlar taşınmaz.';

  @override
  String onboardingProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String versionLabel(String version) {
    return 'Sürüm $version';
  }

  @override
  String get moreActions => 'Diğer işlemler';
}
