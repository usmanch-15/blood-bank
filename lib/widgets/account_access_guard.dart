import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/push_navigation_service.dart';

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
    if (!auth.isLoggedIn || (role != null && auth.currentUser?.role != role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account access')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.errorMessage ??
                    'Sign in with an active account to access this page.',
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
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}
