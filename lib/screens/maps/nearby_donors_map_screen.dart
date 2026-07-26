import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../services/geo_location_service.dart';

/// ✅ REWRITTEN — was showing 3 hardcoded fake donors ("Ahmed", "Sara",
/// "Ali") at fixed New York coordinates regardless of who opened it or
/// where they were. Now uses the receiver's real GPS location + a real
/// Firestore query (GeoLocationService.findNearbyDonorsWithExpand, which
/// already existed but was never actually called from a screen) to show
/// real nearby donors, auto-expanding the search radius if none are found
/// close by.
class NearbyDonorsMapScreen extends StatefulWidget {
  final String? bloodGroup; // null = show donors of any blood group

  const NearbyDonorsMapScreen({super.key, this.bloodGroup});

  @override
  State<NearbyDonorsMapScreen> createState() => _NearbyDonorsMapScreenState();
}

class _NearbyDonorsMapScreenState extends State<NearbyDonorsMapScreen> {
  final GeoLocationService _geoService = GeoLocationService();
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};
  List<DonorModel> _donors = [];

  LatLng? _center;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyDonors();
    });
  }

  Future<void> _loadNearbyDonors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _geoService.getCurrentLocation();
      final center = LatLng(position.latitude, position.longitude);

      final donors = await _geoService.findNearbyDonorsWithExpand(
        receiverLat: position.latitude,
        receiverLng: position.longitude,
        bloodGroup: widget.bloodGroup,
      );

      final markers = <Marker>{
        // Receiver's own position, so they have a frame of reference.
        Marker(
          markerId: const MarkerId('me'),
          position: center,
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        for (final donor in _donorsWithLocation(donors))
          Marker(
            markerId: MarkerId(donor.uid),
            position: LatLng(donor.latitude!, donor.longitude!),
            infoWindow: InfoWindow(
              title: donor.name.isNotEmpty ? donor.name : 'Donor',
              snippet: 'Blood: ${donor.bloodGroup ?? '—'}'
                  '${donor.phoneNumber != null ? ' • Tap for details' : ''}',
              onTap: () => _showDonorSheet(donor),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      };

      if (!mounted) return;
      setState(() {
        _center = center;
        _donors = donors;
        _markers
          ..clear()
          ..addAll(markers);
        _isLoading = false;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, 13));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<DonorModel> _donorsWithLocation(List<DonorModel> donors) =>
      donors.where((d) => d.latitude != null && d.longitude != null).toList();

  void _showDonorSheet(DonorModel donor) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(donor.name.isNotEmpty ? donor.name : 'Donor',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Blood group: ${donor.bloodGroup ?? '—'}'),
            const SizedBox(height: 16),
            if (donor.phoneNumber != null && donor.phoneNumber!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('Call Donor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: donor.phoneNumber)),
              )
            else
              const Text('No phone number on file for this donor.'),
          ],
        ),
      ),
    );
  }

  /// 📍 Move camera back to receiver's own location.
  void _goToCenter() {
    if (_center != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center!, 14));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bloodGroup != null
              ? 'Nearby ${widget.bloodGroup} Donors'
              : 'Nearby Donors',
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.my_location), onPressed: _goToCenter),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        onPressed: _loadNearbyDonors,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNearbyDonors,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _center ?? const LatLng(0, 0),
            zoom: 13,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // we have our own button in the AppBar
          mapType: MapType.normal,
          onMapCreated: (controller) => _mapController = controller,
        ),
        if (_donorsWithLocation(_donors).isEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.bloodGroup != null
                      ? 'No ${widget.bloodGroup} donors found nearby (even after expanding the search up to 50km).'
                      : 'No donors found nearby (even after expanding the search up to 50km).',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}