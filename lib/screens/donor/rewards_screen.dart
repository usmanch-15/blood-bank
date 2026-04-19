import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../models/reward_model.dart';

/// Rewards & Certificates Screen
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late FirestoreService _firestoreService;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rewards & Certificates'),
          backgroundColor: AppColors.primaryRed,
        ),
        body: const Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Certificates'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<RewardModel?>(
        future: _firestoreService.getRewards(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rewards = snapshot.data;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points Summary Card
                  _buildPointsSummaryCard(
                    totalPoints: rewards?.totalPoints ?? 0,
                    tier: rewards?.tier ?? 'bronze',
                  ),
                  const SizedBox(height: 24),

                  // Tier Progress
                  const Text(
                    'Tier Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTierProgressCard(rewards?.totalPoints ?? 0),
                  const SizedBox(height: 24),

                  // Certificates Section
                  const Text(
                    'Certificates Earned',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (rewards?.certificates.isEmpty ?? true)
                    _buildEmptyCertificatesCard()
                  else
                    ..._buildCertificatesList(rewards!.certificates),
                  const SizedBox(height: 24),

                  // Reward Conversion
                  const Text(
                    'Convert Points',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildConversionOptions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build points summary card
  Widget _buildPointsSummaryCard({
    required int totalPoints,
    required String tier,
  }) {
    final tierColor = _getTierColor(tier);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor.withOpacity(0.8), tierColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Points',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tier.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalPoints.toString(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getTierDescription(tier),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build tier progress card
  Widget _buildTierProgressCard(int currentPoints) {
    const tiers = {
      'bronze': 0,
      'silver': 1000,
      'gold': 3000,
      'platinum': 5000,
    };

    return Column(
      children: [
        _buildTierProgress('Bronze', 0, 1000, currentPoints,
            currentPoints >= 0 && currentPoints < 1000),
        const SizedBox(height: 12),
        _buildTierProgress('Silver', 1000, 3000, currentPoints,
            currentPoints >= 1000 && currentPoints < 3000),
        const SizedBox(height: 12),
        _buildTierProgress('Gold', 3000, 5000, currentPoints,
            currentPoints >= 3000 && currentPoints < 5000),
        const SizedBox(height: 12),
        _buildTierProgress('Platinum', 5000, 9999, currentPoints,
            currentPoints >= 5000),
      ],
    );
  }

  /// Build individual tier progress
  Widget _buildTierProgress(
    String tierName,
    int min,
    int max,
    int current,
    bool isActive,
  ) {
    double progress = ((current - min) / (max - min)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? AppColors.primaryRed : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tierName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primaryRed : AppColors.textSecondary,
                ),
              ),
              Text(
                '$min - $max points',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isActive ? progress : 0,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                isActive ? AppColors.primaryRed : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty certificates card
  Widget _buildEmptyCertificatesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Certificates Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Earn certificates by completing donations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Build certificates list
  List<Widget> _buildCertificatesList(List<Certificate> certificates) {
    return certificates.map((cert) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildCertificateCard(cert),
    )).toList();
  }

  /// Build individual certificate card
  Widget _buildCertificateCard(Certificate cert) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.primaryRed,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cert.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issued: ${cert.issuedDate.toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _downloadCertificate(cert),
                    child: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                    ),
                    onPressed: () => _shareCertificate(cert),
                    child: const Text(
                      'Share',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build conversion options
  Widget _buildConversionOptions() {
    return Column(
      children: [
        _buildConversionOption(
          icon: Icons.card_giftcard,
          title: '500 Points',
          subtitle: 'Blood Bank Voucher',
          points: 500,
        ),
        const SizedBox(height: 12),
        _buildConversionOption(
          icon: Icons.medical_services,
          title: '1000 Points',
          subtitle: 'Health Checkup Package',
          points: 1000,
        ),
        const SizedBox(height: 12),
        _buildConversionOption(
          icon: Icons.fastfood,
          title: '250 Points',
          subtitle: 'Nutrition Package',
          points: 250,
        ),
      ],
    );
  }

  /// Build conversion option
  Widget _buildConversionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversion initiated')),
              );
            },
            child: const Text(
              'Redeem',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Download certificate
  void _downloadCertificate(Certificate cert) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate downloading...')),
    );
  }

  /// Share certificate
  void _shareCertificate(Certificate cert) {
    Share.share(
      'I earned ${cert.title} certificate on Blood Bank! 🩸\n\n${cert.description}',
      subject: 'Blood Bank Certificate - ${cert.title}',
    );
  }

  /// Get tier color
  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return AppColors.primaryRed;
    }
  }

  /// Get tier description
  String _getTierDescription(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return '0 - 1000 points: Welcome donor';
      case 'silver':
        return '1000 - 3000 points: Regular donor';
      case 'gold':
        return '3000 - 5000 points: Premium donor';
      case 'platinum':
        return '5000+ points: Elite donor';
      default:
        return '';
    }
  }
}
