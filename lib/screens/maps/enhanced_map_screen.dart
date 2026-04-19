import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../utils/location_helper.dart';
import '../../models/user_model.dart';

/// Enhanced Map View with donor markers
class EnhancedMapScreen extends StatefulWidget {
  final String? bloodGroupFilter;
  final double? centerLatitude;
  final double? centerLongitude;

  const EnhancedMapScreen({
    super.key,
    this.bloodGroupFilter,
    this.centerLatitude,
    this.centerLongitude,
  });

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  late GoogleMapController _mapController;
  late FirestoreService _firestoreService;
  Position? _userPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _loadLocationAndMarkers();
  }

  Future<void> _loadLocationAndMarkers() async {
    try {
      // Get current location if not provided
      if (widget.centerLatitude == null || widget.centerLongitude == null) {
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
        _userPosition = position;
      } else {
        _userPosition = Position(
          latitude: widget.centerLatitude!,
          longitude: widget.centerLongitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // Load nearby donors
      final donors = await _firestoreService.getNearbyDonors(
        _userPosition!.latitude,
        _userPosition!.longitude,
        10, // 10 km radius
      );

      // Filter by blood group if specified
      final filteredDonors = widget.bloodGroupFilter == null
          ? donors
          : donors
              .where((d) => d.bloodGroup == widget.bloodGroupFilter)
              .toList();

      // Create markers
      Set<Marker> markers = {};

      // Add user marker
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Add donor markers
      for (var i = 0; i < filteredDonors.length; i++) {
        final donor = filteredDonors[i];
        if (donor.latitude != null && donor.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('donor_$i'),
              position: LatLng(donor.latitude!, donor.longitude!),
              infoWindow: InfoWindow(
                title: donor.name,
                snippet: '${donor.bloodGroup} - ${donor.phoneNumber}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading map: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map'),
          backgroundColor: AppColors.primaryRed,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Map'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadLocationAndMarkers();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Info Panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Legend',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Your Location', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 20),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Donor', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_markers.length - 1} donors nearby',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
}
