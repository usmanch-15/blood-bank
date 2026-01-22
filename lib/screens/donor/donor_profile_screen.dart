import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
// import '../../models/user_model.dart';        // 🔴 Firebase model commented
// import '../../services/auth_service.dart';  // 🔴 Firebase service commented
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

/// 🔹 Dummy User Model (Firebase OFF mode)
class DemoUser {
  final String name;
  final String email;
  final String bloodGroup;
  final String? phoneNumber;
  final String? location;
  final String? profileImageUrl;

  DemoUser({
    required this.name,
    required this.email,
    required this.bloodGroup,
    this.phoneNumber,
    this.location,
    this.profileImageUrl,
  });
}

/// Donor Profile Screen - View and edit donor profile (Demo)
class DonorProfileScreen extends StatefulWidget {
  final DemoUser userData;

  const DonorProfileScreen({super.key, required this.userData});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData.name;
    _phoneController.text = widget.userData.phoneNumber ?? '';
    _locationController.text = widget.userData.location ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// 🔹 Demo Save (Firebase removed)
  void _handleSave() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated (Demo Mode)'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        width: 3,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryRed.withOpacity(0.1),
                          AppColors.primaryRed.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.transparent,
                      backgroundImage: widget.userData.profileImageUrl != null
                          ? NetworkImage(widget.userData.profileImageUrl!)
                          : null,
                      child: widget.userData.profileImageUrl == null
                          ? const Icon(
                        Icons.person_rounded,
                        size: 70,
                        color: AppColors.primaryRed,
                      )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Handle photo upload
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo upload (Demo Mode)'),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Blood Group Badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Blood Group: ${widget.userData.bloodGroup}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form Fields Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Name Field
                    Container(
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? Colors.grey[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        prefixIcon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Enter name' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field (Disabled)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomTextField(
                        controller:
                        TextEditingController(text: widget.userData.email),
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    Container(
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? Colors.grey[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Field
                    Container(
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? Colors.grey[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomTextField(
                        controller: _locationController,
                        label: 'Location',
                        prefixIcon: Icons.location_on_outlined,
                        enabled: _isEditing,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Save Button (only when editing)
              if (_isEditing)
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _isLoading ? null : _handleSave,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.primaryRed,
                  height: 56,
                  borderRadius: 12,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  loadingColor: Colors.white,
                ),

              // Cancel Button (only when editing)
              if (_isEditing) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      // Reset fields to original values
                      _nameController.text = widget.userData.name;
                      _phoneController.text = widget.userData.phoneNumber ?? '';
                      _locationController.text = widget.userData.location ?? '';
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}