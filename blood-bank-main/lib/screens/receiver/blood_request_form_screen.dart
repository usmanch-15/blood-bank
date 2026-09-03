import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _BloodRequestFormScreenState
    extends State<BloodRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Form controllers
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _unitsRequiredController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _reasonController = TextEditingController();

  // Form data
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
    } catch (e) {
      // Handle location error silently
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _requiredByDate) {
      setState(() {
        _requiredByDate = picked;
      });
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blood Request Form'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Bottom Curve
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 90,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Content
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Information Section
                  _buildSectionHeader('Patient Information'),
                  _buildTextField(
                    controller: _patientNameController,
                    label: 'Patient Name',
                    hint: 'Enter patient full name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Patient name is required';
                      if (value!.length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _patientAgeController,
                          label: 'Age',
                          hint: 'Years',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Age is required';
                            final age = int.tryParse(value!);
                            if (age == null || age < 1 || age > 120) {
                              return 'Enter valid age (1-120)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Gender',
                          value: _selectedGender,
                          items: _genders,
                          onChanged: (value) => setState(() => _selectedGender = value!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Blood Requirements Section
                  _buildSectionHeader('Blood Requirements'),
                  _buildDropdownField(
                    label: 'Blood Group Required',
                    value: _selectedBloodGroup,
                    items: _bloodGroups,
                    onChanged: (value) => setState(() => _selectedBloodGroup = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _unitsRequiredController,
                    label: 'Units Required',
                    hint: 'Number of units needed',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Units required is needed';
                      final units = int.tryParse(value!);
                      if (units == null || units < 1 || units > 10) {
                        return 'Enter valid units (1-10)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Urgency Level',
                    value: _selectedUrgency,
                    items: _urgencyLevels,
                    onChanged: (value) => setState(() => _selectedUrgency = value!),
                  ),

                  const SizedBox(height: 24),

                  // Hospital Information Section
                  _buildSectionHeader('Hospital Information'),
                  _buildTextField(
                    controller: _hospitalNameController,
                    label: 'Hospital Name',
                    hint: 'Enter hospital name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Hospital name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _hospitalAddressController,
                    label: 'Hospital Address',
                    hint: 'Complete hospital address',
                    maxLines: 3,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Hospital address is required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Contact & Timeline Section
                  _buildSectionHeader('Contact & Timeline'),
                  _buildTextField(
                    controller: _contactNumberController,
                    label: 'Contact Number',
                    hint: '+92 300 1234567',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Contact number is required';
                      if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value!)) {
                        return 'Enter valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),

                  const SizedBox(height: 24),

                  // Additional Information Section
                  _buildSectionHeader('Additional Information'),
                  _buildTextField(
                    controller: _reasonController,
                    label: 'Reason for Request',
                    hint: 'Brief description of medical condition',
                    maxLines: 3,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Reason is required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _submitRequest,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Blood Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade900,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'This field is required';
        return null;
      },
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
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.red),
        ),
        child: Text(
          _requiredByDate != null
              ? DateFormat('MMM dd, yyyy').format(_requiredByDate!)
              : 'Select date',
          style: TextStyle(
            color: _requiredByDate != null ? Colors.black : Colors.grey,
          ),
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