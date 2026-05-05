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

    try {
      User? user = _authService.currentUser;

      if (user != null) {
        await _authService.updateUserData(
          user.uid,
          {'role': role},
        );
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'donor'
              ? const DonorDashboardScreen()
              : const ReceiverDashboardScreen(),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F9FC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Top Icon
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 45,
                    color: AppColors.primaryRed,
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Select how you want to use the Blood Donation App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 50),

                // Donor Card
                _buildRoleCard(
                  title: 'Donor',
                  subtitle: 'Donate blood and help save lives',
                  icon: Icons.volunteer_activism,
                  color: AppColors.primaryRed,
                  isLoading: _isLoading && _selectedRole == 'donor',
                  onTap: () => _handleRoleSelection('donor'),
                ),

                const SizedBox(height: 25),

                // Receiver Card
                _buildRoleCard(
                  title: 'Receiver',
                  subtitle: 'Find blood donors near you',
                  icon: Icons.local_hospital,
                  color: AppColors.secondaryBlue,
                  isLoading: _isLoading && _selectedRole == 'receiver',
                  onTap: () => _handleRoleSelection('receiver'),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Text(
                    'You can change your role later from settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: color,
                size: 36,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            isLoading
                ? SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            )
                : Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}