import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_models.dart';

/// Identity never owns, filters, resets or migrates the installation's library.
/// The only identity bridge is a verified provider UID to the billing SDK.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.gateway,
    required this.readEnabled,
    required this.writeEnabled,
    required this.identifyBilling,
  });
  final AuthGateway gateway;
  final Future<bool> Function() readEnabled;
  final Future<void> Function(bool) writeEnabled;
  final Future<void> Function(String?) identifyBilling;
  LocalAccount? account;
  AuthMessage? message;
  bool busy = false, initialized = false, _disposed = false;
  StreamSubscription<LocalAccount?>? _subscription;
  Future<void> _identityQueue = Future.value();
  Future<void>? _initializing;
  bool _identityBound = false;
  String? _billingUid;
  bool get configured => gateway.configured;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _accept(LocalAccount? value) async {
    if (_disposed) return;
    account = value;
    _notify();
    if (_identityBound && _billingUid == value?.uid) return;
    _billingUid = value?.uid;
    _identityBound = true;
    // Preserve ordering across rapid auth changes; never send email as an ID.
    _identityQueue = _identityQueue.catchError((Object _) {}).then((_) async {
      try {
        await identifyBilling(value?.uid).timeout(const Duration(seconds: 20));
      } catch (_) {
        _identityBound = false;
        message = AuthMessage.billingSync;
        _notify();
      }
    });
    await _identityQueue;
  }

  Future<void> _initialize({bool restoreSession = true}) =>
      _initializing ??= _initializeSession(restoreSession)
          .whenComplete(() => _initializing = null);

  Future<void> _initializeSession(bool restoreSession) async {
    if (initialized) return;
    var current = await gateway.initialize();
    if (!restoreSession) {
      await gateway.signOut();
      current = null;
    }
    initialized = true;
    _subscription = gateway.changes.listen(
      (value) {
        unawaited(_accept(value));
      },
      onError: (Object _) {
        message = AuthMessage.failed;
        _notify();
      },
    );
    await _accept(current);
  }

  /// Signs out a stale Keychain session (fresh install only; see
  /// [reconcileInstallMarker]). Initializes the SDK solely for this purpose.
  Future<void> discardStaleSession() async {
    if (!configured) return;
    await gateway.initialize();
    await gateway.signOut();
  }

  Future<void> initialize() async {
    try {
      if (configured && await readEnabled()) {
        await _initialize();
        await refresh();
      }
    } catch (_) {
      message = AuthMessage.unavailable;
      _notify();
    }
  }

  Future<void> login(LoginProvider provider) => _perform(() async {
    if (!configured) throw const AuthFailure(AuthMessage.unavailable);
    final restoreSession = await readEnabled();
    await writeEnabled(true);
    await _initialize(restoreSession: restoreSession);
    final value = account == null
        ? await gateway.signIn(provider)
        : await gateway.link(provider);
    await _accept(value);
  });
  Future<void> refresh() async {
    if (!initialized || busy) return;
    try {
      await _accept(await gateway.refresh());
    } on AuthFailure catch (e) {
      message = e.message;
      if (e.message == AuthMessage.revoked) {
        await _accept(null);
      } else {
        _notify();
      }
    } catch (_) {
      message = AuthMessage.network;
      _notify();
    }
  }

  Future<void> logout() => _perform(() async {
    await gateway.signOut();
    await writeEnabled(false);
    await _accept(null);
    message = AuthMessage.signedOut;
  });
  Future<void> deleteAccount() => _perform(() async {
    await gateway.deleteAccount();
    await writeEnabled(false);
    await _accept(null);
    message = AuthMessage.deleted;
  });
  Future<void> _perform(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    _notify();
    try {
      await action();
    } on AuthFailure catch (e) {
      message = e.message;
    } catch (_) {
      message = AuthMessage.failed;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    unawaited(gateway.dispose());
    super.dispose();
  }
}

const installMarkerKey = 'install_marker.v1';

/// A Firebase session can outlive an app deletion in the iOS Keychain. On a
/// fresh install (database file did not exist before this launch and no marker)
/// sign out once; for upgrades just record the marker. Never throws.
Future<bool> reconcileInstallMarker({
  required bool databaseExisted,
  required Future<bool> Function() readMarker,
  required Future<void> Function() writeMarker,
  required Future<void> Function() signOutStale,
}) async {
  try {
    if (await readMarker()) return false;
    var signedOut = false;
    if (!databaseExisted) {
      try {
        await signOutStale();
        signedOut = true;
      } catch (_) {}
    }
    await writeMarker();
    return signedOut;
  } catch (_) {
    return false;
  }
}
