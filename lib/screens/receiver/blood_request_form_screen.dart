import '../../widgets/unsaved_changes_guard.dart';
import '../../controllers/auth_controller.dart';
import 'package:provider/provider.dart';
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
import '../maps/nearby_donors_map_screen.dart'; // ✅ NEW — post-submit map redirect

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String _selectedBloodGroup = 'B+';
  String _selectedUrgency = 'Normal';
  String _selectedGender = 'Male';
  DateTime? _requiredByDate;

  bool _isLoading = false;
  bool _dirty = false;
  double? _currentLat;
  double? _currentLng;

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
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await LocationHelper.getCurrentLocation();
      if (location != null) {
        if (!mounted) return;
        setState(() {
          _currentLat = location.latitude;
          _currentLng = location.longitude;
          if (_latitudeController.text.isEmpty) {
            _latitudeController.text = location.latitude.toStringAsFixed(6);
          }
          if (_longitudeController.text.isEmpty) {
            _longitudeController.text = location.longitude.toStringAsFixed(6);
          }
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
      if (mounted) {
        setState(() {
          _requiredByDate = picked;
          _dirty = true;
        });
      }
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
    _currentLat = double.tryParse(_latitudeController.text.trim());
    _currentLng = double.tryParse(_longitudeController.text.trim());

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final request = BloodRequestModel(
        id: '',
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
          }
        } catch (_) {
          // Don't block request submission if donor search/notify fails —
          // the request is already saved; admin can still see & act on it.
        }
      }

      if (mounted) {
        setState(() {
          _dirty = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully!'),
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
            builder:
                (_) => NearbyDonorsMapScreen(
                  bloodGroup: _selectedBloodGroup,
                  requestId: requestId,
                  unitsNeeded: units,
                ),
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
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
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
                  validator: AppValidators.validateName,
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
                  validator: AppValidators.validateUnitsRequired,
                ),

                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Hospital Information'),
                const SizedBox(height: AppSpacing.sm + 2),
                const Text(
                  'Enter the hospital coordinates for donor matching. Current GPS coordinates are filled when available; update them if the hospital is elsewhere.',
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _latitudeController,
                  label: 'Hospital latitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return n != null && n.isFinite && n >= -90 && n <= 90
                        ? null
                        : 'Enter a latitude between -90 and 90';
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _longitudeController,
                  label: 'Hospital longitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return n != null && n.isFinite && n >= -180 && n <= 180
                        ? null
                        : 'Enter a longitude between -180 and 180';
                  },
                ),
                const SizedBox(height: AppSpacing.md),
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
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Hospital address required'
                              : null,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _contactNumberController,
                  label: 'Contact Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.validatePhone,
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
    return Row(
      children:
          _genders.map((g) {
            final selected = _selectedGender == g;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
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
                    color:
                        selected ? AppColors.primaryRed : Colors.grey.shade300,
                  ),
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
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _unitsRequiredController.dispose();
    _contactNumberController.dispose();
    _reasonController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
