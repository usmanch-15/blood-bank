import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/donor/donor_dashboard_screen.dart' hide RewardsScreen;
import '../screens/donor/donor_profile_screen.dart';
import '../screens/donor/donation_history_screen.dart';
import '../screens/donor/eligibility_status_screen.dart';
import '../screens/donor/rewards_screen.dart';
import '../screens/receiver/receiver_dashboard_screen.dart';
import '../screens/receiver/blood_request_form_screen.dart';
import '../screens/receiver/sos_emergency_screen.dart';
import '../screens/notification/notification_list_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/maps/nearby_donors_map_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String donorDashboard = '/donor/dashboard';
  static const String donorProfile = '/donor/profile';
  static const String donationHistory = '/donor/history';
  static const String eligibility = '/donor/eligibility';
  static const String donorRewards = '/donor/rewards';
  static const String receiverDashboard = '/receiver/dashboard';
  static const String bloodRequest = '/receiver/request';
  static const String sosAlert = '/receiver/sos';
  static const String notifications = '/notifications';
  static const String adminLogin = '/admin/login';
  static const String nearbyDonors = '/map/nearby';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    home: (_) => HomeScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignUpScreen(),
    donorDashboard: (_) => const DonorDashboardScreen(),
    donorProfile: (_) => const DonorProfileScreen(userData: {},),
    donationHistory: (_) => const DonationHistoryScreen(),
    eligibility: (_) => const EligibilityStatusScreen(),
    donorRewards: (_) => const RewardsScreen(),
    receiverDashboard: (_) => const ReceiverDashboardScreen(),
    bloodRequest: (_) => const BloodRequestFormScreen(),
    sosAlert: (_) => const SosEmergencyScreen(),
    notifications: (_) => const NotificationListScreen(),
    adminLogin: (_) => const AdminLoginScreen(),
    nearbyDonors: (_) => const NearbyDonorsMapScreen(),
  };
}