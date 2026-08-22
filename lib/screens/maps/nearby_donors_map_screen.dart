import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/donor_model.dart';
import '../../services/geo_location_service.dart';
import '../../services/notification_service.dart';
import '../../utils/eligibility_checker.dart';

/// ✅ REWRITTEN (3rd pass) — Uber/InDrive-style donor search.
///
/// What changed vs the previous version:
///  • Fetches a wide pool of compatible donors ONCE (up to 50km) with
///    distance precomputed, then a radius SLIDER filters that list
///    locally — instant feedback, no re-querying Firestore per drag.
///  • A live floating counter shows "X donors within Ykm" (like a ride
///    count), and updates the moment the slider moves.
///  • Tapping a marker opens a FULL detail sheet — name, blood group,
///    exact distance, eligibility, last donation, phone (via Cloud
///    Function) — not just a name + call button.
///  • A "Notify Donors" button sends a real notification (via
///    NotificationService) to every donor currently shown on the map
///    (i.e. within the selected radius), optionally tied to a specific
///    blood request via [requestId].
class NearbyDonorsMapScreen extends StatefulWidget {
  /// null = show donors of any blood group.
  final String? bloodGroup;

  /// If this map was opened from a specific blood request, pass its id so
  /// "Notify Donors" can tag the notification to that request (and donors
  /// can act on it from their dashboard).
  final String? requestId;

  /// How many units the linked request needs — shown in the notification
  /// text so donors know the urgency at a glance.
  final int? unitsNeeded;

  const NearbyDonorsMapScreen({
    super.key,
    this.bloodGroup,
    this.requestId,
    this.unitsNeeded,
  });

  @override
  State<NearbyDonorsMapScreen> createState() => _NearbyDonorsMapScreenState();
}

class _NearbyDonorsMapScreenState extends State<NearbyDonorsMapScreen> {
  final GeoLocationService _geoService = GeoLocationService();
  final NotificationService _notificationService = NotificationService();
  final MapController _mapController = MapController();

  static const double _maxFetchRadiusKm = 50.0;
  static const List<double> _radiusSteps = [2, 5, 10, 15, 25, 50];

  List<DonorWithDistance> _allDonors = []; // fetched once, up to 50km
  LatLng? _center;
  bool _isLoading = true;
  bool _isNotifying = false;
  String? _errorMessage;

  double _radiusKm = 10.0;
  bool _eligibleOnly = false;

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _geoService.getCurrentLocation();
      final center = LatLng(position.latitude, position.longitude);

      final donors = await _geoService.findCompatibleDonorsWithDistance(
        receiverLat: position.latitude,
        receiverLng: position.longitude,
        bloodGroup: widget.bloodGroup,
        maxRadiusKm: _maxFetchRadiusKm,
      );

      if (!mounted) return;
      setState(() {
        _center = center;
        _allDonors = donors;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(center, 12);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Client-side filter applied on every slider move — no network call.
  List<DonorWithDistance> get _visibleDonors {
    return _allDonors.where((d) {
      if (d.distanceKm > _radiusKm) return false;
      if (_eligibleOnly &&
          !EligibilityChecker.isEligibleForDonation(d.donor.lastDonationDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<String?> _fetchDonorPhone(String donorId) async {
    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('getDonorContact');
      final result = await callable.call({'donorId': donorId});
      return result.data['phoneNumber'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _notifySingleDonor(DonorWithDistance dwd) async {
    final receiverName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'A patient';
    await _notificationService.sendToUser(
      userId: dwd.donor.uid,
      title: widget.bloodGroup != null
          ? 'Urgent: ${widget.bloodGroup} blood needed nearby'
          : 'Blood donation needed nearby',
      body: '$receiverName needs your help'
          '${widget.unitsNeeded != null ? ' (${widget.unitsNeeded} units)' : ''}'
          ' — you are ${dwd.distanceKm.toStringAsFixed(1)} km away.',
      type: 'blood_request',
      relatedId: widget.requestId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent to ${dwd.donor.name}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _confirmAndNotifyAll() async {
    final targets = _visibleDonors;
    if (targets.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: const Text('Notify Donors?'),
        content: Text(
          'This will send a notification to all ${targets.length} donor'
              '${targets.length == 1 ? '' : 's'} within ${_radiusKm.toStringAsFixed(0)} km'
              '${widget.bloodGroup != null ? ' (${widget.bloodGroup} compatible)' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text('Notify ${targets.length} Donors'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isNotifying = true);
    try {
      final receiverName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'A patient';

      // Log who was notified for this request, so the receiver dashboard
      // can later show "notified 12 donors" and donors aren't spammed
      // twice for the same request.
      if (widget.requestId != null) {
        await FirebaseFirestore.instance
            .collection('blood_requests')
            .doc(widget.requestId)
            .update({
          'notifiedDonorIds': targets.map((d) => d.donor.uid).toList(),
          'lastNotifiedAt': FieldValue.serverTimestamp(),
        });
      }

      await _notificationService.sendToUsers(
        userIds: targets.map((d) => d.donor.uid).toList(),
        title: widget.bloodGroup != null
            ? 'Urgent: ${widget.bloodGroup} blood needed nearby'
            : 'Blood donation needed nearby',
        body: '$receiverName needs your help'
            '${widget.unitsNeeded != null ? ' (${widget.unitsNeeded} units)' : ''}'
            ' — within ${_radiusKm.toStringAsFixed(0)} km of your location.',
        type: 'blood_request',
        relatedId: widget.requestId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Notified ${targets.length} donor${targets.length == 1 ? '' : 's'}!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send notifications: $e')),
      );
    } finally {
      if (mounted) setState(() => _isNotifying = false);
    }
  }

  void _showDonorSheet(DonorWithDistance dwd) {
    final donor = dwd.donor;
    final eligible =
    EligibilityChecker.isEligibleForDonation(donor.lastDonationDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                    backgroundImage: donor.profileImageUrl != null
                        ? NetworkImage(donor.profileImageUrl!)
                        : null,
                    child: donor.profileImageUrl == null
                        ? Text(
                      donor.name.isNotEmpty
                          ? donor.name[0].toUpperCase()
                          : 'D',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donor.name.isNotEmpty ? donor.name : 'Donor',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text(
                              '${dwd.distanceKm.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      donor.bloodGroup ?? '—',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statusChip(
                    icon: eligible ? Icons.check_circle : Icons.timer,
                    label: eligible ? 'Eligible to donate' : 'Not yet eligible',
                    color: eligible ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _statusChip(
                    icon: donor.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    label: donor.isAvailable ? 'Available' : 'Unavailable',
                    color: donor.isAvailable
                        ? AppColors.secondaryBlue
                        : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (donor.location != null && donor.location!.isNotEmpty) ...[
                _detailRow(Icons.map_outlined, 'Location', donor.location!),
                const SizedBox(height: 10),
              ],
              if (donor.lastDonationDate != null)
                _detailRow(
                  Icons.history,
                  'Last Donation',
                  '${donor.lastDonationDate!.day}/${donor.lastDonationDate!.month}/${donor.lastDonationDate!.year}',
                ),
              const SizedBox(height: 22),
              FutureBuilder<String?>(
                future: _fetchDonorPhone(donor.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final phone = snapshot.data;
                  return Column(
                    children: [
                      if (phone != null && phone.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call),
                            label: const Text('Call Donor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            onPressed: () =>
                                launchUrl(Uri(scheme: 'tel', path: phone)),
                          ),
                        )
                      else
                        Text(
                          'No phone number on file for this donor.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Notify This Donor'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryRed,
                            side:
                            const BorderSide(color: AppColors.primaryRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _notifySingleDonor(dwd);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
      {required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  void _goToCenter() {
    if (_center != null) _mapController.move(_center!, 13);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bloodGroup != null
              ? 'Donors for ${widget.bloodGroup}'
              : 'Nearby Donors',
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.my_location), onPressed: _goToCenter),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDonors),
        ],
      ),
      body: _buildBody(),
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
              ElevatedButton(onPressed: _loadDonors, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    final center = _center ?? const LatLng(0, 0);
    final donors = _visibleDonors;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.usmanch.bloodbank',
            ),
            // ✅ NEW — a translucent circle showing the currently selected
            // search radius, exactly like the pickup-radius circle in
            // Uber/InDrive's driver-search screens.
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: _radiusKm * 1000, // meters
                  useRadiusInMeter: true,
                  color: AppColors.primaryRed.withOpacity(0.08),
                  borderColor: AppColors.primaryRed.withOpacity(0.4),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle,
                      color: Colors.blue, size: 40),
                ),
                for (final dwd in donors)
                  Marker(
                    point: LatLng(dwd.donor.latitude!, dwd.donor.longitude!),
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => _showDonorSheet(dwd),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: dwd.donor.isAvailable
                                  ? AppColors.primaryRed
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dwd.donor.bloodGroup ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.location_on,
                              color: dwd.donor.isAvailable
                                  ? AppColors.primaryRed
                                  : Colors.grey,
                              size: 30),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),

        // ── Top floating "X donors found" counter (Uber/InDrive style) ──
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _DonorCountBanner(count: donors.length, radiusKm: _radiusKm),
        ),

        // ── Bottom control panel: radius slider + eligible toggle + notify ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomControlPanel(
            radiusKm: _radiusKm,
            radiusSteps: _radiusSteps,
            maxRadius: _maxFetchRadiusKm,
            eligibleOnly: _eligibleOnly,
            donorCount: donors.length,
            isNotifying: _isNotifying,
            onRadiusChanged: (v) => setState(() => _radiusKm = v),
            onEligibleToggle: (v) => setState(() => _eligibleOnly = v),
            onNotifyAll: donors.isEmpty ? null : _confirmAndNotifyAll,
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

// ── Floating count banner ──────────────────────────────────────────────
class _DonorCountBanner extends StatelessWidget {
  final int count;
  final double radiusKm;

  const _DonorCountBanner({required this.count, required this.radiusKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_rounded,
                color: AppColors.primaryRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count donor${count == 1 ? '' : 's'} found',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'within ${radiusKm.toStringAsFixed(0)} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet-style control panel ────────────────────────────────────
class _BottomControlPanel extends StatelessWidget {
  final double radiusKm;
  final List<double> radiusSteps;
  final double maxRadius;
  final bool eligibleOnly;
  final int donorCount;
  final bool isNotifying;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<bool> onEligibleToggle;
  final VoidCallback? onNotifyAll;

  const _BottomControlPanel({
    required this.radiusKm,
    required this.radiusSteps,
    required this.maxRadius,
    required this.eligibleOnly,
    required this.donorCount,
    required this.isNotifying,
    required this.onRadiusChanged,
    required this.onEligibleToggle,
    required this.onNotifyAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.social_distance, size: 16, color: AppColors.primaryRed),
              const SizedBox(width: 6),
              Text(
                'Search radius: ${radiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              const Spacer(),
              // Eligible-only toggle
              GestureDetector(
                onTap: () => onEligibleToggle(!eligibleOnly),
                child: Row(
                  children: [
                    Text('Eligible only',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
                    Switch(
                      value: eligibleOnly,
                      activeColor: AppColors.primaryRed,
                      onChanged: onEligibleToggle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryRed,
              thumbColor: AppColors.primaryRed,
              overlayColor: AppColors.primaryRed.withOpacity(0.15),
              inactiveTrackColor: Colors.grey[200],
            ),
            child: Slider(
              value: radiusKm,
              min: radiusSteps.first,
              max: maxRadius,
              divisions: (maxRadius - radiusSteps.first).toInt(),
              label: '${radiusKm.toStringAsFixed(0)} km',
              onChanged: onRadiusChanged,
            ),
          ),
          // Quick-pick chips — like Uber's quick distance presets.
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: radiusSteps.map((r) {
                final selected = r == radiusKm;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${r.toStringAsFixed(0)} km'),
                    selected: selected,
                    onSelected: (_) => onRadiusChanged(r),
                    selectedColor: AppColors.primaryRed,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      side: BorderSide.none,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isNotifying ? null : onNotifyAll,
              icon: isNotifying
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.notifications_active_rounded),
              label: Text(
                isNotifying
                    ? 'Sending...'
                    : donorCount == 0
                    ? 'No Donors in Range'
                    : 'Notify $donorCount Donor${donorCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}