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
    required String bloodGroup,
    double radiusKm = 15.0,
    bool wholeCountry = false, // ✅ NEW: "puri Pakistan" filter option
  }) async {
    // ✅ FIX: 'role' field ab session ke hisaab se badal sakta hai (jab
    // user donor <-> receiver switch karta hai), is liye ye query 'isDonor'
    // (permanent capability flag) aur 'isAvailable' (persisted toggle) use
    // karti hai. Eligibility bhi query-time par 'nextEligibleDate' se check
    // hoti hai — client ke app kholne ka intezar nahi karna padta.
    final now = Timestamp.now();
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .where('isDonor', isEqualTo: true)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .where('isAvailable', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .get();

    final List<Map<String, dynamic>> withinRadius = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Eligibility check: agar nextEligibleDate set hai to wo guzar chuki
      // honi chahiye. Purane data (nextEligibleDate na ho) ke liye
      // backward-compatible fallback: lastDonationDate na ho to eligible.
      final nextEligible = data['nextEligibleDate'] as Timestamp?;
      if (nextEligible != null && nextEligible.compareTo(now) > 0) {
        continue; // abhi 90 din poore nahi huay
      }

      final lat = data['latitude']?.toDouble();
      final lng = data['longitude']?.toDouble();
      if (lat == null || lng == null) continue;

      final distance = LocationHelper.calculateDistance(
          receiverLat, receiverLng, lat, lng);
      if (wholeCountry || distance <= radiusKm) {
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

  double distanceBetween(
      double lat1, double lng1, double lat2, double lng2) {
    return LocationHelper.calculateDistance(lat1, lng1, lat2, lng2);
  }
}