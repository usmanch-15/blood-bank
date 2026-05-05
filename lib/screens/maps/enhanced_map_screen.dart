import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class EnhancedMapScreen extends StatefulWidget {
  final String? initialBloodGroup;

  const EnhancedMapScreen({super.key, this.initialBloodGroup});

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  GoogleMapController? _mapController;

  String? _selectedBloodGroup;
  bool _showEligibleOnly = true;
  Map<String, dynamic>? _selectedDonor;

  static const LatLng _defaultCenter = LatLng(30.0450, 72.3520);

  final List<Map<String, dynamic>> _donors = [
    {
      'id': '1',
      'name': 'Ahmed',
      'bloodGroup': 'O+',
      'lat': 30.046,
      'lng': 72.354,
      'location': 'Vehari',
      'distance': '1 km',
      'isEligible': true,
      'donations': 5,
    },
    {
      'id': '2',
      'name': 'Sara',
      'bloodGroup': 'A+',
      'lat': 30.047,
      'lng': 72.350,
      'location': 'Vehari',
      'distance': '2 km',
      'isEligible': true,
      'donations': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedBloodGroup = widget.initialBloodGroup;
  }

  List<Map<String, dynamic>> get filteredDonors {
    return _donors.where((d) {
      final matchBlood = _selectedBloodGroup == null ||
          d['bloodGroup'] == _selectedBloodGroup;

      final matchEligible =
          !_showEligibleOnly || d['isEligible'] == true;

      return matchBlood && matchEligible;
    }).toList();
  }

  Set<Marker> get markers {
    return filteredDonors.map((d) {
      return Marker(
        markerId: MarkerId(d['id']),
        position: LatLng(d['lat'], d['lng']),
        infoWindow: InfoWindow(
          title: d['name'],
          snippet: d['bloodGroup'],
        ),
        onTap: () {
          setState(() => _selectedDonor = d);
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(
          d['isEligible']
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange,
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Map"),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 13,
            ),
            markers: markers,
            onMapCreated: (c) => _mapController = c,
          ),

          // simple filter
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Row(
                children: [
                  const Text("Eligible only"),
                  Switch(
                    value: _showEligibleOnly,
                    onChanged: (v) {
                      setState(() => _showEligibleOnly = v);
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_selectedDonor != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Text(
                  "Selected: ${_selectedDonor!['name']}",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}