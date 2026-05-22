import 'package:flutter/material.dart';

class AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onToggle;

  const AvailabilityToggle({
    super.key,
    required this.isAvailable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isAvailable ? Colors.green : Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: isAvailable ? Colors.green : Colors.grey, size: 12),
            const SizedBox(width: 8),
            Text(isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                    color: isAvailable ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Switch(
              value: isAvailable,
              onChanged: (_) => onToggle(),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}