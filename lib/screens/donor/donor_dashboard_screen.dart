import '../requests/request_list_screen.dart';
import '../../utils/eligibility_checker.dart';
import '../../utils/feedback.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

import '../notification/notification_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/app_animations.dart';



import '../../widgets/app_custom_widgets.dart';
import '../../widgets/status_badge.dart';
import 'donor_profile_screen.dart';
import 'donation_history_screen.dart';

import 'rewards_screen.dart'; // ✅ FIX — see note below
import '../settings/settings_screen.dart'; // ✅ NEW — was never reachable anywhere in the app

/// ✅ FIXED BUG — this file used to define its OWN local `RewardsScreen`
/// class (a placeholder that just showed the text "Rewards Screen"), while
/// the REAL rewards feature (tier progress, certificates, gamification —
/// lib/screens/donor/rewards_screen.dart) sat unused right next to it with
/// the exact same class name. Since this file never imported that real
/// file, "Rewards & Certificates" always opened the placeholder — the real
/// screen was completely unreachable. Now this file imports the real
/// RewardsScreen and no longer defines a duplicate.
///
/// ✅ ALSO FIXED — the "Contact: number" button on each request card had
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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw StateError('Please sign in.');

      // User profile load karo
      final userDoc = await _firestore.collection('users').doc(uid).get();

      // Donation count load karo
      final donations =
          await _firestore
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = AppFeedback.message(e);
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donor Dashboard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              TextButton(onPressed: _loadUserData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final liveUser = context.watch<AuthController>().currentUser;
    if (liveUser != null) {
      _userData = {...?_userData, ...liveUser.toFirestore()};
    }
    final name = _userData?['name'] ?? 'Donor';
    final bloodGroup = _userData?['bloodGroup'] ?? '—';
    final rewardPoints = _userData?['rewardPoints'] ?? 0;
    final isEligible = EligibilityChecker.isEligibleForDonation(
      (_userData?['lastDonationDate'] as Timestamp?)?.toDate(),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/role-select'),
        ),
        title: Text(
          'Donor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationHistoryScreen(),
                  ),
                ),
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
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
                          style: TextStyle(
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
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Blood Group: ',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                BloodTypeBadge(
                                  bloodGroup: bloodGroup,
                                  fontSize: 12,
                                ),
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
                    color:
                        isEligible
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
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
                        color:
                            isEligible ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.md + 3),
                      Expanded(
                        child: Text(
                          isEligible
                              ? 'Eligible to Donate'
                              : 'Not Eligible Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isEligible
                                    ? AppColors.success
                                    : AppColors.warning,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl + 1),

              // ── Available Blood Requests ──
              Text(
                'Matching Blood Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'People who need blood donation',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: AppSpacing.md),

              _buildActionTile(title:'My Active Donations',icon:Icons.volunteer_activism,color:AppColors.primaryRed,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RequestListScreen(mode:'active')))),
              _buildActionTile(title:'Browse matching requests',icon:Icons.search,color:Colors.teal,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RequestListScreen(mode:'discover')))),

              const SizedBox(height: AppSpacing.xxl + 1),

              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                      builder:
                          (_) => DonorProfileScreen(userData: _userData ?? {}),
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
                    ), // ✅ now the real screen
                  );
                },
              ),

              // ✅ NEW — SettingsScreen (notifications, theme, privacy,
              // help/about, legal, sign out) existed as a complete, working
              // file but had no button anywhere in the app that opened it.
              _buildActionTile(
                title: 'Settings',
                icon: Icons.settings_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
