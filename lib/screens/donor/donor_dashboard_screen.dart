import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import 'donor_profile_screen.dart';
import 'donation_history_screen.dart';
import 'blood_request_detail_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  int _donationCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // User profile load karo
      final userDoc = await _firestore.collection('users').doc(uid).get();

      // Donation count load karo
      final donations = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: uid)
          .get();

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _donationCount = donations.size;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    final name = _userData?['name'] ?? 'Donor';
    final bloodGroup = _userData?['bloodGroup'] ?? '—';
    final rewardPoints = _userData?['rewardPoints'] ?? 0;
    final isEligible = _userData?['isEligible'] ?? true;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'D',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Blood Group: $bloodGroup',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Stats Row ──
              Row(
                children: [
                  _buildStatCard(
                    title: 'Donations',
                    value: '$_donationCount',
                    icon: Icons.bloodtype,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    title: 'Points',
                    value: '$rewardPoints',
                    icon: Icons.stars,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Eligibility Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isEligible
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isEligible ? AppColors.success : AppColors.warning,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEligible ? Icons.check_circle : Icons.schedule,
                      size: 34,
                      color: isEligible ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      isEligible ? 'Eligible to Donate' : 'Not Eligible Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEligible ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 15),

              // ── My Profile ──
              // ── Available Blood Requests ──
              const Text(
                'Blood Requests Near You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'People who need blood donation',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('blood_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryRed));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Koi pending request nahi abhi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final urgency = d['urgency'] ?? 'Normal';
                      final urgencyColor = urgency == 'Critical'
                          ? Colors.red
                          : urgency == 'Urgent'
                          ? Colors.orange
                          : Colors.green;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BloodRequestDetailScreen(requestData: d),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Blood group badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryRed
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.primaryRed
                                                .withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        d['bloodGroup'] ?? '?',
                                        style: const TextStyle(
                                          color: AppColors.primaryRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Urgency badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                        urgencyColor.withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        urgency,
                                        style: TextStyle(
                                          color: urgencyColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Patient name
                                if (d['patientName'] != null)
                                  Row(children: [
                                    const Icon(Icons.person_outline,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(d['patientName'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ]),
                                const SizedBox(height: 4),
                                // Hospital
                                Row(children: [
                                  const Icon(Icons.local_hospital_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      d['hospitalName'] ?? 'Unknown',
                                      style: const TextStyle(
                                          color: Colors.grey),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                // Location
                                if (d['location'] != null &&
                                    d['location'].toString().isNotEmpty)
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(d['location'],
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ),
                                  ]),
                                const SizedBox(height: 4),
                                // Units
                                Row(children: [
                                  const Icon(Icons.bloodtype_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${d['unitsRequired'] ?? d['quantity'] ?? 1} units required',
                                    style:
                                    const TextStyle(color: Colors.grey),
                                  ),
                                ]),
                                // Contact number
                                if (d['contactNumber'] != null &&
                                    d['contactNumber']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.call, size: 16),
                                      label: Text(
                                          'Contact: ${d['contactNumber']}'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryRed,
                                        side: BorderSide(
                                            color: AppColors.primaryRed
                                                .withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ), // Card
                      ); // GestureDetector
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 15),

              _buildActionTile(
                title: 'My Profile',
                icon: Icons.person,
                color: AppColors.secondaryBlue,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonorProfileScreen(
                        userData: _userData ?? {},
                      ),
                    ),
                  );
                  // Profile update ke baad refresh karo
                  _loadUserData();
                },
              ),

              _buildActionTile(
                title: 'Donation History',
                icon: Icons.history,
                color: AppColors.secondaryGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DonationHistoryScreen(),
                    ),
                  );
                },
              ),

              _buildActionTile(
                title: 'Rewards & Certificates',
                icon: Icons.card_giftcard,
                color: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RewardsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Rewards Screen')),
    );
  }
}