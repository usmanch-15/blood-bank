import 'package:flutter/material.dart';


import 'firebase_options.dart'; // 🔥 flutterfire CLI se generate hoti hai
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/web/admin_web_login.dart';
import 'screens/admin/web/admin_web_dashboard.dart';


/// Main entry point of the Blood Bank application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Proper Firebase initialization (Web + Android safe)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BloodBankApp());
}

/// Root widget of the application
class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Bank',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryRed,
          primary: AppColors.primaryRed,
          secondary: AppColors.secondaryBlue,
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
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Initial Route - Splash screen will decide where to go
      home: const SplashScreen(),

      // Named Routes - Both User and Admin routes
      routes: {
        // User Routes
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),

        // Admin Routes
        '/admin/login': (context) => const AdminWebLogin(),
        '/admin/dashboard': (context) => const AdminWebDashboard(),
        '/admin/users': (context) => const AdminWebUsers(),
        '/admin/requests': (context) => const AdminWebRequests(),
        '/admin/analytics': (context) => const AdminWebAnalytics(),
        '/admin/donations': (context) => const AdminWebDonations(),
        '/admin/reports': (context) => const AdminWebReports(),
        '/admin/notifications': (context) => const AdminWebNotifications(),
      },

      // Optional: Handle unknown routes gracefully
      onGenerateRoute: (settings) {
        // If route doesn't exist, redirect to splash
        if (settings.name != null &&
            !['/splash', '/login', '/admin/login', '/admin/dashboard',
              '/admin/users', '/admin/requests', '/admin/analytics',
              '/admin/donations', '/admin/reports', '/admin/notifications']
                .contains(settings.name)) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Page not found'),
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}