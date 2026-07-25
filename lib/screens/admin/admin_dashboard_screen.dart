import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import 'admin_guard.dart';
// These two screens already exist in your project from earlier fixes —
// wire this dashboard's buttons to them.
import 'admin_requests_screen.dart';
// import 'web/admin_web_users.dart'; // adjust import path to match your
// actual users-management screen if the path differs.

/// ✅ PHASE 1 — Admin Dashboard
///
/// Shows KPI cards (total donors, receivers, open requests, fulfilled
/// requests) computed live from Firestore, plus quick-access buttons to
/// Users management and Requests management.
///
/// Wrapped in AdminGuard so only an approved admin can view it.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: AppColors.primaryDarkRed,
          foregroundColor: Colors.white,
        ),
        body: const _DashboardBody(),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _KpiGrid(),
          const SizedBox(height: 24),
          const Text(
            'Manage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ManageButton(
            icon: Icons.people_outline,
            label: 'Users Management',
            subtitle: 'Approve, reject, or suspend users',
            onTap: () {
              // TODO: adjust to your actual users-management screen class
              // name if different, e.g. AdminWebUsers().
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Wire this button to your existing Users management '
                        'screen (e.g. AdminWebUsers).',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ManageButton(
            icon: Icons.bloodtype_outlined,
            label: 'Requests Management',
            subtitle: 'View & update blood request statuses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ KPI GRID ═══════════════════════════

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          title: 'Total Donors',
          icon: Icons.volunteer_activism,
          color: Colors.red,
          stream: firestore
              .collection(AppConstants.usersCollection)
              .where('role', isEqualTo: 'donor')
              .snapshots()
              .map((s) => s.size),
        ),
        _KpiCard(
          title: 'Total Receivers',
          icon: Icons.person_search,
          color: Colors.blue,
          stream: firestore
              .collection(AppConstants.usersCollection)
              .where('role', isEqualTo: 'receiver')
              .snapshots()
              .map((s) => s.size),
        ),
        _KpiCard(
          title: 'Open Requests',
          icon: Icons.pending_actions,
          color: Colors.orange,
          stream: firestore
              .collection(AppConstants.bloodRequestsCollection)
              .where('status', isEqualTo: 'pending')
              .snapshots()
              .map((s) => s.size),
        ),
        _KpiCard(
          title: 'Fulfilled Requests',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          stream: firestore
              .collection(AppConstants.bloodRequestsCollection)
              .where('status', isEqualTo: 'fulfilled')
              .snapshots()
              .map((s) => s.size),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<int> stream;

  const _KpiCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final count = snapshot.data ?? 0;
                return Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ MANAGE BUTTON ═══════════════════════════

class _ManageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryRed.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primaryRed),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}