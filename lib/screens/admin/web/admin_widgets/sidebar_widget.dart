// ✅ part of hata diya, material import lagaya
import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  }) : super(key: key);

  // ✅ const list mein Icons use ho sakta hai — material import hone ke baad
  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'index': 0},
    {'icon': Icons.people, 'title': 'Users', 'index': 1},
    {'icon': Icons.bloodtype, 'title': 'Blood Requests', 'index': 2},
    {'icon': Icons.analytics, 'title': 'Analytics', 'index': 3},
    {'icon': Icons.favorite, 'title': 'Donations', 'index': 4},
    {'icon': Icons.report, 'title': 'Reports', 'index': 5},
    {'icon': Icons.notifications, 'title': 'Notifications', 'index': 6},
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
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) => _buildMenuItem(_menuItems[index]),
            ),
          ),
          const Divider(height: 1),
          _buildLogoutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bloodtype, size: 40, color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          const Text(
            'BloodLink Admin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isSelected = selectedIndex == item['index'];
    return InkWell(
      onTap: () => onItemSelected(item['index']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              item['icon'],
              color: isSelected ? Colors.red.shade700 : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              item['title'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: onLogout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 22),
            const SizedBox(width: 12),
            Text('Logout', style: TextStyle(fontSize: 14, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}