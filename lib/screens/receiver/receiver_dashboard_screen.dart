import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/blood_request_model.dart';
import 'blood_request_form_screen.dart';
import 'sos_emergency_screen.dart';

class ReceiverDashboardScreen extends StatefulWidget {
  const ReceiverDashboardScreen({super.key});

  @override
  State<ReceiverDashboardScreen> createState() =>
      _ReceiverDashboardScreenState();
}

class _ReceiverDashboardScreenState extends State<ReceiverDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (mounted) setState(() => _userData = doc.data());
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';
    final name = _userData?['name'] ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Receiver Dashboard',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Welcome Card ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondaryBlue,
                        AppColors.primaryRed.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create a request or use SOS for emergencies',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ── SOS Button ──
                ElevatedButton.icon(
                  icon: const Icon(Icons.warning, size: 28),
                  label: const Text(
                    'SOS EMERGENCY',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SosEmergencyScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Create Request ──
                _actionTile(
                  title: 'Create Blood Request',
                  icon: Icons.add_circle_outline,
                  color: Colors.blue,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BloodRequestFormScreen()),
                    );
                    // Form submit hone ke baad list auto-refresh hogi (StreamBuilder)
                  },
                ),

                const SizedBox(height: 30),

                const Text(
                  'My Requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ── Real Firebase Requests (StreamBuilder) ──
                uid.isEmpty
                    ? const Center(child: Text('Not logged in'))
                    : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('blood_requests')
                      .where('requesterId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.red));
                    }

                    final docs = snap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No requests yet.\nTap "Create Blood Request" to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final request = BloodRequestModel.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                        return _requestCard(request);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }

  Widget _requestCard(BloodRequestModel request) {
    Color statusColor;
    switch (request.status) {
      case 'fulfilled':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${request.bloodGroup}  •  ${request.unitsRequired ?? request.quantity} Units',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(request.hospitalName,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(request.location,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (request.urgency.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.priority_high, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Urgency: ${request.urgency}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}