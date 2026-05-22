import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  static const double earthRadiusKm = 6371.0;

  // ── NEW: GPS + Geocoding ─────────────────────────────────────────────────

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String?> getAddressFromCoordinates(
      double latitude,
      double longitude,
      ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return [p.street, p.subLocality, p.locality, p.country]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
    } catch (_) {
      return null;
    }
  }

  // ── Existing distance helpers ────────────────────────────────────────────

  static double calculateDistance(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusKm * 2 * asin(sqrt(a));
  }

  static double _toRad(double degree) => degree * pi / 180;

  static bool isWithinRadius(
      double lat1, double lon1,
      double lat2, double lon2,
      double radiusKm,
      ) =>
      calculateDistance(lat1, lon1, lat2, lon2) <= radiusKm;
}