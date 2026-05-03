import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  final List<Map<String, dynamic>> _menuItems = const [
    {
      'icon': Icons.dashboard,
      'title': 'Dashboard',
      'index': 0,
    },
    {
      'icon': Icons.people,
      'title': 'Users',
      'index': 1,
    },
    {
      'icon': Icons.bloodtype,
      'title': 'Blood Requests',
      'index': 2,
    },
    {
      'icon': Icons.analytics,
      'title': 'Analytics',
      'index': 3,
    },
    {
      'icon': Icons.favorite,
      'title': 'Donations',
      'index': 4,
    },
    {
      'icon': Icons.report,
      'title': 'Reports',
      'index': 5,
    },
    {
      'icon': Icons.notifications,
      'title': 'Notifications',
      'index': 6,
    },
    {
      'icon': Icons.settings,
      'title': 'Settings',
      'index': 7,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade800,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.bloodtype,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'BloodLink Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  'Management Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = selectedIndex == item['index'];

                return _buildMenuItem(
                  icon: item['icon'],
                  title: item['title'],
                  isSelected: isSelected,
                  onTap: () => onItemSelected(item['index']),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Logout Button
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            isSelected: false,
            onTap: () => _showLogoutDialog(context),
            isLogout: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.shade50
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.red.shade700
                  : (isLogout ? Colors.red : Colors.grey.shade600),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.red.shade700
                      : (isLogout ? Colors.red : Colors.grey.shade700),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.red.shade700,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
          ElevatedButton(
            onPressed: () {
              // Implement logout logic
              Navigator.pushReplacementNamed(context, '/admin/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}