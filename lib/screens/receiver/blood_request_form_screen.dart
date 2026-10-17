import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../maps/hospital_location_screen.dart';
import '../requests/request_tracking_screen.dart';
import '../../widgets/unsaved_changes_guard.dart';
import '../../controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/blood_request_model.dart';
import '../../services/firestore_service.dart';

import '../../utils/validators.dart';
import '../../utils/input_formatters.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
// ✅ NEW — post-submit map redirect

/// ✅ UI POLISH ONLY — every piece of logic below (Firestore save, geo
/// location fetch, nearby-donor search + notify, validators) is byte-for-
/// byte unchanged from the previous version. Only the visual layer changed:
/// gradient header, sectioned form with dividers, colored blood-group/
/// urgency chip selectors instead of plain dropdowns, CustomTextField for
/// consistent styling.
class BloodRequestFormScreen extends StatefulWidget {
  const BloodRequestFormScreen({super.key});

  @override
  State<BloodRequestFormScreen> createState() => _BloodRequestFormScreenState();
}

class _BloodRequestFormScreenState extends State<BloodRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formScrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

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
  bool _dirty = false;
  final String _submissionId =
      FirebaseFirestore.instance.collection('blood_requests').doc().id;
  double? _currentLat;
  double? _currentLng;
  String? _hospitalId;
  bool _hospitalSelectionError = false;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  final List<String> _urgencyLevels = ['Critical', 'Urgent', 'Normal', 'Low'];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickHospital() async {
    final selection = await Navigator.push<LocationSelection>(
      context,
      MaterialPageRoute(builder: (_) => HospitalLocationScreen()),
    );
    if (selection != null && mounted) {
      setState(() {
        _currentLat = selection.point.latitude;
        _currentLng = selection.point.longitude;
        _hospitalId = selection.hospitalId;
        _hospitalNameController.text = selection.hospitalName;
        _hospitalAddressController.text = selection.address;
        _dirty = true;
        _hospitalSelectionError = false;
      });
      if (selection.hospitalName.isEmpty) {
        FocusScope.of(context).requestFocus(_hospitalNameFocusNode);
      }
    }
  }

  final _hospitalNameFocusNode = FocusNode();

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          _requiredByDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
          );
          _dirty = true;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    final hasHospitalLocation = _currentLat != null && _currentLng != null;
    setState(() => _hospitalSelectionError = !hasHospitalLocation);
    final isValid = _formKey.currentState!.validate();
    if (!hasHospitalLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectHospitalPoint),
        ),
      );
      return;
    }
    if (!isValid) return;

    if (_requiredByDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).requiredDateMissing),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final age = int.tryParse(_patientAgeController.text.trim());
    final units = int.tryParse(_unitsRequiredController.text.trim());

    if (age == null || units == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidAgeUnits),
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
        id: _submissionId,
        requesterId: user.uid,
        requesterName:
            context.read<AuthController>().currentUser?.name ??
            user.displayName ??
            '',
        // ✅ FIX: `user.phoneNumber` here is FirebaseAuth's linked-phone
        // field, which is null for the vast majority of accounts (email/
        // password signup, no phone-auth linking) — so this was always
        // saving an empty string. The number the receiver actually typed
        // into this form is `_contactNumberController`, so use that.
        requesterPhone: AppValidators.normalizePhone(
          _contactNumberController.text,
        ),
        patientName: _patientNameController.text.trim(),
        patientAge: age,
        patientGender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        unitsRequired: units,
        quantity: units,
        hospitalName: _hospitalNameController.text.trim(),
        hospitalId: _hospitalId,
        hospitalAddress: _hospitalAddressController.text.trim(),
        urgency: _selectedUrgency,
        reason: _reasonController.text.trim(),
        contactNumber: AppValidators.normalizePhone(
          _contactNumberController.text,
        ),
        requiredBy: _requiredByDate!,
        status: 'pending',
        createdAt: DateTime.now(),
        location: _hospitalAddressController.text.trim(),
        latitude: _currentLat,
        longitude: _currentLng,
      );

      /// 🔥 SAVE TO FIRESTORE
      final requestId = await _firestoreService.createBloodRequest(request);

      if (mounted) {
        setState(() {
          _dirty = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).requestSubmitted),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ NEW — Uber/InDrive-style flow: instead of silently popping
        // back to the dashboard, take the receiver straight to the map so
        // they can SEE who was found, drag the search radius, tap a donor
        // for full details, and notify anyone the automatic nearby-notify
        // above may have missed (e.g. it only auto-notifies once at
        // submit time — the map lets them re-notify with a wider radius
        // later without creating a new request).
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RequestTrackingScreen(requestId: requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      dirty: _dirty,
      busy: _isLoading,
      onDiscard: () => setState(() => _dirty = false),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Blood Request Form',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: SingleChildScrollView(
            controller: _formScrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
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
                  child: Row(
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
                  inputFormatters: AppInputFormatters.name,
                  validator: AppValidators.validateName,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _patientAgeController,
                  label: 'Age',
                  prefixIcon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.age,
                  validator: AppValidators.validateAge,
                ),
                const SizedBox(height: AppSpacing.md),
                _genderSelector(),

                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Blood Requirement'),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  'Blood Group',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _bloodGroupSelector(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Urgency Level',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _urgencySelector(),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _unitsRequiredController,
                  label: 'Units Required',
                  prefixIcon: Icons.bloodtype_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.units,
                  validator: AppValidators.validateUnitsRequired,
                ),

                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Hospital Information'),
                const SizedBox(height: AppSpacing.sm + 2),
                const Text(
                  'Select a hospital by name to view its location and area on the map.',
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _pickHospital,
                  icon: const Icon(Icons.pin_drop),
                  label: Text(
                    _currentLat == null ? 'Select hospital on map' : 'Change selected hospital',
                  ),
                ),
                if (_hospitalSelectionError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Select a hospital location before submitting.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _hospitalNameController,
                  label: 'Hospital Name',
                  prefixIcon: Icons.local_hospital_outlined,
                  validator: AppValidators.validateHospitalName,
                  focusNode: _hospitalNameFocusNode,
                  inputFormatters: AppInputFormatters.hospitalName,
                  onChanged: (_) => _hospitalId = null,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _hospitalAddressController,
                  label: 'Hospital Address',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => AppValidators.validateAddress(v),
                  inputFormatters: AppInputFormatters.address,
                  onChanged: (_) => _hospitalId = null,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _contactNumberController,
                  label: 'Contact Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: AppInputFormatters.phone,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _reasonController,
                  label: 'Reason / Notes (optional)',
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 3,
                  inputFormatters: AppInputFormatters.notes,
                  validator: AppValidators.validateNotes,
                ),

                const SizedBox(height: AppSpacing.lg),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).requiredByDate,
                      prefixIcon: Icon(
                        Icons.calendar_today_outlined,
                        size: AppSpacing.iconSm + 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );

  Widget _genderSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _genders.map((g) {
            final selected = _selectedGender == g;
            return ChoiceChip(
              label: Text(g),
              selected: selected,
              onSelected:
                  (_) => setState(() {
                    _selectedGender = g;
                    _dirty = true;
                  }),
              selectedColor: AppColors.primaryRed.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color:
                    selected
                        ? AppColors.primaryRed
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppColors.primaryRed : Colors.grey.shade300,
              ),
            );
          }).toList(),
    );
  }

  Widget _bloodGroupSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children:
          _bloodGroups.map((bg) {
            final selected = _selectedBloodGroup == bg;
            return GestureDetector(
              onTap:
                  () => setState(() {
                    _selectedBloodGroup = bg;
                    _dirty = true;
                  }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color:
                      selected ? null : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  bg,
                  style: TextStyle(
                    color:
                        selected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
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
      children:
          _urgencyLevels.map((u) {
            final selected = _selectedUrgency == u;
            return GestureDetector(
              onTap:
                  () => setState(() {
                    _selectedUrgency = u;
                    _dirty = true;
                  }),
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
    _hospitalNameFocusNode.dispose();
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
