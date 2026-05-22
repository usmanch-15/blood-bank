import 'package:flutter/material.dart';

class DonorMapMarker extends StatelessWidget {
  final String bloodGroup;
  final double distanceKm;

  const DonorMapMarker({
    super.key,
    required this.bloodGroup,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: Text(bloodGroup,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        Text('${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(fontSize: 10, color: Colors.red)),
      ],
    );
  }
}