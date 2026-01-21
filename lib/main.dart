import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // 🔥 flutterfire CLI se generate hoti hai
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';

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
          fillColor: Colors.grey,
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
      ),

      // Initial Route
      home: const SplashScreen(),

      // Named Routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
