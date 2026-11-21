import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

/// Firebase/OAuth client identifiers are public. Never put service-account,
/// OAuth client secrets or Apple signing keys in these values.
class AuthConfig {
  const AuthConfig();
  String get apiKey => Platform.isIOS
      ? const String.fromEnvironment('FIREBASE_IOS_API_KEY')
      : const String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  String get appId => Platform.isIOS
      ? const String.fromEnvironment('FIREBASE_IOS_APP_ID')
      : const String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  String get projectId => const String.fromEnvironment('FIREBASE_PROJECT_ID');
  String get senderId =>
      const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  String get googleIosClientId =>
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  String get googleWebClientId =>
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  bool get configured =>
      (Platform.isIOS || Platform.isAndroid) &&
      [
        apiKey,
        appId,
        projectId,
        senderId,
        googleWebClientId,
      ].every((v) => v.isNotEmpty) &&
      (!Platform.isIOS ||
          googleIosClientId.endsWith('.apps.googleusercontent.com'));
  FirebaseOptions get options => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    iosBundleId: Platform.isIOS ? 'com.example.screenshotCehennemi' : null,
    iosClientId: Platform.isIOS ? googleIosClientId : null,
  );
}
