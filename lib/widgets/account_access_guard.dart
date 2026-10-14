import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/push_navigation_service.dart';
import '../l10n/app_localizations.dart';

/// Backend rules remain authoritative; this also removes restricted UI.
class AccountAccessGuard extends StatelessWidget {
  final Widget child;
  final String? role;
  const AccountAccessGuard({super.key, required this.child, this.role});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.sessionReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hasRole =
        role == null ||
        (role == 'donor' && auth.isDonor) ||
        (role == 'receiver' && auth.isReceiver) ||
        (role == 'admin' && auth.isAdmin);
    if (!auth.isLoggedIn || !hasRole) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).accountAccess)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.errorMessage ??
                    AppLocalizations.of(context).activeAccountRequired,
              ),
              TextButton(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                      '/login',
                      (_) => false,
                    );
                  }
                },
                child: Text(AppLocalizations.of(context).backToLogin),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}
