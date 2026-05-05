import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'donor_profile_screen.dart';
import 'donation_history_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  final dummyUserData = _DummyUser(
    name: 'Usman',
    bloodGroup: 'O+',
    rewardPoints: 0,
    isEligible: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // 🔴 PROFESSIONAL APP BAR WITH BACK ARROW
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
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),

            _buildStatsRow(),
            const SizedBox(height: 20),

            _buildEligibilityCard(),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DonorProfileScreen(
                      userData: DemoUser(
                        name: dummyUserData.name,
                        email: 'usman4009797@gmail.com',
                        bloodGroup: dummyUserData.bloodGroup,
                        phoneNumber: '03044009797',
                        location: 'Vehari',
                      ),
                    ),
                  ),
                );
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
    );
  }

  // 🔵 HEADER CARD
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 36, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dummyUserData.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Blood Group: ${dummyUserData.bloodGroup}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔵 STATS ROW
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          title: 'Donations',
          value: '0',
          icon: Icons.bloodtype,
          color: AppColors.primaryRed,
        ),
        const SizedBox(width: 15),
        _buildStatCard(
          title: 'Points',
          value: dummyUserData.rewardPoints.toString(),
          icon: Icons.stars,
          color: AppColors.warning,
        ),
      ],
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
            Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // 🔵 ELIGIBILITY CARD
  Widget _buildEligibilityCard() {
    final isEligible = dummyUserData.isEligible;

    return Container(
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
    );
  }

  // 🔵 ACTION TILE
  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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

/// DUMMY USER
class _DummyUser {
  final String name;
  final String bloodGroup;
  final int rewardPoints;
  final bool isEligible;

  _DummyUser({
    required this.name,
    required this.bloodGroup,
    required this.rewardPoints,
    required this.isEligible,
  });
}

/// DUMMY REWARDS SCREEN
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: const Center(child: Text('Rewards Screen (Demo)')),
    );
  }
}
