import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'donor/donor_dashboard_screen.dart';
import 'receiver/receiver_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _selectedRole;

  Future<void> _handleRoleSelection(String role) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedRole = role;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      User? user = _authService.currentUser;

      if (user != null) {
        await _authService.updateUserData(user.uid, {'role': role});
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'donor'
              ? const DonorDashboardScreen()
              : const ReceiverDashboardScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Simple
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    'Choose Your Role',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Simple Subtitle
                  Text(
                    'Select how you want to use the app',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Center Content - Just 2 Buttons
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Donor Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        child: _buildRoleButton(
                          title: 'Donor',
                          subtitle: 'I want to donate blood',
                          icon: Icons.bloodtype,
                          color: AppColors.primaryRed,
                          isLoading: _isLoading && _selectedRole == 'donor',
                          onTap: () => _handleRoleSelection('donor'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Receiver Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        child: _buildRoleButton(
                          title: 'Receiver',
                          subtitle: 'I need to find blood',
                          icon: Icons.local_hospital,
                          color: AppColors.primaryDarkRed,
                          isLoading: _isLoading && _selectedRole == 'receiver',
                          onTap: () => _handleRoleSelection('receiver'),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Simple Help Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'You can change your role later from settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),

              const SizedBox(width: 20),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow or Loading
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}