import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_web_users.dart';
import 'admin_web_requests.dart';
import 'admin_web_analytics.dart';
import 'admin_web_donations.dart';
import 'admin_web_reports.dart';
import '../../auth/login_screen.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({Key? key}) : super(key: key);

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _DashboardHome(),
      AdminWebUsers(),
      AdminWebRequests(),
      AdminWebAnalytics(),
      AdminWebDonations(),
      AdminWebReports(),
    ];
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.bloodtype, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Blood Connect — Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      body: isWide
          ? Row(
        children: [
          _SideBar(
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      )
          : _screens[_selectedIndex],
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.red.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bloodtype), label: "Requests"),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: "Analytics"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Donations"),
          BottomNavigationBarItem(
              icon: Icon(Icons.report), label: "Reports"),
        ],
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────
class _SideBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SideBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.dashboard, 'Dashboard'],
      [Icons.people, 'Users'],
      [Icons.bloodtype, 'Blood Requests'],
      [Icons.analytics, 'Analytics'],
      [Icons.favorite, 'Donations'],
      [Icons.report, 'Reports'],
    ];

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          ...List.generate(items.length, (i) {
            final selected = selectedIndex == i;
            return ListTile(
              leading: Icon(
                items[i][0] as IconData,
                color: selected ? Colors.red.shade700 : Colors.grey,
              ),
              title: Text(
                items[i][1] as String,
                style: TextStyle(
                  color:
                  selected ? Colors.red.shade700 : Colors.grey.shade700,
                  fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              tileColor: selected ? Colors.red.shade50 : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () => onTap(i),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Dashboard Home ───────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  const _DashboardHome({Key? key}) : super(key: key);

  Future<Map<String, int>> _fetchStats() async {
    final db = FirebaseFirestore.instance;

    // Sab Firebase se real data
    final users = await db.collection('users').get();
    final requests = await db.collection('blood_requests').get();
    final donations = await db.collection('donations').get();

    // Pending user approvals (naye sign up wale)
    final pendingUsers = await db
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .get();

    return {
      'users': users.size,
      'requests': requests.size,
      'donations': donations.size,
      'pendingUsers': pendingUsers.size, // ← naye users approval awaiting
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ── Stat Cards (real Firebase data) ──
          FutureBuilder<Map<String, int>>(
            future: _fetchStats(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data ?? {
                'users': 0,
                'requests': 0,
                'donations': 0,
                'pendingUsers': 0,
              };

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'Total Users',
                    value: '${data['users']}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    label: 'Blood Requests',
                    value: '${data['requests']}',
                    icon: Icons.bloodtype,
                    color: Colors.red,
                  ),
                  _StatCard(
                    label: 'Donations',
                    value: '${data['donations']}',
                    icon: Icons.favorite,
                    color: Colors.green,
                  ),
                  // ← Pending user approvals ka real card
                  _StatCard(
                    label: 'Pending Approvals',
                    value: '${data['pendingUsers']}',
                    icon: Icons.person_add_alt_1,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          const Text(
            'Recent Blood Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // ── Recent Blood Requests (real Firebase) ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('blood_requests')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('Koi blood request nahi abhi tak.',
                    style: TextStyle(color: Colors.grey));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'pending';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: Text(
                          d['bloodGroup'] ?? '?',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(d['patientName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(d['hospital'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'pending'
                              ? Colors.orange.shade50
                              : status == 'fulfilled'
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'pending'
                                ? Colors.orange.shade700
                                : status == 'fulfilled'
                                ? Colors.green.shade700
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 32),
          const Text(
            'Recent Users',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // ── Recent Users (real Firebase) ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('Koi user nahi abhi tak.',
                    style: TextStyle(color: Colors.grey));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'pending';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'pending'
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        child: Text(
                          (d['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                              color: status == 'pending'
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(d['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(d['email'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'pending'
                              ? Colors.orange.shade50
                              : status == 'approved'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'pending'
                                ? Colors.orange.shade700
                                : status == 'approved'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}