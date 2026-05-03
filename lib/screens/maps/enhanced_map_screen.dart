import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

/// Enhanced Map Screen — Full Google Maps with donor markers, filters,
/// and donor info bottom sheet.
class EnhancedMapScreen extends StatefulWidget {
  final String? initialBloodGroup;

  const EnhancedMapScreen({super.key, this.initialBloodGroup});

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  GoogleMapController? _mapController;
  String? _selectedBloodGroup;
  MapType _mapType = MapType.normal;
  bool _showEligibleOnly = true;
  Map<String, dynamic>? _selectedDonor;

  // Default center: Vehari, Pakistan (project's campus city)
  static const LatLng _defaultCenter = LatLng(30.0450, 72.3520);

  // 🔧 Dummy donors — replace with Firestore geolocation query
  final List<Map<String, dynamic>> _donors = [
    {
      'id': 'd1', 'name': 'Ahmed Raza', 'bloodGroup': 'O+',
      'lat': 30.0465, 'lng': 72.3540,
      'location': 'Model Town, Vehari',
      'phone': '03001234567', 'donations': 8,
      'isEligible': true, 'distance': '0.3 km',
    },
    {
      'id': 'd2', 'name': 'Sara Khan', 'bloodGroup': 'A+',
      'lat': 30.0430, 'lng': 72.3500,
      'location': 'Gulshan Colony, Vehari',
      'phone': '03119876543', 'donations': 4,
      'isEligible': true, 'distance': '0.6 km',
    },
    {
      'id': 'd3', 'name': 'Bilal Mahmood', 'bloodGroup': 'B+',
      'lat': 30.0480, 'lng': 72.3560,
      'location': 'Canal Road, Vehari',
      'phone': '03334455667', 'donations': 12,
      'isEligible': true, 'distance': '0.9 km',
    },
    {
      'id': 'd4', 'name': 'Hina Iqbal', 'bloodGroup': 'AB+',
      'lat': 30.0410, 'lng': 72.3480,
      'location': 'Old City, Vehari',
      'phone': '03211223344', 'donations': 2,
      'isEligible': false, 'distance': '1.2 km',
    },
    {
      'id': 'd5', 'name': 'Umar Farooq', 'bloodGroup': 'O-',
      'lat': 30.0500, 'lng': 72.3590,
      'location': 'New Scheme, Vehari',
      'phone': '03456789012', 'donations': 6,
      'isEligible': true, 'distance': '1.5 km',
    },
    {
      'id': 'd6', 'name': 'Zainab Ali', 'bloodGroup': 'A-',
      'lat': 30.0390, 'lng': 72.3460,
      'location': 'Satellite Town, Vehari',
      'phone': '03678901234', 'donations': 3,
      'isEligible': true, 'distance': '1.9 km',
    },
  ];

  Set<Marker> get _markers {
    final filtered = _filteredDonors;
    return filtered.map((donor) {
      final isEligible = donor['isEligible'] as bool;
      return Marker(
        markerId: MarkerId(donor['id']),
        position: LatLng(donor['lat'], donor['lng']),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isEligible
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: donor['name'],
          snippet: '${donor['bloodGroup']} • ${donor['distance']}',
        ),
        onTap: () => setState(() => _selectedDonor = donor),
      );
    }).toSet();
  }

  List<Map<String, dynamic>> get _filteredDonors {
    return _donors.where((d) {
      final bgMatch = _selectedBloodGroup == null ||
          d['bloodGroup'] == _selectedBloodGroup;
      final eligibleMatch =
          !_showEligibleOnly || (d['isEligible'] as bool);
      return bgMatch && eligibleMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedBloodGroup = widget.initialBloodGroup;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donor Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Map type toggle
          IconButton(
            icon: Icon(
              _mapType == MapType.normal
                  ? Icons.satellite_alt
                  : Icons.map_outlined,
            ),
            tooltip: 'Toggle map type',
            onPressed: () => setState(() {
              _mapType = _mapType == MapType.normal
                  ? MapType.satellite
                  : MapType.normal;
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map ──
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: AppConstants.defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _mapType,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (_) => setState(() => _selectedDonor = null),
          ),

          // ── Filter panel (top) ──
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: _buildFilterPanel(),
          ),

          // ── Legend (bottom-left) ──
          Positioned(
            bottom: _selectedDonor != null ? 260 : 100,
            left: 12,
            child: _buildLegend(),
          ),

          // ── FABs (bottom-right) ──
          Positioned(
            bottom: _selectedDonor != null ? 280 : 120,
            right: 12,
            child: Column(
              children: [
                _buildFab(
                  Icons.my_location,
                  'My location',
                      () => _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                        _defaultCenter, AppConstants.defaultZoom),
                  ),
                ),
                const SizedBox(height: 10),
                _buildFab(
                  Icons.zoom_in,
                  'Zoom in',
                      () => _mapController
                      ?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 10),
                _buildFab(
                  Icons.zoom_out,
                  'Zoom out',
                      () => _mapController
                      ?.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),

          // ── Donor count chip ──
          Positioned(
            bottom: _selectedDonor != null ? 260 : 100,
            left: 12,
            child: const SizedBox.shrink(),
          ),

          // ── Donor info card ──
          if (_selectedDonor != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildDonorInfoCard(_selectedDonor!),
            ),

          // ── Donor count banner ──
          Positioned(
            bottom: _selectedDonor != null ? 248 : 88,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6),
                  ],
                ),
                child: Text(
                  '${_filteredDonors.length} donors found nearby',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Filter panel
  // ─────────────────────────────────────────────
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 16, color: AppColors.primaryRed),
              const SizedBox(width: 6),
              const Text(
                'Filter Donors',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              // Eligible only toggle
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _showEligibleOnly,
                  onChanged: (val) =>
                      setState(() => _showEligibleOnly = val),
                  activeColor: AppColors.primaryRed,
                ),
              ),
              const Text('Eligible only',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          // Blood group chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _bloodChip(null, 'All'),
                ...AppConstants.bloodGroups
                    .map((bg) => _bloodChip(bg, bg)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloodChip(String? value, String label) {
    final selected = _selectedBloodGroup == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedBloodGroup = value),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryRed
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primaryRed
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight:
              selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Legend
  // ─────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(Colors.red, 'Eligible donor'),
          const SizedBox(height: 4),
          _legendItem(Colors.orange, 'Not eligible'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FAB button
  // ─────────────────────────────────────────────
  Widget _buildFab(
      IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon,
              color: AppColors.primaryRed, size: 22),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Donor info card (bottom sheet style)
  // ─────────────────────────────────────────────
  Widget _buildDonorInfoCard(Map<String, dynamic> donor) {
    final isEligible = donor['isEligible'] as bool;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 12, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                    AppColors.primaryRed.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        size: 30, color: AppColors.primaryRed),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        donor['bloodGroup'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(donor['location'],
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        const Icon(Icons.near_me_outlined,
                            size: 13,
                            color: AppColors.secondaryBlue),
                        const SizedBox(width: 3),
                        Text(donor['distance'],
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryBlue,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.volunteer_activism,
                            size: 13,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${donor['donations']} donations',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isEligible
                                ? AppColors.success.withOpacity(0.12)
                                : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isEligible ? 'Eligible' : 'Not Eligible',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isEligible
                                  ? AppColors.success
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isEligible
                      ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Calling ${donor['name']}...'),
                        backgroundColor:
                        AppColors.secondaryBlue,
                      ),
                    );
                  }
                      : null,
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Call Donor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryBlue,
                    side: BorderSide(
                        color: isEligible
                            ? AppColors.secondaryBlue
                            : Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isEligible
                      ? () {
                    setState(
                            () => _selectedDonor = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Request sent to ${donor['name']}!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                      : null,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEligible
                        ? AppColors.primaryRed
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
