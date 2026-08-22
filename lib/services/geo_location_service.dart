import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donor_model.dart';
import '../utils/location_helper.dart';
import '../constants/app_constants.dart';

class GeoLocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<DonorModel>> findNearbyDonors({
    required double receiverLat,
    required double receiverLng,
    String? bloodGroup, // ✅ CHANGED: nullable — null means "any blood group"
    double radiusKm = 15.0,
  }) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'donor')
        .where('isEligible', isEqualTo: true)
        .where('status', isEqualTo: 'approved');

    if (bloodGroup != null) {
      query = query.where('bloodGroup', isEqualTo: bloodGroup);
    }

    final snapshot = await query.get();

    final List<Map<String, dynamic>> withinRadius = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude']?.toDouble();
      final lng = data['longitude']?.toDouble();
      if (lat == null || lng == null) continue;

      final distance = LocationHelper.calculateDistance(
          receiverLat, receiverLng, lat, lng);
      if (distance <= radiusKm) {
        withinRadius.add({'doc': doc, 'distance': distance});
      }
    }

    withinRadius.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    return withinRadius
        .map((e) {
      final doc = e['doc'] as QueryDocumentSnapshot<Map<String, dynamic>>;
      return DonorModel.fromFirestore(doc.data(), doc.id);
    })
        .toList();
  }

  /// ✅ FIX (Issue #20): auto-expanding donor search. Previously
  /// findNearbyDonors() used a single fixed radius and returned an empty
  /// list if nothing matched, even if donors existed slightly further
  /// away. This tries 15km, then 30km, then 50km before giving up, so a
  /// receiver isn't told "no donors" when donors do exist nearby.
  Future<List<DonorModel>> findNearbyDonorsWithExpand({
    required double receiverLat,
    required double receiverLng,
    String? bloodGroup, // ✅ CHANGED: nullable — null means "any blood group"
    List<double> radiiKm = const [15.0, 30.0, 50.0],
  }) async {
    for (final radius in radiiKm) {
      final donors = await findNearbyDonors(
        receiverLat: receiverLat,
        receiverLng: receiverLng,
        bloodGroup: bloodGroup,
        radiusKm: radius,
      );
      if (donors.isNotEmpty) return donors;
    }
    return [];
  }

  double distanceBetween(
      double lat1, double lng1, double lat2, double lng2) {
    return LocationHelper.calculateDistance(lat1, lng1, lat2, lng2);
  }

  // ── ✅ NEW — Uber/InDrive-style donor search ────────────────────────
  // Which blood groups CAN donate to a given recipient group. Kept local
  // to this service (separate copy from DonorMatchingScreen's own map) so
  // neither screen risks breaking the other.
  static const Map<String, List<String>> compatibleDonorGroups = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
  };

  /// Fetches every approved donor with a compatible blood group (or every
  /// approved donor if [bloodGroup] is null), computes each one's distance
  /// from the receiver, and returns them all sorted nearest-first — up to
  /// [maxRadiusKm]. The UI then filters this ONE fetched list locally as
  /// the user drags a radius slider, instead of re-querying Firestore on
  /// every slider move (same pattern Uber/InDrive use: fetch a wide pool
  /// once, filter client-side for instant slider feedback).
  Future<List<DonorWithDistance>> findCompatibleDonorsWithDistance({
    required double receiverLat,
    required double receiverLng,
    String? bloodGroup,
    double maxRadiusKm = 50.0,
  }) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .where('isDonor', isEqualTo: true)
        .where('status', isEqualTo: 'approved');

    final snapshot = await query.get();
    final compatible =
    bloodGroup != null ? compatibleDonorGroups[bloodGroup] : null;

    final results = <DonorWithDistance>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude']?.toDouble();
      final lng = data['longitude']?.toDouble();
      if (lat == null || lng == null) continue;

      if (compatible != null && !compatible.contains(data['bloodGroup'])) {
        continue;
      }

      final distance =
      LocationHelper.calculateDistance(receiverLat, receiverLng, lat, lng);
      if (distance > maxRadiusKm) continue;

      results.add(DonorWithDistance(
        donor: DonorModel.fromFirestore(data, doc.id),
        distanceKm: distance,
      ));
    }

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }
}

/// ✅ NEW — pairs a donor with their precomputed distance from the
/// receiver, so the map/list UI never has to recompute it repeatedly.
class DonorWithDistance {
  final DonorModel donor;
  final double distanceKm;

  DonorWithDistance({required this.donor, required this.distanceKm});
}