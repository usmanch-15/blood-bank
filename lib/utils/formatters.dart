class AppFormatters {
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k pts';
    return '$points pts';
  }

  static String formatBloodGroup(String bg) => bg.toUpperCase().trim();

  static String formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '+92${phone.substring(1)}';
    }
    return phone;
  }
}