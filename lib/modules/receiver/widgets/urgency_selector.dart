import 'package:flutter/material.dart';

class UrgencySelector extends StatelessWidget {
  final String? selected;
  final Function(String) onSelected;

  const UrgencySelector({super.key, required this.selected, required this.onSelected});

  static const levels = [
    {'label': 'Routine', 'color': Colors.blue},
    {'label': 'Urgent', 'color': Colors.orange},
    {'label': 'Critical', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: levels.map((level) {
        final label = level['label'] as String;
        final color = level['color'] as Color;
        final isSelected = selected == label;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(label),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? color : Colors.grey.shade300),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        );
      }).toList(),
    );
  }
}