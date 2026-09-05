import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/reward_controller.dart';
import '../../models/reward_model.dart';
import '../../constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<RewardController>().loadReward(uid);
      }
    });
  }

  // Tier config: color, icon, label, min points
  static const _tiers = {
    'bronze': _TierConfig(
      label: 'Bronze',
      icon: Icons.military_tech,
      color: Color(0xFFCD7F32),
      minPoints: 0,
      nextPoints: 1000,
    ),
    'silver': _TierConfig(
      label: 'Silver',
      icon: Icons.military_tech,
      color: Color(0xFF9E9E9E),
      minPoints: 1000,
      nextPoints: 3000,
    ),
    'gold': _TierConfig(
      label: 'Gold',
      icon: Icons.military_tech,
      color: Color(0xFFFFD700),
      minPoints: 3000,
      nextPoints: 5000,
    ),
    'platinum': _TierConfig(
      label: 'Platinum',
      icon: Icons.workspace_premium,
      color: Color(0xFF00BCD4),
      minPoints: 5000,
      nextPoints: 5000,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Rewards',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<RewardController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          final reward = controller.reward;
          final points = controller.totalPoints;
          final tier = controller.tier;
          final config = _tiers[tier] ?? _tiers['bronze']!;

          return RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) await controller.loadReward(uid);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Points & Tier Card ──
                _PointsCard(
                  points: points,
                  tier: tier,
                  config: config,
                ),
                const SizedBox(height: 16),

                // ── Tier Progress ──
                _TierProgressCard(
                  points: points,
                  tier: tier,
                  config: config,
                ),
                const SizedBox(height: 16),

                // ── How to Earn ──
                _HowToEarnCard(),
                const SizedBox(height: 16),

                // ── Certificates ──
                if (reward != null && reward.certificates.isNotEmpty) ...[
                  Text(
                    'My Certificates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...reward.certificates.map(
                        (cert) => _CertificateCard(certificate: cert),
                  ),
                ] else ...[
                  _EmptyCertificates(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Points Card ──────────────────────────────────────────────
class _PointsCard extends StatelessWidget {
  final int points;
  final String tier;
  final _TierConfig config;

  const _PointsCard({
    required this.points,
    required this.tier,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Total Points',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(config.icon, color: config.color, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      config.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$points',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'pts',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── Tier Progress Card ────────────────────────────────────────
class _TierProgressCard extends StatelessWidget {
  final int points;
  final String tier;
  final _TierConfig config;

  const _TierProgressCard({
    required this.points,
    required this.tier,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final isPlatinum = tier == 'platinum';
    final progress = isPlatinum
        ? 1.0
        : ((points - config.minPoints) /
        (config.nextPoints - config.minPoints))
        .clamp(0.0, 1.0);
    final remaining = isPlatinum ? 0 : config.nextPoints - points;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tier Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tier steps row — connecting line + circular badges instead of
          // bare icons, so it reads as a proper progress stepper.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['bronze', 'silver', 'gold', 'platinum'].map((t) {
              final tc = _RewardsScreen._tiers[t]!;
              final isActive = _tierIndex(tier) >= _tierIndex(t);
              final isCurrent = tier == t;
              return Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? tc.color.withOpacity(0.15)
                          : Colors.grey[100],
                      border: Border.all(
                        color: isCurrent
                            ? tc.color
                            : (isActive ? tc.color.withOpacity(0.4) : Colors.grey[300]!),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      tc.icon,
                      color: isActive ? tc.color : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tc.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? tc.color : Colors.grey[400],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(config.color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                isPlatinum
                    ? 'You have reached the highest tier!'
                    : '$remaining more points to ${_nextTierLabel(tier)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _tierIndex(String t) {
    const order = ['bronze', 'silver', 'gold', 'platinum'];
    return order.indexOf(t);
  }

  String _nextTierLabel(String t) {
    const next = {
      'bronze': 'Silver',
      'silver': 'Gold',
      'gold': 'Platinum',
      'platinum': 'Platinum',
    };
    return next[t] ?? '';
  }
}

// ── How to Earn Card ──────────────────────────────────────────
class _HowToEarnCard extends StatelessWidget {
  final _perks = const [
    _Perk(icon: Icons.bloodtype, label: 'Donate Blood', points: '+50 pts'),
    _Perk(icon: Icons.check_circle, label: 'Complete Profile', points: '+20 pts'),
    _Perk(icon: Icons.campaign, label: 'Refer a Friend', points: '+30 pts'),
    _Perk(icon: Icons.event, label: 'Attend Blood Drive', points: '+25 pts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.primaryRed, size: 20),
              SizedBox(width: 8),
              Text(
                'How to Earn Points',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._perks.map(
                (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(p.icon,
                        color: AppColors.primaryRed, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p.label,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p.points,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Certificate Card ──────────────────────────────────────────
class _CertificateCard extends StatelessWidget {
  final Certificate certificate;

  const _CertificateCard({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  certificate.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(certificate.issuedDate),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          if (certificate.imageUrl != null)
            IconButton(
              icon: const Icon(Icons.download,
                  color: AppColors.primaryRed, size: 22),
              onPressed: () async {
                final url = Uri.parse(certificate.imageUrl!);
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open certificate.')),
                    );
                  }
                }
              },
              tooltip: 'Download Certificate',
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Empty Certificates ─────────────────────────────────────────
class _EmptyCertificates extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_membership,
                size: 34, color: AppColors.primaryRed.withOpacity(0.6)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No certificates yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Donate blood to earn your first certificate!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ── Helper structs ─────────────────────────────────────────────
class _TierConfig {
  final String label;
  final IconData icon;
  final Color color;
  final int minPoints;
  final int nextPoints;
  const _TierConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.minPoints,
    required this.nextPoints,
  });
}

class _Perk {
  final IconData icon;
  final String label;
  final String points;
  const _Perk({
    required this.icon,
    required this.label,
    required this.points,
  });
}

// Allow _PointsCard / _TierProgressCard to access _tiers map
// (moved to top-level for cleanliness in real project)
class _RewardsScreen {
  static const _tiers = _RewardsScreenState._tiers;
}