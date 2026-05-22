import 'package:flutter/material.dart';

import '../../../utils/date_utils.dart';

class EligibilityCard extends StatelessWidget {
  final DateTime? lastDonationDate;
  final bool isEligible;

  const EligibilityCard({
    super.key,
    required this.lastDonationDate,
    required this.isEligible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEligible ? Colors.green.shade600 : Colors.orange.shade600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isEligible ? Icons.check_circle : Icons.timer,
              color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            isEligible ? 'Ready to Donate!' : 'Not Eligible Yet',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (!isEligible && lastDonationDate != null)
            Text(
              '${AppDateUtils.daysRemaining(lastDonationDate!)} days remaining',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          if (isEligible)
            const Text('You can donate blood today!',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}