import 'package:flutter/material.dart';

class PointsProgressBar extends StatelessWidget {
  final int currentPoints;
  final int targetPoints;
  final String label;

  const PointsProgressBar({
    super.key,
    required this.currentPoints,
    required this.targetPoints,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentPoints / targetPoints).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$currentPoints / $targetPoints pts',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
      ],
    );
  }
}