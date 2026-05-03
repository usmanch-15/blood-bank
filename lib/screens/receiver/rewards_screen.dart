import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reward_model.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🔧 Dummy data (replace with Firestore in production)
  final RewardModel _rewardData = RewardModel(
    id: 'reward001',
    donorId: 'user123',
    totalPoints: 1250,
    tier: 'silver',
    lastUpdated: DateTime.now(),
    certificates: [
      Certificate(
        id: 'cert001',
        title: 'First Donation Hero',
        description: 'Awarded for completing your very first blood donation.',
        issuedDate: DateTime(2024, 3, 10),
        criteria: '1 donation',
      ),
      Certificate(
        id: 'cert002',
        title: 'Silver Donor',
        description: 'You have earned 1000+ reward points. Thank you!',
        issuedDate: DateTime(2024, 8, 22),
        criteria: '1000 points',
      ),
      Certificate(
        id: 'cert003',
        title: 'Life Saver',
        description: 'Donated blood during an emergency SOS request.',
        issuedDate: DateTime(2025, 1, 5),
        criteria: 'Emergency donation',
      ),
    ],
  );

  final List<Map<String, dynamic>> _pointHistory = [
    {
      'action': 'Blood Donation',
      'points': 200,
      'date': DateTime(2025, 1, 5),
      'type': 'earn',
    },
    {
      'action': 'Emergency SOS Response',
      'points': 150,
      'date': DateTime(2024, 11, 18),
      'type': 'earn',
    },
    {
      'action': 'Profile Completion Bonus',
      'points': 50,
      'date': DateTime(2024, 10, 1),
      'type': 'earn',
    },
    {
      'action': 'Blood Donation',
      'points': 200,
      'date': DateTime(2024, 8, 22),
      'type': 'earn',
    },
    {
      'action': 'Referral Bonus',
      'points': 100,
      'date': DateTime(2024, 6, 14),
      'type': 'earn',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'platinum':
        return const Color(0xFF6A0DAD);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFFCD7F32); // bronze
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'platinum':
        return Icons.workspace_premium;
      case 'gold':
        return Icons.emoji_events;
      case 'silver':
        return Icons.military_tech;
      default:
        return Icons.grade;
    }
  }

  int _getNextTierPoints(String tier) {
    switch (tier) {
      case 'bronze':
        return 1000;
      case 'silver':
        return 3000;
      case 'gold':
        return 5000;
      default:
        return 5000;
    }
  }

  String _getNextTierName(String tier) {
    switch (tier) {
      case 'bronze':
        return 'Silver';
      case 'silver':
        return 'Gold';
      case 'gold':
        return 'Platinum';
      default:
        return 'Max Tier';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rewards & Certificates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.stars), text: 'My Points'),
            Tab(icon: Icon(Icons.card_membership), text: 'Certificates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPointsTab(),
          _buildCertificatesTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: Points & Tier
  // ─────────────────────────────────────────────
  Widget _buildPointsTab() {
    final tier = _rewardData.tier;
    final points = _rewardData.totalPoints;
    final nextTierPoints = _getNextTierPoints(tier);
    final progress = (points / nextTierPoints).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tier Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTierColor(tier),
                  _getTierColor(tier).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  _getTierIcon(tier),
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  tier.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Donor Tier',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Text(
                  '$points pts',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress to next tier
                if (tier != 'platinum') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to ${_getNextTierName(tier)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '$points / $nextTierPoints',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white30,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ] else
                  const Text(
                    'You have reached the highest tier!',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tier info cards
          Row(
            children: [
              _buildTierInfoCard('Bronze', '0+', const Color(0xFFCD7F32)),
              const SizedBox(width: 10),
              _buildTierInfoCard('Silver', '1000+', const Color(0xFF9E9E9E)),
              const SizedBox(width: 10),
              _buildTierInfoCard('Gold', '3000+', const Color(0xFFFFD700)),
              const SizedBox(width: 10),
              _buildTierInfoCard(
                  'Platinum', '5000+', const Color(0xFF6A0DAD)),
            ],
          ),

          const SizedBox(height: 28),

          // Points history
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Points History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          ..._pointHistory.map((entry) => _buildHistoryTile(entry)),
        ],
      ),
    );
  }

  Widget _buildTierInfoCard(String name, String pts, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(Icons.circle, color: color, size: 14),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color),
              textAlign: TextAlign.center,
            ),
            Text(
              pts,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> entry) {
    final isEarn = entry['type'] == 'earn';
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEarn
              ? AppColors.success.withOpacity(0.15)
              : AppColors.error.withOpacity(0.15),
          child: Icon(
            isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isEarn ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(entry['action'],
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${entry['date'].day}/${entry['date'].month}/${entry['date'].year}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          '${isEarn ? '+' : '-'}${entry['points']} pts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isEarn ? AppColors.success : AppColors.error,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2: Certificates
  // ─────────────────────────────────────────────
  Widget _buildCertificatesTab() {
    final certs = _rewardData.certificates;

    if (certs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No certificates yet',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Donate blood to earn your first certificate!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      itemBuilder: (context, index) {
        return _buildCertificateCard(certs[index]);
      },
    );
  }

  Widget _buildCertificateCard(Certificate cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Certificate of Achievement',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        cert.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildCertDetail(
                      Icons.flag_outlined,
                      'Criteria',
                      cert.criteria,
                    ),
                    const SizedBox(width: 20),
                    _buildCertDetail(
                      Icons.calendar_today_outlined,
                      'Issued',
                      '${cert.issuedDate.day}/${cert.issuedDate.month}/${cert.issuedDate.year}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Certificate download coming soon!'),
                          backgroundColor: AppColors.primaryRed,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download Certificate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
