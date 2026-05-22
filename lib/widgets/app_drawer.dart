import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../app/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 8),
                Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (auth.isDonor) ...[
            _tile(context, Icons.dashboard, 'Dashboard', AppRoutes.donorDashboard),
            _tile(context, Icons.history, 'Donation History', AppRoutes.donationHistory),
            _tile(context, Icons.star, 'Rewards', AppRoutes.donorRewards),
            _tile(context, Icons.check_circle, 'Eligibility', AppRoutes.eligibility),
          ],
          if (auth.isReceiver) ...[
            _tile(context, Icons.dashboard, 'Dashboard', AppRoutes.receiverDashboard),
            _tile(context, Icons.bloodtype, 'Request Blood', AppRoutes.bloodRequest),
            _tile(context, Icons.sos, 'SOS Alert', AppRoutes.sosAlert),
          ],
          _tile(context, Icons.notifications, 'Notifications', AppRoutes.notifications),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }

  ListTile _tile(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}