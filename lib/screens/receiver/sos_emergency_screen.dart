import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/blood_request_model.dart';
import '../../widgets/custom_button.dart';

/// SOS Emergency Screen - Demo Version (No Scroll)
class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  String? _selectedBloodGroup;
  bool _isLoading = false;

  // Dummy user data
  final String userId = 'dummyUser123';
  final String userName = 'John Doe';
  final String userPhone = '03001234567';
  final String userLocation = 'Lahore';

  Future<void> _handleEmergencyRequest() async {
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a blood group'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = BloodRequestModel(
        id: 'emergency123',
        requesterId: userId,
        requesterName: userName,
        requesterPhone: userPhone,
        bloodGroup: _selectedBloodGroup!,
        quantity: 2,
        hospitalName: userLocation,
        location: userLocation,
        urgency: 'emergency',
        notes: 'SOS EMERGENCY REQUEST',
        createdAt: DateTime.now(),
      );

      if (mounted) {
        _showEmergencyAlert();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmergencyAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'EMERGENCY REQUEST SENT',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your emergency blood request has been sent successfully.\n\n'
              'Nearby donors have been notified (demo mode).',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.error.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        title: const Text(
          'SOS Emergency',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 🔴 Emergency Icon
            Center(
              child: Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 3),
                ),
                child: const Icon(
                  Icons.warning,
                  size: 50,
                  color: AppColors.error,
                ),
              ),
            ),

            /// 🔴 Title
            const Text(
              'EMERGENCY BLOOD REQUEST',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            /// ℹ️ Info Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: const Text(
                'Use this only for life-threatening emergencies.\n'
                    'Nearby donors will be notified immediately (demo).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 18),

            /// 🩸 Blood Group Title
            const Text(
              'Select Blood Group',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// 🩸 Blood Group Grid (Fits Screen)
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: AppConstants.bloodGroups.length,
                itemBuilder: (context, index) {
                  final group = AppConstants.bloodGroups[index];
                  final isSelected = _selectedBloodGroup == group;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedBloodGroup = group);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.error
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.error
                              : AppColors.textLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// 🔥 Emergency Button
            CustomButton(
              text: 'SEND EMERGENCY REQUEST',
              onPressed: _isLoading ? null : _handleEmergencyRequest,
              isLoading: _isLoading,
              backgroundColor: AppColors.error,
              height: 55,
            ),

            /// ❌ Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
