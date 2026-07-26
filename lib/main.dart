import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'constants/app_theme.dart'; // ✅ USE THIS
import 'services/push_navigation_service.dart'; // ✅ NEW — FCM foreground/tap handling

// ✅ NEW — Controllers, provided below via MultiProvider.
import 'controllers/auth_controller.dart';
import 'controllers/donor_controller.dart';
import 'controllers/receiver_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/reward_controller.dart';

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

  // ✅ NEW — must be registered before runApp(), so FCM can deliver
  // background messages to this handler even when the app is killed.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const BloodBankApp());

  // ✅ NEW — sets up foreground banner + tap-to-navigate listeners.
  // Safe to call after runApp(): listeners are registered immediately,
  // and any actual navigation waits for the first frame internally.
  PushNavigationService.instance.init();
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ NEW — MultiProvider wrapper.
    // ------------------------------------------------------------------
    // WHY THIS WAS MISSING AND WHY IT MATTERS:
    // lib/app/app.dart (SmartBloodBankApp) already sets up exactly this
    // MultiProvider — but main() never runs SmartBloodBankApp, it runs
    // THIS widget (BloodBankApp), which never had any Provider wrapping
    // it. Two screens that ARE reachable from this actually-running app
    // depend on these controllers and were crashing as a result:
    //   - ReceiverDashboardScreen → "SOS Alert" button → SosEmergencyScreen
    //     (needs ReceiverController) — a live crash on a safety-critical
    //     feature.
    //   - DonorDashboardScreen → Rewards → RewardsScreen (needs
    //     RewardController) — a live crash on the rewards feature.
    // All 6 controllers are added here (matching the original intended
    // design in app.dart) so any other screen relying on them going
    // forward (e.g. if AppDrawer ever gets wired into a Scaffold) works
    // too, without needing to revisit this file again.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => DonorController()),
        ChangeNotifierProvider(create: (_) => ReceiverController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => RewardController()),
      ],
      child: MaterialApp(
        title: 'Blood Bank',
        debugShowCheckedModeBanner: false,

        // ✅ NEW — lets PushNavigationService navigate from outside the
        // widget tree (e.g. from a notification tap callback).
        navigatorKey: rootNavigatorKey,

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
      ),
    );
  }
}