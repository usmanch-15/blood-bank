import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class DonorRewardsScreen extends StatefulWidget {
  const DonorRewardsScreen({super.key});

  @override
  State<DonorRewardsScreen> createState() => _DonorRewardsScreenState();
}

class _DonorRewardsScreenState extends State<DonorRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final int _totalPoints = 20;
  final int _donationsCount = 2;

  final List<_PointEntry> _pointHistory = [
    _PointEntry(
      description: 'First blood donation',
      points: 10,
      date: DateTime(2024, 4, 10),
      icon: Icons.bloodtype,
      isEarned: true,
    ),
    _PointEntry(
      description: 'Profile completed',
      points: 5,
      date: DateTime(2024, 4, 5),
      icon: Icons.person_add,
      isEarned: true,
    ),
    _PointEntry(
      description: 'Referred a donor',
      points: 5,
      date: DateTime(2024, 3, 28),
      icon: Icons.share,
      isEarned: true,
    ),
  ];

  final List<_Achievement> _achievements = [
    _Achievement(
      title: 'First Drop',
      description: 'Completed your first donation',
      icon: Icons.bloodtype,
      isUnlocked: true,
    ),
    _Achievement(
      title: 'Life Saver',
      description: 'Save 3 lives with donations',
      icon: Icons.favorite,
      isUnlocked: false,
      progress: 1,
      total: 3,
    ),
    _Achievement(
      title: 'Regular Hero',
      description: 'Donate 5 times',
      icon: Icons.emoji_events,
      isUnlocked: false,
      progress: 2,
      total: 5,
    ),
    _Achievement(
      title: 'Community Champion',
      description: 'Refer 5 donors',
      icon: Icons.people,
      isUnlocked: false,
      progress: 1,
      total: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        title: Text(
          'Rewards & Certificates',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHistoryTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPointsCard(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildCertificateCard(),
          const SizedBox(height: 20),
          _buildRedeemSection(),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 48),
          const SizedBox(height: 12),
          Text(
            '$_totalPoints',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'Reward Points',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Silver Donor',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Donations', '$_donationsCount', Icons.bloodtype,
            AppColors.primaryRed),
        const SizedBox(width: 12),
        _statCard('Lives Saved', '${_donationsCount * 3}', Icons.favorite,
            AppColors.success),
        const SizedBox(width: 12),
        _statCard('Rank', '#42', Icons.leaderboard, AppColors.warning),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium,
                color: Colors.amber.shade700, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donation Certificate',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Download your official certificate',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showSnack('Certificate download coming soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Download',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemSection() {
    final rewards = [
      {'label': 'Coffee Voucher', 'points': 10, 'icon': Icons.coffee},
      {'label': 'Health Check-up', 'points': 15, 'icon': Icons.health_and_safety},
      {'label': 'T-Shirt', 'points': 25, 'icon': Icons.checkroom},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redeem Points',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...rewards.map(
          (r) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                child: Icon(r['icon'] as IconData,
                    color: AppColors.primaryRed),
              ),
              title: Text(r['label'] as String,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${r['points']} points',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
              trailing: TextButton(
                onPressed: _totalPoints >= (r['points'] as int)
                    ? () => _showSnack('Redeemed: ${r['label']}')
                    : null,
                child: Text(
                  'Redeem',
                  style: GoogleFonts.poppins(
                    color: _totalPoints >= (r['points'] as int)
                        ? AppColors.primaryRed
                        : AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pointHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final entry = _pointHistory[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: entry.isEarned
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                child: Icon(
                  entry.icon,
                  color: entry.isEarned ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.isEarned ? '+' : '-'}${entry.points} pts',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: entry.isEarned ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _achievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final a = _achievements[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: a.isUnlocked
                ? Border.all(color: Colors.amber.shade300)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: a.isUnlocked
                      ? Colors.amber.shade50
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  a.icon,
                  color: a.isUnlocked ? Colors.amber.shade700 : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          a.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: a.isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (a.isUnlocked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: Colors.amber, size: 18),
                        ],
                      ],
                    ),
                    Text(
                      a.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!a.isUnlocked && a.total != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: a.progress! / a.total!,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.primaryRed,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${a.progress}/${a.total} completed',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PointEntry {
  final String description;
  final int points;
  final DateTime date;
  final IconData icon;
  final bool isEarned;

  const _PointEntry({
    required this.description,
    required this.points,
    required this.date,
    required this.icon,
    required this.isEarned,
  });
}

class _Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final int? progress;
  final int? total;

  const _Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.progress,
    this.total,
  });
}
