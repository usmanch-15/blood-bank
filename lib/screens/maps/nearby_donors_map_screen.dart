import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

/// Nearby Donors Map Screen - Show donors on Google Maps
/// Note: Google Maps API key must be configured in:
/// - android/app/src/main/AndroidManifest.xml
/// - ios/Runner/AppDelegate.swift (for iOS)
class NearbyDonorsMapScreen extends StatefulWidget {
  final String? bloodGroup;

  const NearbyDonorsMapScreen({super.key, this.bloodGroup});

  @override
  State<NearbyDonorsMapScreen> createState() => _NearbyDonorsMapScreenState();
}

class _NearbyDonorsMapScreenState extends State<NearbyDonorsMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _center = const LatLng(0.0, 0.0); // Default location

  @override
  void initState() {
    super.initState();
    // TODO: Get user's current location using LocationHelper
    // For now, using a default location
    _center = const LatLng(40.7128, -74.0060); // New York as example
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Donors'),
        backgroundColor: AppColors.secondaryBlue,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: AppConstants.defaultZoom,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _loadNearbyDonors();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNearbyDonors,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  /// Load nearby donors and add markers to map
  /// TODO: Implement actual donor fetching logic using FirestoreService
  void _loadNearbyDonors() {
    // Example markers - Replace with actual donor data
    setState(() {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('donor1'),
          position: const LatLng(40.7128, -74.0060),
          infoWindow: const InfoWindow(
            title: 'Donor Name',
            snippet: 'Blood Group: O+',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        // Add more markers from actual donor data
      ]);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
