import 'package:flutter/material.dart';
import '../screens/admin/web/admin_web_login.dart';
import '../screens/admin/web/admin_web_dashboard.dart';
import '../screens/admin/web/admin_web_requests.dart';
import '../screens/admin/web/admin_web_users.dart';


class AdminRoutes {
  static const String login = '/admin/login';
  static const String dashboard = '/admin/dashboard';
  static const String users = '/admin/users';
  static const String requests = '/admin/requests';
  static const String analytics = '/admin/analytics';
  static const String donations = '/admin/donations';
  static const String reports = '/admin/reports';
  static const String notifications = '/admin/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const AdminWebLogin());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const AdminWebDashboard());
      case users:
        return MaterialPageRoute(builder: (_) => const AdminWebUsers());
      case requests:
        return MaterialPageRoute(builder: (_) => const AdminWebRequests());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 - Page Not Found')),
          ),
        );
    }
  }
}