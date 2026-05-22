import 'package:flutter/material.dart';
import '../../../models/donation_model.dart';
import '../../../utils/date_utils.dart';

class DonationHistoryTile extends StatelessWidget {
  final DonationModel donation;

  const DonationHistoryTile({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Text(donation.bloodGroup,
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        title: Text(donation.location,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppDateUtils.formatDate(donation.donationDate)),
        trailing: Chip(
          label: Text('+${donation.pointsEarned} pts',
              style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.red.shade50,
        ),
      ),
    );
  }
}