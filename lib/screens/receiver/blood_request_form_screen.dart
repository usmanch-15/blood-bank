import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/blood_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/geo_location_service.dart';
import '../../services/notification_service.dart';
import '../../utils/location_helper.dart';
import '../../utils/validators.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';

/// ✅ UI POLISH ONLY — every piece of logic below (Firestore save, geo
/// location fetch, nearby-donor search + notify, validators) is byte-for-
/// byte unchanged from the previous version. Only the visual layer changed:
/// gradient header, sectioned form with dividers, colored blood-group/
/// urgency chip selectors instead of plain dropdowns, CustomTextField for
/// consistent styling.
class BloodRequestFormScreen extends StatefulWidget {
  const BloodRequestFormScreen({super.key});

  @override
  State<BloodRequestFormScreen> createState() =>
      _BloodRequestFormScreenState();
}

class _BloodRequestFormScreenState extends State<BloodRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final GeoLocationService _geoLocationService = GeoLocationService();
  final NotificationService _notificationService = NotificationService();

  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _unitsRequiredController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedBloodGroup = 'B+';
  String _selectedUrgency = 'Normal';
  String _selectedGender = 'Male';
  DateTime? _requiredByDate;

  bool _isLoading = false;
  String? _currentLocation;
  double? _currentLat;
  double? _currentLng;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  final List<String> _urgencyLevels = [
    'Critical', 'Urgent', 'Normal', 'Low'
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await LocationHelper.getCurrentLocation();
      if (location != null) {
        final address = await LocationHelper.getAddressFromCoordinates(
          location.latitude,
          location.longitude,
        );
        setState(() {
          _currentLocation = address;
          _currentLat = location.latitude;
          _currentLng = location.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _requiredByDate = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiredByDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select required by date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final age = int.tryParse(_patientAgeController.text.trim());
    final units = int.tryParse(_unitsRequiredController.text.trim());

    if (age == null || units == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid age and units'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final request = BloodRequestModel(
        id: '',
        requesterId: user.uid,
        requesterName: user.displayName ?? 'Unknown',
        requesterPhone: user.phoneNumber ?? '',
        patientName: _patientNameController.text.trim(),
        patientAge: age,
        patientGender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        unitsRequired: units,
        hospitalName: _hospitalNameController.text.trim(),
        hospitalAddress: _hospitalAddressController.text.trim(),
        urgency: _selectedUrgency,
        reason: _reasonController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        requiredBy: _requiredByDate!,
        status: 'pending',
        createdAt: DateTime.now(),
        location: _currentLocation ?? '',
        latitude: _currentLat,
        longitude: _currentLng,
      );

      /// 🔥 SAVE TO FIRESTORE
      final requestId = await _firestoreService.createBloodRequest(request);

      // Donor auto-search + notify (unchanged)
      if (_currentLat != null && _currentLng != null) {
        try {
          final donors = await _geoLocationService.findNearbyDonorsWithExpand(
            receiverLat: _currentLat!,
            receiverLng: _currentLng!,
            bloodGroup: _selectedBloodGroup,
          );

          if (donors.isNotEmpty) {
            await _notificationService.sendToUsers(
              userIds: donors.map((d) => d.uid).toList(),
              title: 'Blood Needed: $_selectedBloodGroup',
              body:
              'A patient at ${_hospitalNameController.text.trim()} needs $_selectedBloodGroup blood ($_selectedUrgency).',
              type: 'blood_request',
              relatedId: requestId,
            );
            await _firestoreService.updateNotifiedDonors(
              requestId,
              donors.map((d) => d.uid).toList(),
            );
          }
        } catch (_) {
          // Don't block request submission if donor search/notify fails —
          // the request is already saved; admin can still see & act on it.
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        /// ✅ RETURN DATA TO DASHBOARD
        Navigator.pop(context, request);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Blood Request Form', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient hint banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 22),
                    SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Text(
                        'Nearby matching donors will be notified automatically once you submit.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _sectionTitle('Patient Information'),
              const SizedBox(height: AppSpacing.sm + 2),
              CustomTextField(
                controller: _patientNameController,
                label: 'Patient Name',
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Patient name required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _patientAgeController,
                label: 'Age',
                prefixIcon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: AppValidators.validateAge,
              ),
              const SizedBox(height: AppSpacing.md),
              _genderSelector(),

              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              _sectionTitle('Blood Requirement'),
              const SizedBox(height: AppSpacing.sm + 2),
              const Text('Blood Group', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              _bloodGroupSelector(),
              const SizedBox(height: AppSpacing.lg),
              const Text('Urgency Level', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              _urgencySelector(),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _unitsRequiredController,
                label: 'Units Required',
                prefixIcon: Icons.bloodtype_outlined,
                keyboardType: TextInputType.number,
                validator: AppValidators.validateUnitsRequired,
              ),

              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              _sectionTitle('Hospital Information'),
              const SizedBox(height: AppSpacing.sm + 2),
              CustomTextField(
                controller: _hospitalNameController,
                label: 'Hospital Name',
                prefixIcon: Icons.local_hospital_outlined,
                validator: AppValidators.validateHospitalName,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _hospitalAddressController,
                label: 'Hospital Address',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _contactNumberController,
                label: 'Contact Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _reasonController,
                label: 'Reason / Notes (optional)',
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Required By Date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, size: AppSpacing.iconSm + 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Text(
                    _requiredByDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(_requiredByDate!),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: AppSpacing.elevationLow,
                    shadowColor: AppColors.shadowRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Submit Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
  );

  Widget _genderSelector() {
    return Row(
      children: _genders.map((g) {
        final selected = _selectedGender == g;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(g),
              selected: selected,
              onSelected: (_) => setState(() => _selectedGender = g),
              selectedColor: AppColors.primaryRed.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryRed : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(color: selected ? AppColors.primaryRed : Colors.grey.shade300),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bloodGroupSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _bloodGroups.map((bg) {
        final selected = _selectedBloodGroup == bg;
        return GestureDetector(
          onTap: () => setState(() => _selectedBloodGroup = bg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
            ),
            child: Text(
              bg,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _urgencySelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _urgencyLevels.map((u) {
        final selected = _selectedUrgency == u;
        return GestureDetector(
          onTap: () => setState(() => _selectedUrgency = u),
          child: Opacity(
            opacity: selected ? 1 : 0.55,
            child: UrgencyBadge(urgency: u),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _unitsRequiredController.dispose();
    _contactNumberController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}