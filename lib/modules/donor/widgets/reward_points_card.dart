import 'package:flutter/material.dart';

class RewardPointsCard extends StatelessWidget {
  final int points;
  final String tier;

  const RewardPointsCard({
    super.key,
    required this.points,
    this.tier = 'bronze',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFe53935), Color(0xFFb71c1c)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star, color: Colors.yellow, size: 24),
            const SizedBox(width: 8),
            const Text('Reward Points',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            const Spacer(),
            Chip(
              label: Text(tier.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.white24,
            )
          ]),
          const SizedBox(height: 8),
          Text('$points pts',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}