import 'package:flutter/material.dart';

// Screens
part 'admin_screens/admin_web_users.dart';
part 'admin_screens/admin_web_requests.dart';
part 'admin_screens/admin_web_analytics.dart';
part 'admin_screens/admin_web_donations.dart';
part 'admin_screens/admin_web_reports.dart';
part 'admin_screens/admin_web_notifications.dart';

// Widgets
part 'admin_widgets/sidebar_widget.dart';
part 'admin_widgets/top_bar_widget.dart';
part 'admin_widgets/stat_card_widget.dart';
part 'admin_widgets/chart_widget.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({Key? key}) : super(key: key);

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int _selectedIndex = 0;
  String _userName = "Admin User";
  String _userEmail = "admin@bloodlink.com";

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _DashboardHome(),
      const AdminWebUsers(),
      const AdminWebRequests(),
      const AdminWebAnalytics(),
      const AdminWebDonations(),
      const AdminWebReports(),
      const AdminWebNotifications(),
    ];
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleLogout() {
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
  }

  void _handleNotification() {
    print('Notification clicked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            onLogout: _handleLogout,
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
}

// Dashboard Home Screen
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
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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