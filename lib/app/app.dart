import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/donor_controller.dart';
import '../controllers/receiver_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/reward_controller.dart';
import 'routes.dart';
import '../constants/app_theme.dart';

class SmartBloodBankApp extends StatelessWidget {
  const SmartBloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: 'Smart Blood Bank',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}