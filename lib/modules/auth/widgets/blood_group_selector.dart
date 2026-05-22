import 'package:flutter/material.dart';

class BloodGroupSelector extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const BloodGroupSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Blood Group',
        prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: bloodGroups
          .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Select blood group' : null,
    );
  }
}