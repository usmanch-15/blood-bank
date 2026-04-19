import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../models/blood_request_model.dart';
import '../../utils/location_helper.dart';

/// Donor Matching Screen - Find nearby donors for receiver
class DonorMatchingScreen extends StatefulWidget {
  final String? bloodGroupFilter;

  const DonorMatchingScreen({
    super.key,
    this.bloodGroupFilter,
  });

  @override
  State<DonorMatchingScreen> createState() => _DonorMatchingScreenState();
}

class _DonorMatchingScreenState extends State<DonorMatchingScreen> {
  late FirestoreService _firestoreService;
  final user = FirebaseAuth.instance.currentUser;
  Position? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      Position position = await LocationHelper.getCurrentLocation() ?? Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      setState(() {
        _userPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Donors'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text('Unable to access location'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _isLoading = true;
                          _loadCurrentLocation();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder(
                  future: _firestoreService.getNearbyDonors(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                    10, // 10 km radius
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final donors = (snapshot.data ?? [])
                        .where((donor) =>
                            widget.bloodGroupFilter == null ||
                            donor.bloodGroup == widget.bloodGroupFilter)
                        .toList();

                    if (donors.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No eligible donors nearby',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try expanding the search radius',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: donors.length,
                      itemBuilder: (context, index) {
                        final donor = donors[index];
                        final distance = LocationHelper.calculateDistance(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                          donor.latitude ?? 0,
                          donor.longitude ?? 0,
                        );

                        return _buildDonorCard(donor, distance);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildDonorCard(dynamic donor, double distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryRed,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    donor.bloodGroup ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening chat...')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Initiating call...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
