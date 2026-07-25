import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

/// ✅ PHASE 3 — Donor Level Card
/// Drop this into donor_dashboard_screen.dart or a profile screen. Pass
/// the donor's actual donationCount from their Firestore document.
class DonorLevelCard extends StatelessWidget {
  final int donationCount;
  final List<String> badges;

  const DonorLevelCard({
    super.key,
    required this.donationCount,
    this.badges = const [],
  });

  @override
  Widget build(BuildContext context) {
    final level = GamificationService.levelForDonationCount(donationCount);
    final icon = GamificationService.iconForLevel(level);
    final toNext = GamificationService.donationsToNextLevel(donationCount);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('$donationCount donations'),
                  ],
                ),
              ],
            ),
            if (toNext != null) ...[
              const SizedBox(height: 8),
              Text(
                '$toNext more donation${toNext == 1 ? '' : 's'} to level up!',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges
                    .map((b) => Chip(
                  label: Text(
                    GamificationService.badgeLabel(b),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.red.shade50,
                ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}