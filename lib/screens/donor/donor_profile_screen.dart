import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart'; // ✅ light-touch polish
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/storage_service.dart';
import '../auth/otp_verification_screen.dart';

class DonorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

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

  final StorageService _storageService = StorageService();
  String? _uploadedImageUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Firebase se aaya real data fields mein daal do
    _nameController.text = widget.userData['name'] ?? '';
    _phoneController.text = widget.userData['phoneNumber'] ?? '';
    _locationController.text = widget.userData['location'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storageService.uploadProfileImage(
        file: File(picked.path),
        userId: uid,
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': url,
      });
      setState(() {
        _uploadedImageUrl = url;
        _uploadingPhoto = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload photo: $e')),
        );
      }
    }
  }

  // ✅ Firebase mein save karo
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
      });

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData['email'] ?? '';
    final bloodGroup = widget.userData['bloodGroup'] ?? '—';
    final profileImageUrl = _uploadedImageUrl ?? widget.userData['profileImageUrl'];

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
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Profile Picture ──
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
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: _uploadingPhoto
                              ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                              : const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Blood Group Badge ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop_rounded,
                        color: AppColors.primaryRed, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Blood Group: $bloodGroup',
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

              // ── Form Fields ──
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
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline_rounded,
                      enabled: _isEditing,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      controller: TextEditingController(text: email),
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // ✅ NEW: Phone verification badge — pehle ye feature
                    // README mein claim ki gayi thi lekin kahin implement
                    // nahi thi.
                    Row(
                      children: [
                        Icon(
                          (widget.userData['phoneVerified'] ?? false)
                              ? Icons.verified
                              : Icons.error_outline,
                          size: 16,
                          color: (widget.userData['phoneVerified'] ?? false)
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm - 2),
                        Text(
                          (widget.userData['phoneVerified'] ?? false)
                              ? 'Phone Verified'
                              : 'Phone Not Verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: (widget.userData['phoneVerified'] ?? false)
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const Spacer(),
                        if (!(widget.userData['phoneVerified'] ?? false) &&
                            _phoneController.text.trim().isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              final phone = _phoneController.text.trim();
                              final formatted = phone.startsWith('+')
                                  ? phone
                                  : '+92${phone.replaceFirst(RegExp(r'^0'), '')}';
                              final verified = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OtpVerificationScreen(
                                      phoneNumber: formatted),
                                ),
                              );
                              if (verified == true && mounted) {
                                setState(() {
                                  widget.userData['phoneVerified'] = true;
                                });
                              }
                            },
                            child: const Text('Verify Now'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Location',
                      prefixIcon: Icons.location_on_outlined,
                      enabled: _isEditing,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_isEditing) ...[
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
                  ),
                  loadingColor: Colors.white,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = widget.userData['name'] ?? '';
                      _phoneController.text = widget.userData['phoneNumber'] ?? '';
                      _locationController.text = widget.userData['location'] ?? '';
                    });
                  },
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}