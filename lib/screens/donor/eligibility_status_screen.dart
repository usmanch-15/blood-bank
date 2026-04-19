import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../utils/eligibility_checker.dart';
import '../../models/user_model.dart';

/// Donor Eligibility Status Screen
class EligibilityStatusScreen extends StatefulWidget {
  const EligibilityStatusScreen({super.key});

  @override
  State<EligibilityStatusScreen> createState() =>
      _EligibilityStatusScreenState();
}

class _EligibilityStatusScreenState extends State<EligibilityStatusScreen> {
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
          title: const Text('Eligibility Status'),
          backgroundColor: AppColors.primaryRed,
        ),
        body: const Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eligibility Status'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.getUser(user!.uid).asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Unable to load user data'));
          }

          final userModel = snapshot.data!;
          final isEligible =
              EligibilityChecker.isEligibleForDonation(userModel.lastDonationDate);
          final daysLeft =
              EligibilityChecker.daysUntilEligible(userModel.lastDonationDate);
          final message =
              EligibilityChecker.getEligibilityMessage(userModel.lastDonationDate);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    color: isEligible
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: isEligible
                                  ? AppColors.success
                                  : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isEligible ? Icons.check : Icons.schedule,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isEligible ? 'Eligible to Donate' : 'Not Eligible Yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isEligible
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Last Donation Info
                  const Text(
                    'Donation Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Last Donation Card
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Last Donation',
                    value: userModel.lastDonationDate != null
                        ? DateFormat('MMM dd, yyyy')
                            .format(userModel.lastDonationDate!)
                        : 'Never',
                  ),
                  const SizedBox(height: 12),

                  // Next Eligible Date
                  _buildInfoCard(
                    icon: Icons.check_circle,
                    title: 'Next Eligible Date',
                    value: userModel.lastDonationDate != null
                        ? DateFormat('MMM dd, yyyy').format(
                            userModel.lastDonationDate!.add(
                              const Duration(days: 90),
                            ),
                          )
                        : 'Now',
                  ),
                  const SizedBox(height: 12),

                  // Days Remaining / Completed
                  if (!isEligible && daysLeft != null && daysLeft > 0)
                    _buildInfoCard(
                      icon: Icons.hourglass_bottom,
                      title: 'Days to Wait',
                      value: '$daysLeft days',
                      valueColor: AppColors.warning,
                    ),
                  if (isEligible)
                    _buildInfoCard(
                      icon: Icons.thumb_up,
                      title: 'Status',
                      value: 'Ready to Donate',
                      valueColor: AppColors.success,
                    ),

                  const SizedBox(height: 32),

                  // Eligibility Criteria
                  const Text(
                    'Eligibility Criteria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCriteriaItem(
                    'Minimum interval: 90 days between donations',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildCriteriaItem(
                    'Age: 18 - 65 years',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildCriteriaItem(
                    'Weight: At least 50 kg',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildCriteriaItem(
                    'Good overall health',
                    true,
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  if (isEligible)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proceed to schedule donation'),
                            ),
                          );
                        },
                        child: const Text(
                          'Schedule Donation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build info card
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build criteria item
  Widget _buildCriteriaItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? AppColors.success : AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              decoration: isMet ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }
}
