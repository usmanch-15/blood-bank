import 'dart:math';

class Haversine {
  static const double _earthRadiusKm = 6371.0;

  /// SDD Algorithm 1 – donor distance calculate karta hai
  static double calculate(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * asin(sqrt(a));
    return _earthRadiusKm * c;
  }

  static double _toRad(double degree) => degree * pi / 180;
}