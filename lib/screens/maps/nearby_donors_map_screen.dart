import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../services/geo_location_service.dart';

/// ✅ REWRITTEN (2nd pass) — switched from google_maps_flutter to
/// flutter_map (OpenStreetMap tiles). Google Maps requires a Google Cloud
/// Platform project with a BILLING ACCOUNT linked (a card on file) just to
/// enable the Maps SDK, even to stay within the free tier — Usman doesn't
/// have a card, so that path was a hard blocker. flutter_map + OpenStreetMap
/// needs NO API key, NO billing account, ever — it's genuinely free.
///
/// Also still uses real Firestore data (GeoLocationService.findNearbyDonorsWithExpand)
/// instead of the original hardcoded dummy donors — that part is unchanged
/// from the previous fix.
class NearbyDonorsMapScreen extends StatefulWidget {
  final String? bloodGroup; // null = show donors of any blood group

  const NearbyDonorsMapScreen({super.key, this.bloodGroup});

  @override
  State<NearbyDonorsMapScreen> createState() => _NearbyDonorsMapScreenState();
}

class _NearbyDonorsMapScreenState extends State<NearbyDonorsMapScreen> {
  final GeoLocationService _geoService = GeoLocationService();
  final MapController _mapController = MapController();

  List<DonorModel> _donors = [];
  LatLng? _center;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNearbyDonors();
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

      if (!mounted) return;
      setState(() {
        _center = center;
        _donors = donors;
        _isLoading = false;
      });

      // Map might not be mounted yet on first load — guard with a
      // post-frame callback so `move` doesn't run before FlutterMap exists.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(center, 13);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<DonorModel> get _donorsWithLocation =>
      _donors.where((d) => d.latitude != null && d.longitude != null).toList();

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

  void _goToCenter() {
    if (_center != null) {
      _mapController.move(_center!, 14);
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

    final center = _center ?? const LatLng(0, 0);
    final donors = _donorsWithLocation;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            // OpenStreetMap tiles — free, no API key required. The
            // userAgentPackageName is required by OSM's tile usage policy
            // (identifies the app making requests, not a secret).
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.usmanch.bloodbank',
            ),
            MarkerLayer(
              markers: [
                // Receiver's own position, so they have a frame of reference.
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle,
                      color: Colors.blue, size: 40),
                ),
                for (final donor in donors)
                  Marker(
                    point: LatLng(donor.latitude!, donor.longitude!),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _showDonorSheet(donor),
                      child: const Icon(Icons.location_on,
                          color: AppColors.primaryRed, size: 44),
                    ),
                  ),
              ],
            ),
            // OSM requires attribution to be visible on the map.
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (donors.isEmpty)
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
    _mapController.dispose();
    super.dispose();
  }
}