import 'dart:io';

/// Only PUBLIC RevenueCat SDK keys and public legal URLs belong in dart-defines.
/// Store secrets / AI keys never belong in this configuration or the app bundle.
class ReleaseConfig {
  const ReleaseConfig({
    this.appleKey = const String.fromEnvironment('REVENUECAT_APPLE_PUBLIC_KEY'),
    this.googleKey = const String.fromEnvironment(
      'REVENUECAT_GOOGLE_PUBLIC_KEY',
    ),
    this.privacyUrl = const String.fromEnvironment('PRIVACY_POLICY_URL'),
    this.termsUrl = const String.fromEnvironment('TERMS_OF_USE_URL'),
    this.monthlyId = const String.fromEnvironment(
      'PRO_MONTHLY_PRODUCT_ID',
      defaultValue: 'screenshot_hell_pro_monthly',
    ),
    this.yearlyId = const String.fromEnvironment(
      'PRO_YEARLY_PRODUCT_ID',
      defaultValue: 'screenshot_hell_pro_yearly',
    ),
    this.offeringId = const String.fromEnvironment(
      'REVENUECAT_OFFERING_ID',
      defaultValue: 'default',
    ),
  });
  final String appleKey, googleKey, privacyUrl, termsUrl;
  final String monthlyId, yearlyId, offeringId;
  static const entitlement = 'pro';
  static const freeImportBatch = 10;
  static const proImportBatch = 50;
  static const requestTimeout = Duration(seconds: 20);
  static const offlineAccessWindow = Duration(hours: 72);
  String get publicKey => Platform.isIOS
      ? appleKey
      : Platform.isAndroid
      ? googleKey
      : '';
  bool get billingConfigured => Platform.isIOS
      ? appleKey.startsWith('appl_')
      : Platform.isAndroid && googleKey.startsWith('goog_');
  bool get legalReady =>
      publicHttps(privacyUrl) &&
      publicHttps(termsUrl) &&
      ![privacyUrl, termsUrl].any((value) {
        final host = Uri.parse(value).host;
        return ['example.com', 'example.org', 'example.net'].contains(host) ||
            host.endsWith('.invalid') ||
            host.endsWith('.test');
      });
  // Pro automation currently exists only on iOS. Do not sell an Android plan
  // before an Android Pro benefit is actually implemented and policy-cleared.
  bool get canSell =>
      Platform.isIOS &&
      billingConfigured &&
      legalReady &&
      monthlyId != yearlyId;
  static bool publicHttps(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        uri.host.endsWith('.local') ||
        uri.host.endsWith('.localhost') ||
        uri.host == 'localhost') {
      return false;
    }
    if (InternetAddress.tryParse(uri.host) != null) return false;
    return uri.host.contains('.') &&
        !uri.host.startsWith('.') &&
        !uri.host.endsWith('.') &&
        !RegExp(r'\s').hasMatch(value);
  }
}
