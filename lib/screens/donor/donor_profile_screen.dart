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
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                    backgroundImage: widget.userData.profileImageUrl != null
                        ? NetworkImage(widget.userData.profileImageUrl!)
                        : null,
                    child: widget.userData.profileImageUrl == null
                        ? const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primaryRed,
                    )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryRed,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // Blood Group
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Blood Group: ${widget.userData.bloodGroup}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person,
                enabled: _isEditing,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller:
                TextEditingController(text: widget.userData.email),
                label: 'Email',
                prefixIcon: Icons.email,
                enabled: false,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                enabled: _isEditing,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _locationController,
                label: 'Location',
                prefixIcon: Icons.location_on,
                enabled: _isEditing,
              ),
              const SizedBox(height: 30),

              if (_isEditing)
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _isLoading ? null : _handleSave,
                  isLoading: _isLoading,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
