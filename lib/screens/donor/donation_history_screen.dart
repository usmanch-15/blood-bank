import 'package:flutter/material.dart';
<<<<<<< HEAD
// import 'package:firebase_auth/firebase_auth.dart'; // 🔴 Firebase Auth commented
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
// import '../../services/firestore_service.dart'; // 🔴 Firestore commented
import '../../models/donation_model.dart';

/// Donation History Screen - View all past donations
class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser; // 🔴 Firebase commented
    // final _firestoreService = FirestoreService();  // 🔴 Firebase commented

    /*
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }
    */
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../models/donation_model.dart';

/// Donation History Screen - View all past donations
class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
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
          title: const Text('Donation History'),
          backgroundColor: AppColors.primaryRed,
        ),
        body: const Center(
          child: Text('Please login to view donation history'),
        ),
      );
    }
>>>>>>> 6a6249e (first commit)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
<<<<<<< HEAD
      ),

      // 🔴 Firebase StreamBuilder commented
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            SizedBox(height: 20),
            Text(
              'Firebase disabled',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Donation history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),

      /*
      body: StreamBuilder<List<DonationModel>>(
        stream: _firestoreService.getDonationsByDonor(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final donations = snapshot.data ?? [];

          if (donations.isEmpty) {
=======
        elevation: 0,
      ),
      body: StreamBuilder<List<DonationModel>>(
        stream: _firestoreService.getDonationHistory(user!.uid),
        builder: (context, snapshot) {
          // Loading state with shimmer
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Error loading donation history'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (snapshot.data?.isEmpty ?? true) {
>>>>>>> 6a6249e (first commit)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bloodtype_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No donations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your donation history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

<<<<<<< HEAD
=======
          // List of donations
          final donations = snapshot.data ?? [];
>>>>>>> 6a6249e (first commit)
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _buildDonationCard(donation);
            },
          );
        },
      ),
<<<<<<< HEAD
      */
    );
  }

=======
    );
  }

  /// Build a single donation card
>>>>>>> 6a6249e (first commit)
  Widget _buildDonationCard(DonationModel donation) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bloodtype,
                color: AppColors.primaryRed,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(donation.donationDate),
                    style: const TextStyle(
<<<<<<< HEAD
                      fontSize: 18,
=======
                      fontSize: 16,
>>>>>>> 6a6249e (first commit)
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    donation.location,
                    style: const TextStyle(
<<<<<<< HEAD
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
=======
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
>>>>>>> 6a6249e (first commit)
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
<<<<<<< HEAD
                        Icons.stars,
                        size: 16,
=======
                        Icons.star,
                        size: 14,
>>>>>>> 6a6249e (first commit)
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 5),
                      Text(
<<<<<<< HEAD
                        '${donation.pointsEarned} points',
                        style: const TextStyle(
                          fontSize: 12,
=======
                        '${donation.pointsEarned} points earned',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
>>>>>>> 6a6249e (first commit)
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Blood Group Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                donation.bloodGroup,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
<<<<<<< HEAD
=======
                  fontSize: 14,
>>>>>>> 6a6249e (first commit)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
