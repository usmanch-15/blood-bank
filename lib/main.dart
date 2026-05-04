import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/donor/donor_dashboard_screen.dart';
import 'screens/receiver/receiver_dashboard_screen.dart';
import 'screens/admin/web/admin_web_login.dart';
import 'screens/admin/web/admin_web_dashboard.dart';
import 'screens/admin/web/admin_web_users.dart';
import 'screens/admin/web/admin_web_requests.dart';
import 'screens/admin/web/admin_web_analytics.dart';
import 'screens/admin/web/admin_web_donations.dart';
import 'screens/admin/web/admin_web_reports.dart';
import 'screens/admin/web/admin_web_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not configured — running in demo mode: $e');
  }

  runApp(const BloodBankApp());
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
      child: MaterialApp(
        title: 'Blood Bank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryRed,
          primary: AppColors.primaryRed,
          secondary: AppColors.primaryLightRed,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryRed),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryRed;
            }
            return null;
          }),
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.primaryRed.withOpacity(0.15),
          labelStyle: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/donor/dashboard': (context) => const DonorDashboardScreen(),
        '/receiver/dashboard': (context) => const ReceiverDashboardScreen(),
        '/admin/login': (context) => const AdminWebLogin(),
        '/admin/dashboard': (context) => const AdminWebDashboard(),
        '/admin/users': (context) => const AdminWebUsers(),
        '/admin/requests': (context) => const AdminWebRequests(),
        '/admin/analytics': (context) => const AdminWebAnalytics(),
        '/admin/donations': (context) => const AdminWebDonations(),
        '/admin/reports': (context) => const AdminWebReports(),
        '/admin/notifications': (context) => const AdminWebNotifications(),
      },
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Page not found')),
            ),
          );
        },
      ),
    );
  }
}
