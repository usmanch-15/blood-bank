import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/app_animations.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_custom_widgets.dart';
import 'donor_profile_screen.dart';
import 'donation_history_screen.dart';
import 'blood_request_detail_screen.dart';
import 'rewards_screen.dart'; // ✅ FIX — see note below

/// ✅ FIXED BUG — this file used to define its OWN local `RewardsScreen`
/// class (a placeholder that just showed the text "Rewards Screen"), while
/// the REAL rewards feature (tier progress, certificates, gamification —
/// lib/screens/donor/rewards_screen.dart) sat unused right next to it with
/// the exact same class name. Since this file never imported that real
/// file, "Rewards & Certificates" always opened the placeholder — the real
/// screen was completely unreachable. Now this file imports the real
/// RewardsScreen and no longer defines a duplicate.
///
/// ✅ ALSO FIXED — the "Contact: <number>" button on each request card had
/// `onPressed: () {}` (did nothing at all when tapped). Now it opens the
/// phone dialer.
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

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer.')),
        );
      }
    }
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Card ──
              FadeInAnimation(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowRed,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Blood Group: ',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                BloodTypeBadge(bloodGroup: bloodGroup, fontSize: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Stats Row ──
              SlideInAnimation(
                delay: const Duration(milliseconds: 80),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Donations',
                        value: '$_donationCount',
                        icon: Icons.bloodtype,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md + 3),
                    Expanded(
                      child: StatCard(
                        label: 'Points',
                        value: '$rewardPoints',
                        icon: Icons.stars,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Eligibility Card ──
              SlideInAnimation(
                delay: const Duration(milliseconds: 140),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg + 2),
                  decoration: BoxDecoration(
                    color: isEligible
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                      const SizedBox(width: AppSpacing.md + 3),
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
              ),
              const SizedBox(height: AppSpacing.xxl + 1),

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
              const SizedBox(height: AppSpacing.md),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('blood_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LoadingShimmerList(itemCount: 2);
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.bloodtype_outlined,
                      title: 'No pending requests right now',
                      message: 'New nearby requests will show up here as they come in.',
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final urgency = d['urgency'] ?? 'Normal';

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BloodRequestDetailScreen(requestData: d),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                          elevation: AppSpacing.elevationLow,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    BloodTypeBadge(bloodGroup: d['bloodGroup'] ?? '?'),
                                    UrgencyBadge(urgency: urgency),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm + 2),
                                // Patient name
                                if (d['patientName'] != null)
                                  Row(children: [
                                    const Icon(Icons.person_outline,
                                        size: AppSpacing.iconSm, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(d['patientName'],
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ]),
                                const SizedBox(height: 4),
                                // Hospital
                                Row(children: [
                                  const Icon(Icons.local_hospital_outlined,
                                      size: AppSpacing.iconSm, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      d['hospitalName'] ?? 'Unknown',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                // Location
                                if (d['location'] != null &&
                                    d['location'].toString().isNotEmpty)
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: AppSpacing.iconSm, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(d['location'],
                                          style: const TextStyle(color: Colors.grey)),
                                    ),
                                  ]),
                                const SizedBox(height: 4),
                                // Units
                                Row(children: [
                                  const Icon(Icons.bloodtype_outlined,
                                      size: AppSpacing.iconSm, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${d['unitsRequired'] ?? d['quantity'] ?? 1} units required',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ]),
                                // Contact number — ✅ FIX: now actually opens the dialer
                                if (d['contactNumber'] != null &&
                                    d['contactNumber'].toString().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm + 2),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.call, size: AppSpacing.iconSm),
                                      label: Text('Contact: ${d['contactNumber']}'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryRed,
                                        side: BorderSide(
                                            color: AppColors.primaryRed.withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(AppSpacing.radiusSm + 2)),
                                      ),
                                      onPressed: () => _callNumber(d['contactNumber']),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl + 1),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg - 1),

              _buildActionTile(
                title: 'My Profile',
                icon: Icons.person,
                color: AppColors.secondaryBlue,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonorProfileScreen(userData: _userData ?? {}),
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
                    MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
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
                    MaterialPageRoute(builder: (_) => const RewardsScreen()), // ✅ now the real screen
                  );
                },
              ),
            ],
          ),
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
      elevation: AppSpacing.elevationLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
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