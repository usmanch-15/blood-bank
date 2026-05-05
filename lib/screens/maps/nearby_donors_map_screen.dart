import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class NearbyDonorsMapScreen extends StatefulWidget {
  final String? bloodGroup;

  const NearbyDonorsMapScreen({super.key, this.bloodGroup});

  @override
  State<NearbyDonorsMapScreen> createState() =>
      _NearbyDonorsMapScreenState();
}

class _NearbyDonorsMapScreenState extends State<NearbyDonorsMapScreen> {
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  LatLng _center = const LatLng(40.7128, -74.0060);

  // 🔥 Dummy donor data (replace later with Firestore)
  final List<Map<String, dynamic>> _donors = [
    {
      "id": "1",
      "name": "Ahmed",
      "bloodGroup": "O+",
      "lat": 40.7130,
      "lng": -74.0065,
    },
    {
      "id": "2",
      "name": "Sara",
      "bloodGroup": "A+",
      "lat": 40.7140,
      "lng": -74.0070,
    },
    {
      "id": "3",
      "name": "Ali",
      "bloodGroup": "B+",
      "lat": 40.7150,
      "lng": -74.0080,
    },
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyDonors();
    });
  }

  /// 🔥 MAIN LOGIC: load + filter + show markers
  void _loadNearbyDonors() {
    final String? filterGroup = widget.bloodGroup;

    Set<Marker> newMarkers = {};

    for (var donor in _donors) {
      // blood group filter
      if (filterGroup != null &&
          donor['bloodGroup'] != filterGroup) {
        continue;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(donor['id']),
          position: LatLng(
            donor['lat'],
            donor['lng'],
          ),
          infoWindow: InfoWindow(
            title: donor['name'],
            snippet: "Blood: ${donor['bloodGroup']}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  /// 📍 Move camera to user/center
  void _goToCenter() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_center, 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Donors'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCenter,
          )
        ],
      ),

      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 13,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        onMapCreated: (controller) {
          _mapController = controller;
          _loadNearbyDonors();
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        onPressed: _loadNearbyDonors,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}