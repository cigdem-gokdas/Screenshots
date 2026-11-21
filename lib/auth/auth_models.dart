enum LoginProvider { google, apple }

enum AuthMessage {
  unavailable,
  cancelled,
  failed,
  network,
  conflict,
  revoked,
  deleted,
  signedOut,
  billingSync,
}

class LocalAccount {
  const LocalAccount({
    required this.uid,
    required this.providers,
    this.name,
    this.email,
  });
  final String uid;
  final Set<LoginProvider> providers;
  final String? name, email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final AuthMessage message;
}

abstract interface class AuthGateway {
  bool get configured;
  Stream<LocalAccount?> get changes;
  Future<LocalAccount?> initialize();
  Future<LocalAccount> signIn(LoginProvider provider);
  Future<LocalAccount> link(LoginProvider provider);
  Future<LocalAccount?> refresh();
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> dispose();
}
