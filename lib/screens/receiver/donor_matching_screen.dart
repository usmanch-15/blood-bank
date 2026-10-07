import 'package:flutter/material.dart';
import '../maps/nearby_donors_map_screen.dart';

class DonorMatchingScreen extends StatelessWidget {
  final String? initialBloodGroup, requestId;
  const DonorMatchingScreen({
    super.key,
    this.initialBloodGroup,
    this.requestId,
  });
  @override
  Widget build(BuildContext context) => NearbyDonorsMapScreen(
    bloodGroup: initialBloodGroup,
    requestId: requestId,
    listInitially: true,
  );
}
