import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../utils/location_helper.dart';
import '../../models/user_model.dart';

/// Nearest Donor Search Result Screen
class NearestDonorSearchScreen extends StatefulWidget {
  final String bloodGroup;

  const NearestDonorSearchScreen({
    super.key,
    required this.bloodGroup,
  });

  @override
  State<NearestDonorSearchScreen> createState() =>
      _NearestDonorSearchScreenState();
}

class _NearestDonorSearchScreenState extends State<NearestDonorSearchScreen> {
  late FirestoreService _firestoreService;
  Position? _userPosition;
  List<UserModel> _nearbyDonors = [];
  bool _isLoading = true;
  int _sortBy = 0; // 0: distance, 1: rating

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _searchNearbyDonors();
  }

  Future<void> _searchNearbyDonors() async {
    try {
      Position position = await LocationHelper.getCurrentLocation() ?? Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      _userPosition = position;

      final donors = await _firestoreService.getNearbyDonors(
        position.latitude,
        position.longitude,
        10, // 10 km radius
      );

      // Filter by blood group
      final filtered = donors
          .where((d) => d.bloodGroup == widget.bloodGroup)
          .toList();

      setState(() {
        _nearbyDonors = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _sortDonors(int sortType) {
    setState(() => _sortBy = sortType);

    if (_userPosition == null) return;

    if (sortType == 0) {
      // Sort by distance
      _nearbyDonors.sort((a, b) {
        double distA = LocationHelper.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          a.latitude ?? 0,
          a.longitude ?? 0,
        );
        double distB = LocationHelper.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          b.latitude ?? 0,
          b.longitude ?? 0,
        );
        return distA.compareTo(distB);
      });
    } else {
      // Sort by reward points (as rating proxy)
      _nearbyDonors.sort((a, b) => b.rewardPoints.compareTo(a.rewardPoints));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bloodGroup} Donors'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sort options
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      const Text(
                        'Sort by:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('Nearest'),
                                selected: _sortBy == 0,
                                onSelected: (selected) => _sortDonors(0),
                                backgroundColor: Colors.white,
                                selectedColor:
                                    AppColors.primaryRed.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color:
                                      _sortBy == 0 ? AppColors.primaryRed : null,
                                  fontWeight: _sortBy == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Top Rated'),
                                selected: _sortBy == 1,
                                onSelected: (selected) => _sortDonors(1),
                                backgroundColor: Colors.white,
                                selectedColor:
                                    AppColors.primaryRed.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color:
                                      _sortBy == 1 ? AppColors.primaryRed : null,
                                  fontWeight: _sortBy == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results
                Expanded(
                  child: _nearbyDonors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text('No donors found'),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.bloodGroup} donors not available in your area',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _nearbyDonors.length,
                          itemBuilder: (context, index) {
                            final donor = _nearbyDonors[index];
                            final distance = _userPosition != null
                                ? LocationHelper.calculateDistance(
                                    _userPosition!.latitude,
                                    _userPosition!.longitude,
                                    donor.latitude ?? 0,
                                    donor.longitude ?? 0,
                                  )
                                : 0.0;

                            return _buildDonorResultCard(donor, distance);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDonorResultCard(UserModel donor, double distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
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
                        donor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${(donor.rewardPoints / 50).toStringAsFixed(1)} (${donor.rewardPoints} ~)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    donor.bloodGroup ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Distance and Details
            // Each column is Expanded so the (variable-length) phone value can
            // never push the row past the screen width on narrow phones.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Est. Time',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(distance * 2).toStringAsFixed(0)} min',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phone',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        donor.phoneNumber ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening chat...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Initiating call...')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
