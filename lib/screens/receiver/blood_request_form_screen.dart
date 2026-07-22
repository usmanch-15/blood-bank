import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/blood_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/geo_location_service.dart';
import '../../services/notification_service.dart';
import '../../utils/location_helper.dart';
import '../../utils/validators.dart';

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

      // ✅ FIX (Issue #2 / #19 / #20): previously nothing happened after
      // saving — no donor search, no notification. Now, if we have the
      // receiver's coordinates, we search for nearby eligible donors
      // (auto-expanding 15km → 30km → 50km) and notify them immediately,
      // the same way the dedicated SOS screen does.
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
      appBar: AppBar(
        title: const Text("Blood Request Form"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              _buildField(_patientNameController, "Patient Name"),
              _buildField(
                _patientAgeController,
                "Age",
                number: true,
                validator: AppValidators.validateAge,
              ),

              _buildDropdown("Blood Group", _selectedBloodGroup,
                      (val) => setState(() => _selectedBloodGroup = val!),
                  _bloodGroups),

              _buildDropdown("Urgency", _selectedUrgency,
                      (val) => setState(() => _selectedUrgency = val!),
                  _urgencyLevels),

              _buildField(
                _unitsRequiredController,
                "Units Required",
                number: true,
                validator: AppValidators.validateUnitsRequired,
              ),
              _buildField(
                _hospitalNameController,
                "Hospital Name",
                validator: AppValidators.validateHospitalName,
              ),
              _buildField(_hospitalAddressController, "Hospital Address"),

              const SizedBox(height: 10),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Required By Date",
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _requiredByDate == null
                        ? "Select Date"
                        : DateFormat('dd MMM yyyy').format(_requiredByDate!),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Request"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label,
      {bool number = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType:
        number ? TextInputType.number : TextInputType.text,
        // ✅ FIX (Issue #17): allow a real bounds-checked validator to be
        // passed in (age 1-120, units 1-50, hospital name format/length)
        // instead of every field only checking "not empty".
        validator: validator ??
                (v) => v == null || v.isEmpty ? "$label required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String value,
      Function(String?) onChanged,
      List<String> items,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
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