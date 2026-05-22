import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _roleCard('donor', Icons.favorite, 'Donor')),
        const SizedBox(width: 12),
        Expanded(child: _roleCard('receiver', Icons.local_hospital, 'Receiver')),
      ],
    );
  }

  Widget _roleCard(String role, IconData icon, String label) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => onRoleSelected(role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}