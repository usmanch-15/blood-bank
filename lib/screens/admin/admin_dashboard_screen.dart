import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
// import '../../services/auth_service.dart';        // 🔴 COMMENTED
// import '../../services/firestore_service.dart'; // 🔴 COMMENTED
import 'admin_users_screen.dart';
import 'admin_requests_screen.dart';

/// Admin Dashboard - Main screen for administrators
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // final _authService = AuthService();            // 🔴 COMMENTED
  // final _firestoreService = FirestoreService(); // 🔴 COMMENTED

  // Map<String, dynamic>? _stats;                 // 🔴 COMMENTED
  bool _isLoading = false; // 🔧 direct false for frontend demo

  @override
  void initState() {
    super.initState();
    // _loadStats(); // 🔴 COMMENTED
  }

  /*
  Future<void> _loadStats() async {
    try {
      final stats = await _firestoreService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primaryDarkRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {}, // 🔧 no backend
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dashboard Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            /// 🔧 STATIC / DUMMY DATA (Frontend only)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Users',
                    value: '120',
                    icon: Icons.people,
                    color: AppColors.secondaryBlue,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Donors',
                    value: '80',
                    icon: Icons.bloodtype,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Receivers',
                    value: '40',
                    icon: Icons.local_hospital,
                    color: AppColors.secondaryGreen,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending Requests',
                    value: '12',
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildStatCard(
              title: 'Total Donations',
              value: '56',
              icon: Icons.favorite,
              color: AppColors.error,
            ),

            const SizedBox(height: 30),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 15),

            _buildActionCard(
              title: 'View All Users',
              icon: Icons.people_outline,
              color: AppColors.secondaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            _buildActionCard(
              title: 'View Blood Requests',
              icon: Icons.list_alt,
              color: AppColors.secondaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminRequestsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
        onTap: onTap,
      ),
    );
  }
}
