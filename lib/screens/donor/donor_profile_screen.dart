import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/storage_service.dart';
import '../auth/otp_verification_screen.dart';

/// ✅ REDESIGNED — the old "view" mode simply rendered every field as a
/// *disabled* CustomTextField (grey box, faint border, no real hierarchy),
/// which is what made the screen look unfinished/unprofessional. Read-only
/// mode now renders clean labeled info rows inside a card (the pattern used
/// by every polished profile screen — Settings apps, banking apps, etc),
/// and the actual TextFormFields only appear once the user taps "Edit".
/// Also adds CNIC (view + edit), stored the same secure way as phone number
/// (users/{uid}/private/contact — never on the public user doc).
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
  final _cnicController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _loadingPrivate = true;

  final StorageService _storageService = StorageService();
  String? _uploadedImageUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? '';
    _locationController.text = widget.userData['location'] ?? '';
    _loadOwnPrivateInfo();
  }

  Future<void> _loadOwnPrivateInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('contact')
          .get();
      if (mounted && doc.exists) {
        setState(() {
          _phoneController.text = doc.data()?['phoneNumber'] ?? '';
          _cnicController.text = doc.data()?['cnic'] ?? '';
        });
      }
    } catch (_) {
      // No private/contact doc yet — leave fields blank.
    } finally {
      if (mounted) setState(() => _loadingPrivate = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
          const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: AppColors.success),
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef.update({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
      });

      await userRef.collection('private').doc('contact').set({
        'phoneNumber': _phoneController.text.trim(),
        'cnic': _cnicController.text.trim(),
      }, SetOptions(merge: true));

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
    final profileImageUrl =
        _uploadedImageUrl ?? widget.userData['profileImageUrl'];
    final phoneVerified = widget.userData['phoneVerified'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = widget.userData['name'] ?? '';
                  _locationController.text =
                      widget.userData['location'] ?? '';
                });
                _loadOwnPrivateInfo();
              },
              child:
              const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ── Header banner with avatar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                  AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxxl),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusXl)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 53,
                          backgroundColor: Colors.white,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              fontSize: 40,
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
                            onTap:
                            _uploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryRed, width: 2),
                              ),
                              child: _uploadingPhoto
                                  ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryRed),
                              )
                                  : const Icon(Icons.camera_alt_rounded,
                                  color: AppColors.primaryRed, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Donor'
                        : _nameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.85)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Blood Group: $bloodGroup',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -AppSpacing.xxl),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Personal Info Card ──
                      _SectionCard(
                        title: 'Personal Information',
                        icon: Icons.badge_outlined,
                        child: _isEditing
                            ? _buildEditFields()
                            : _buildReadOnlyFields(email, phoneVerified),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      if (_isEditing)
                        CustomButton(
                          text: 'Save Changes',
                          onPressed: _isLoading ? null : _handleSave,
                          isLoading: _isLoading,
                          backgroundColor: AppColors.primaryRed,
                          height: 54,
                          borderRadius: 12,
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          loadingColor: Colors.white,
                        ),

                      const SizedBox(height: AppSpacing.xxl),
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

  // ── Read-only info rows (professional, non-disabled look) ──
  Widget _buildReadOnlyFields(String email, bool phoneVerified) {
    if (_loadingPrivate) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: AppColors.primaryRed),
          ),
        ),
      );
    }
    return Column(
      children: [
        _InfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Full Name',
          value: _nameController.text.isEmpty ? '—' : _nameController.text,
        ),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone Number',
          value: _phoneController.text.isEmpty
              ? 'Not added'
              : _phoneController.text,
          trailing: _VerifiedChip(verified: phoneVerified),
        ),
        if (!phoneVerified && _phoneController.text.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _verifyPhone,
              icon: const Icon(Icons.verified_user_outlined, size: 16),
              label: const Text('Verify Now'),
              style:
              TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
            ),
          ),
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'CNIC',
          value:
          _cnicController.text.isEmpty ? 'Not added' : _cnicController.text,
        ),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: _locationController.text.isEmpty
              ? 'Not added'
              : _locationController.text,
          isLast: true,
        ),
      ],
    );
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    final formatted = phone.startsWith('+')
        ? phone
        : '+92${phone.replaceFirst(RegExp(r'^0'), '')}';
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(phoneNumber: formatted),
      ),
    );
    if (verified == true && mounted) {
      setState(() => widget.userData['phoneVerified'] = true);
    }
  }

  // ── Editable form fields ──
  Widget _buildEditFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          prefixIcon: Icons.person_outline_rounded,
          enabled: true,
          validator: AppValidators.validateName,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller:
          TextEditingController(text: widget.userData['email'] ?? ''),
          label: 'Email',
          prefixIcon: Icons.email_outlined,
          enabled: false,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          enabled: true,
          keyboardType: TextInputType.phone,
          validator: AppValidators.validatePhone,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _cnicController,
          label: 'CNIC (National ID)',
          hint: '12345-1234567-1',
          prefixIcon: Icons.badge_outlined,
          enabled: true,
          keyboardType: TextInputType.number,
          validator: AppValidators.validateCnic,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _locationController,
          label: 'Location',
          prefixIcon: Icons.location_on_outlined,
          enabled: true,
        ),
      ],
    );
  }
}

// ── Reusable section card wrapper ──────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryRed),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ── Read-only info row ───────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryRed),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Verified / not-verified chip ─────────────────────────────────
class _VerifiedChip extends StatelessWidget {
  final bool verified;
  const _VerifiedChip({required this.verified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (verified ? AppColors.success : AppColors.warning)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.error_outline,
            size: 13,
            color: verified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'Verified' : 'Unverified',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: verified ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}