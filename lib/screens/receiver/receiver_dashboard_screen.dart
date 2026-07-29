import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/blood_request_model.dart';
import '../../utils/app_animations.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import 'blood_request_form_screen.dart';
import 'sos_emergency_screen.dart';
import '../maps/nearby_donors_map_screen.dart'; // Nearby Donors map
import 'donor_matching_screen.dart'; // Find Donors for a specific request

/// ✅ UI POLISH ONLY — all 3 features added earlier this session (SOS
/// button → SosEmergencyScreen, "Find Nearby Donors" → NearbyDonorsMapScreen,
/// per-request "Find Donors" → DonorMatchingScreen with requestId) are
/// untouched: same destinations, same params, same imports. Only the
/// visual layer changed (badges, spacing, entrance animation, empty state).
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
                  child: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Receiver Dashboard',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Welcome Card ──
                FadeInAnimation(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryBlue,
                          AppColors.primaryRed.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
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
                ),

                const SizedBox(height: AppSpacing.xxl + 1),

                // ── SOS Button (unchanged destination: SosEmergencyScreen) ──
                SlideInAnimation(
                  delay: const Duration(milliseconds: 80),
                  child: ElevatedButton.icon(
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
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: AppSpacing.elevationMedium,
                      shadowColor: AppColors.shadowRed,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Create Request (unchanged destination: BloodRequestFormScreen) ──
                _actionTile(
                  title: 'Create Blood Request',
                  icon: Icons.add_circle_outline,
                  color: AppColors.secondaryBlue,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BloodRequestFormScreen()),
                    );
                    // Form submit hone ke baad list auto-refresh hogi (StreamBuilder)
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Find Nearby Donors on Map (unchanged destination: NearbyDonorsMapScreen) ──
                _actionTile(
                  title: 'Find Nearby Donors',
                  icon: Icons.map_outlined,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NearbyDonorsMapScreen()),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxl + 6),

                const Text(
                  'My Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Real Firebase Requests (StreamBuilder) — unchanged query ──
                uid.isEmpty
                    ? const Center(child: Text('Not logged in'))
                    : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('blood_requests')
                      .where('requesterId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const LoadingShimmerList(itemCount: 2);
                    }

                    final docs = snap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No requests yet',
                        message: 'Tap "Create Blood Request" to add one.',
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

                const SizedBox(height: AppSpacing.xxl),
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
      elevation: AppSpacing.elevationLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }

  BadgeStatus _badgeStatusFor(String status) {
    switch (status) {
      case 'fulfilled':
        return BadgeStatus.verified;
      case 'rejected':
        return BadgeStatus.rejected;
      default:
        return BadgeStatus.pending;
    }
  }

  Widget _requestCard(BloodRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      elevation: AppSpacing.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    BloodTypeBadge(bloodGroup: request.bloodGroup),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${request.unitsRequired ?? request.quantity} Units',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                StatusBadge(
                  status: _badgeStatusFor(request.status),
                  customLabel: request.status,
                  customColor: null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: AppSpacing.iconSm, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(request.hospitalName,
                      style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: AppSpacing.iconSm, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(request.location,
                      style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            if (request.urgency.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              UrgencyBadge(urgency: request.urgency),
            ],
            // ── Find Donors (unchanged: DonorMatchingScreen with requestId,
            // needed for confirmDonation Cloud Function authorization) ──
            if (request.status != 'fulfilled') ...[
              const SizedBox(height: AppSpacing.sm + 2),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DonorMatchingScreen(
                          initialBloodGroup: request.bloodGroup,
                          requestId: request.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Find Donors'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    side: const BorderSide(color: AppColors.primaryRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}