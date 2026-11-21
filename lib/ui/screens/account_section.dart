import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_models.dart';
import '../../l10n/app_localizations.dart';
import '../design.dart';

String authMessage(AuthMessage message, AppLocalizations l) =>
    switch (message) {
      AuthMessage.unavailable => l.authUnavailable,
      AuthMessage.cancelled => l.authCancelled,
      AuthMessage.failed => l.authFailed,
      AuthMessage.network => l.authNetwork,
      AuthMessage.conflict => l.authConflict,
      AuthMessage.revoked => l.authRevoked,
      AuthMessage.deleted => l.authDeleted,
      AuthMessage.signedOut => l.authSignedOut,
      AuthMessage.billingSync => l.authBillingSync,
    };

class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.auth, this.showApple});
  final AuthController auth;
  final bool? showApple;
  Future<void> delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.l.deleteAccount),
        content: Text(c.l.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.l.deleteAccount, style: TextStyle(color: c.c.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.deleteAccount();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) {
      final l = context.l;
      final account = auth.account;
      final enabled = auth.configured && !auth.busy;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.accountTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            account == null
                ? l.guestMode
                : account.name ?? account.email ?? l.accountConnected,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (!auth.configured)
            Text(
              l.authDisabled,
              style: TextStyle(color: context.c.muted, fontSize: 13),
            )
          else ...[
            Text(
              l.accountExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (account?.providers.contains(LoginProvider.google) != true)
              FilledButton.tonalIcon(
                key: const Key('sign-in-google'),
                onPressed: enabled
                    ? () => auth.login(LoginProvider.google)
                    : null,
                icon: Image.asset(
                  'assets/branding/google-g.png',
                  width: 20,
                  height: 20,
                  excludeFromSemantics: true,
                ),
                label: Text(account == null ? l.continueGoogle : l.linkGoogle),
              ),
            const SizedBox(height: 12),
            if ((showApple ?? Platform.isIOS) &&
                account?.providers.contains(LoginProvider.apple) != true)
              SizedBox(
                height: 50,
                child: Opacity(
                  opacity: enabled ? 1 : .45,
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: Semantics(
                      key: const Key('apple-account-action'),
                      container: true,
                      button: true,
                      enabled: enabled,
                      excludeSemantics: true,
                      label: account == null ? l.continueApple : l.linkApple,
                      onTap: enabled
                          ? () => auth.login(LoginProvider.apple)
                          : null,
                      child: MediaQuery.withNoTextScaling(
                        child: SignInWithAppleButton(
                          key: const Key('sign-in-apple'),
                          onPressed: () => auth.login(LoginProvider.apple),
                          text: account == null ? l.continueApple : l.linkApple,
                          style: Theme.of(context).brightness == Brightness.dark
                              ? SignInWithAppleButtonStyle.white
                              : SignInWithAppleButtonStyle.black,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          if (account != null) ...[
            const SizedBox(height: 12),
            Text(
              l.linkAccountExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: auth.busy ? null : auth.logout,
              child: Text(l.signOut),
            ),
            TextButton(
              onPressed: auth.busy ? null : () => delete(context),
              child: Text(
                l.deleteAccount,
                style: TextStyle(color: context.c.danger),
              ),
            ),
          ],
          if (auth.busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (auth.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(authMessage(auth.message!, l)),
              ),
            ),
        ],
      );
    },
  );
}
