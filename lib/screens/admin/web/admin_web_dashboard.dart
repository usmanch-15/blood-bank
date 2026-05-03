import 'package:flutter/material.dart';
import '../../../widgets/web/stat_card_widget.dart';
import '../../../widgets/web/chart_widget.dart';
import '../../../widgets/web/top_bar_widget.dart';
import '../../../widgets/web/sidebar_widget.dart';
import 'admin_web_users.dart';
import 'admin_web_requests.dart';
import 'admin_web_analytics.dart';
import 'admin_web_donations.dart';
import 'admin_web_reports.dart';
import 'admin_web_notifications.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({Key? key}) : super(key: key);

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int _selectedIndex = 0;
  String _userName = "Admin User";
  String _userEmail = "admin@bloodlink.com";

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens.addAll([
      const _DashboardHome(),
      const AdminWebUsers(),
      const AdminWebRequests(),
      const AdminWebAnalytics(),
      const AdminWebDonations(),
      const AdminWebReports(),
      const AdminWebNotifications(),
    ]);
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
          Expanded(
            child: Column(
              children: [
                TopBarWidget(
                  userName: _userName,
                  userEmail: _userEmail,
                  onLogout: _handleLogout,
                  onSearch: _handleSearch,
                  onNotification: _handleNotification,
                ),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    // Implement logout logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Navigate to login
              Navigator.pushReplacementNamed(context, '/admin/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleSearch(String query) {
    print('Searching: $query');
    // Implement search logic
  }

  void _handleNotification() {
    print('Notification clicked');
    // Show notifications panel
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              StatCardWidget(
                title: 'Total Users',
                value: '1,234',
                icon: Icons.people,
                color: Colors.blue,
                percentage: '+12%',
              ),
              StatCardWidget(
                title: 'Blood Requests',
                value: '89',
                icon: Icons.bloodtype,
                color: Colors.red,
                percentage: '+5%',
              ),
              StatCardWidget(
                title: 'Donations',
                value: '456',
                icon: Icons.favorite,
                color: Colors.green,
                percentage: '+8%',
              ),
              StatCardWidget(
                title: 'Active Donors',
                value: '789',
                icon: Icons.people_outline,
                color: Colors.orange,
                percentage: '+15%',
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const ChartWidget(),
          ),
        ],
      ),
    );
  }
}