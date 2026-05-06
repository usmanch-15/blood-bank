import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'constants/app_theme.dart'; // ✅ USE THIS

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/donor/donor_dashboard_screen.dart';
import 'screens/receiver/receiver_dashboard_screen.dart';

// Admin Web Screens
import 'screens/admin/web/admin_web_login.dart';
import 'screens/admin/web/admin_web_dashboard.dart';
import 'screens/admin/web/admin_web_users.dart';
import 'screens/admin/web/admin_web_requests.dart';
import 'screens/admin/web/admin_web_donations.dart';
import 'screens/admin/web/admin_web_analytics.dart';
import 'screens/admin/web/admin_web_reports.dart';
import 'screens/admin/web/admin_web_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BloodBankApp());
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Bank',
      debugShowCheckedModeBanner: false,

      // ✅ ONLY CHANGE (Theme apply)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      home: const SplashScreen(), // 👈 SAME as tumhara code

      routes: {
        '/splash':        (context) => const SplashScreen(),
        '/login':         (context) => const LoginScreen(),
        '/role-select':   (context) => const RoleSelectionScreen(),
        '/donor':         (context) => const DonorDashboardScreen(),
        '/receiver':      (context) => const ReceiverDashboardScreen(),

        // Admin Routes
        '/admin/login':         (context) => const AdminWebLogin(),
        '/admin/dashboard':     (context) => const AdminWebDashboard(),
        '/admin/users':         (context) => const AdminWebUsers(),
        '/admin/requests':      (context) => const AdminWebRequests(),
        '/admin/donations':     (context) => const AdminWebDonations(),
        '/admin/analytics':     (context) => const AdminWebAnalytics(),
        '/admin/reports':       (context) => const AdminWebReports(),
        '/admin/notifications': (context) => const AdminWebNotifications(),
      },
    );
  }
}