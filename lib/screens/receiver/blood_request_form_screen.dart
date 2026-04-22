import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/blood_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/location_helper.dart';

class BloodRequestFormScreen extends StatefulWidget {
  const BloodRequestFormScreen({super.key});

  @override
  State<BloodRequestFormScreen> createState() =>
      _BloodRequestFormScreenState();
}

class _BloodRequestFormScreenState extends State<BloodRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _unitsRequiredController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _reasonController = TextEditingController();

  // Form values
  String _selectedBloodGroup = 'B+';
  String _selectedUrgency = 'Normal';
  String _selectedGender = 'Male';
  DateTime? _requiredByDate;
  bool _isLoading = false;
  String? _currentLocation;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  final List<String> _urgencyLevels = [
    'Critical',
    'Urgent',
    'Normal',
    'Low'
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
        });
      }
    } catch (_) {}
  }

  Future<void> _selectDate(BuildContext context) async {
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

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final request = BloodRequestModel(
        id: '',
        requesterId: user.uid,

        // ✅ ADD THESE (missing fields causing error)
        requesterName: user.displayName ?? 'Unknown',
        requesterPhone: user.phoneNumber ?? '',

        patientName: _patientNameController.text.trim(),
        patientAge: int.parse(_patientAgeController.text.trim()),
        patientGender: _selectedGender,

        bloodGroup: _selectedBloodGroup,
        unitsRequired: int.parse(_unitsRequiredController.text.trim()),

        hospitalName: _hospitalNameController.text.trim(),
        hospitalAddress: _hospitalAddressController.text.trim(),

        urgency: _selectedUrgency,
        reason: _reasonController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),

        requiredBy: _requiredByDate!,
        status: 'pending',
        createdAt: DateTime.now(),
        location: _currentLocation ?? '',
      );

      await _firestoreService.createBloodRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blood request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blood Request Form'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildTextField(
                controller: _patientNameController,
                label: 'Patient Name',
                hint: 'Enter patient name',
                validator: (v) =>
                v!.isEmpty ? 'Patient name required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _patientAgeController,
                label: 'Age',
                hint: 'Enter age',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Blood Group',
                value: _selectedBloodGroup,
                items: _bloodGroups,
                onChanged: (v) =>
                    setState(() => _selectedBloodGroup = v!),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Urgency',
                value: _selectedUrgency,
                items: _urgencyLevels,
                onChanged: (v) =>
                    setState(() => _selectedUrgency = v!),
              ),
              const SizedBox(height: 12),
              _buildDateField(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Required By Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _requiredByDate == null
              ? 'Select date'
              : DateFormat('dd MMM yyyy').format(_requiredByDate!),
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