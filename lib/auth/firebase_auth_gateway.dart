import 'dart:io';

import 'package:flutter/services.dart';

import 'package:crypto/crypto.dart';

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_config.dart';
import 'auth_models.dart';

/// SDK-managed platform credential persistence (Keychain on iOS); no tokens in Drift,
/// app preferences or logs. No Firebase product other than Auth is configured.
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this.config);
  final AuthConfig config;
  FirebaseAuth? _auth;
  bool _googleReady = false;
  @override
  bool get configured => config.configured;
  LocalAccount? _account(User? user) => user == null
      ? null
      : LocalAccount(
          uid: user.uid,
          name: user.displayName,
          email: user.email,
          providers: {
            for (final p in user.providerData)
              if (p.providerId == 'google.com')
                LoginProvider.google
              else if (p.providerId == 'apple.com')
                LoginProvider.apple,
          },
        );
  @override
  Stream<LocalAccount?> get changes => _auth!.userChanges().map(_account);
  @override
  Future<LocalAccount?> initialize() async {
    if (!configured) throw const AuthFailure(AuthMessage.unavailable);
    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp(options: config.options)
        : Firebase.app();
    await app.setAutomaticDataCollectionEnabled(false);
    _auth = FirebaseAuth.instanceFor(app: app);
    return _account(_auth!.currentUser);
  }

  Future<void> _googleInitialize({bool requireCallback = true}) async {
    if (Platform.isIOS && requireCallback) {
      final scheme = config.googleIosClientId.split('.').reversed.join('.');
      final ready = await const MethodChannel(
        'screenshot_cehennemi/local_vision',
      ).invokeMethod<bool>('googleCallbackReady', {'scheme': scheme});
      if (ready != true) throw const AuthFailure(AuthMessage.unavailable);
    }
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS ? config.googleIosClientId : null,
      serverClientId: config.googleWebClientId,
    );
    _googleReady = true;
  }

  Future<({AuthCredential credential, String? code})> _credential(
    LoginProvider provider,
  ) async {
    if (provider == LoginProvider.google) {
      await _googleInitialize();
      final google = await GoogleSignIn.instance.authenticate();
      final token = google.authentication.idToken;
      if (token == null) throw const AuthFailure(AuthMessage.failed);
      return (
        credential: GoogleAuthProvider.credential(idToken: token),
        code: null,
      );
    }
    if (!Platform.isIOS || !await SignInWithApple.isAvailable()) {
      throw const AuthFailure(AuthMessage.unavailable);
    }
    final nonce = generateNonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256.convert(utf8.encode(nonce)).toString(),
    );
    final token = apple.identityToken;
    if (token == null) throw const AuthFailure(AuthMessage.failed);
    return (
      credential: AppleAuthProvider.credentialWithIDToken(
        token,
        nonce,
        AppleFullPersonName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        ),
      ),
      code: apple.authorizationCode,
    );
  }

  AuthFailure _failure(Object error) {
    if (error is AuthFailure) return error;
    if (error is SignInWithAppleAuthorizationException &&
            error.code == AuthorizationErrorCode.canceled ||
        error is GoogleSignInException &&
            error.code == GoogleSignInExceptionCode.canceled) {
      return const AuthFailure(AuthMessage.cancelled);
    }
    if (error is FirebaseAuthException) {
      if ([
        'account-exists-with-different-credential',
        'credential-already-in-use',
        'email-already-in-use',
        'provider-already-linked',
      ].contains(error.code)) {
        return const AuthFailure(AuthMessage.conflict);
      }
      if (error.code == 'network-request-failed') {
        return const AuthFailure(AuthMessage.network);
      }
      if ([
        'user-disabled',
        'user-not-found',
        'invalid-user-token',
        'user-token-expired',
      ].contains(error.code)) {
        return const AuthFailure(AuthMessage.revoked);
      }
    }
    return const AuthFailure(AuthMessage.failed);
  }

  @override
  Future<LocalAccount> signIn(LoginProvider provider) async {
    try {
      final credential = await _credential(provider);
      return _account(
        (await _auth!.signInWithCredential(credential.credential)).user,
      )!;
    } catch (e) {
      throw _failure(e);
    }
  }

  LoginProvider _provider(User user) =>
      user.providerData.any((p) => p.providerId == 'apple.com') &&
          Platform.isIOS
      ? LoginProvider.apple
      : LoginProvider.google;
  Future<({AuthCredential credential, String? code})> _reauthenticate(
    User user,
  ) async {
    final credential = await _credential(_provider(user));
    await user.reauthenticateWithCredential(credential.credential);
    return credential;
  }

  @override
  Future<LocalAccount> link(LoginProvider provider) async {
    try {
      final user = _auth!.currentUser;
      if (user == null) throw const AuthFailure(AuthMessage.revoked);
      if (user.providerData.any(
        (p) => p.providerId == '${provider.name}.com',
      )) {
        return _account(user)!;
      }
      await _reauthenticate(user);
      final credential = await _credential(provider);
      return _account(
        (await user.linkWithCredential(credential.credential)).user,
      )!;
    } catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<LocalAccount?> refresh() async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    try {
      if (Platform.isIOS) {
        final apple = user.providerData
            .where((p) => p.providerId == 'apple.com')
            .firstOrNull;
        if (apple?.uid != null) {
          final state = await SignInWithApple.getCredentialState(apple!.uid!);
          if (state == CredentialState.revoked ||
              state == CredentialState.notFound) {
            await signOut();
            throw const AuthFailure(AuthMessage.revoked);
          }
        }
      }
      await user.reload();
      await _auth!.currentUser?.getIdToken(true);
      return _account(_auth!.currentUser);
    } catch (e) {
      final failure = _failure(e);
      if (failure.message == AuthMessage.revoked) await signOut();
      if (failure.message == AuthMessage.failed) {
        throw const AuthFailure(AuthMessage.network);
      }
      throw failure;
    }
  }

  @override
  Future<void> signOut() async {
    final hadGoogle =
        _auth?.currentUser?.providerData.any(
          (p) => p.providerId == 'google.com',
        ) ==
        true;
    await _auth?.signOut();
    if (hadGoogle && !_googleReady) {
      try {
        await _googleInitialize(requireCallback: false);
      } catch (_) {}
    }
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth?.currentUser;
      if (user == null) throw const AuthFailure(AuthMessage.revoked);
      final hadGoogle = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );
      final reauth = await _reauthenticate(user);
      // Apple requires fresh authorization for token revocation. Never retain codes.
      if (reauth.code != null) {
        await _auth!.revokeTokenWithAuthorizationCode(reauth.code!);
      }
      await user.delete();
      if (hadGoogle && !_googleReady) {
        try {
          await _googleInitialize(requireCallback: false);
        } catch (_) {}
      }
      if (_googleReady) {
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
      }
      await signOut();
    } catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> dispose() async {}
}
