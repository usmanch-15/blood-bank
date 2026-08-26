import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Typed result for a single route lookup.
class RouteEta {
  final int durationSeconds;
  final int distanceMeters;

  const RouteEta({required this.durationSeconds, required this.distanceMeters});

  /// e.g. "12 min", "1h 5min"
  String get humanDuration {
    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}min';
  }

  /// e.g. "4.8 km", "850 m"
  String get humanDistance {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

/// Free, no-API-key routing/ETA using the public OSRM demo server.
///
/// Replaces the old `maps_service.dart`, which called Google's paid
/// Distance Matrix API (billing required) — this project already switched
/// its map *display* to flutter_map/OpenStreetMap for the same
/// no-cost/no-key reason (see pubspec.yaml). OSRM's public demo server has
/// no official uptime SLA, so every call has a timeout + graceful failure
/// path; callers should treat a null result as "ETA unavailable" and hide
/// the ETA UI rather than erroring the whole screen.
class OsrmRoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org';
  static const Duration _timeout = Duration(seconds: 8);

  // Simple in-memory de-dupe so rapid rebuilds (e.g. a list of donor
  // markers) don't fire duplicate requests for the same coordinate pair
  // within a short window. Not a persistent cache — just avoids bursts.
  final Map<String, Future<RouteEta?>> _inFlight = {};

  /// Returns driving distance/duration between two points, or null if the
  /// route couldn't be computed (no internet, timeout, invalid
  /// coordinates, no route found, etc). Never throws.
  Future<RouteEta?> getDrivingEta({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (!_isValidCoordinate(originLat, originLng) ||
        !_isValidCoordinate(destLat, destLng)) {
      return null;
    }

    final key =
        '${originLat.toStringAsFixed(4)},${originLng.toStringAsFixed(4)}'
        '->${destLat.toStringAsFixed(4)},${destLng.toStringAsFixed(4)}';

    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _fetchRoute(originLat, originLng, destLat, destLng);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<RouteEta?> _fetchRoute(
      double originLat,
      double originLng,
      double destLat,
      double destLng,
      ) async {
    try {
      // OSRM expects coordinates as longitude,latitude — the opposite
      // order from how most of this app stores lat/lng.
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/'
            '$originLng,$originLat;$destLng,$destLat'
            '?overview=false',
      );

      final response = await http.get(url).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final duration = route['duration'];
      final distance = route['distance'];
      if (duration == null || distance == null) return null;

      return RouteEta(
        durationSeconds: (duration as num).round(),
        distanceMeters: (distance as num).round(),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      // No internet, malformed response, DNS failure, etc — ETA is a
      // nice-to-have, never worth crashing or erroring the screen over.
      return null;
    }
  }

  bool _isValidCoordinate(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}