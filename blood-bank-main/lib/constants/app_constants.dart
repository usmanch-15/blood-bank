/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Blood Bank';
  static const String appVersion = '1.0.0';
  
  // User Roles
  static const String roleDonor = 'donor';
  static const String roleReceiver = 'receiver';
  static const String roleAdmin = 'admin';
  
  // Blood Groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  
  // Donation Eligibility
  static const int minDaysBetweenDonations = 90; // 90 days minimum
  
  // Collections (Firestore)
  static const String usersCollection = 'users';
  static const String bloodRequestsCollection = 'blood_requests';
  static const String donationsCollection = 'donations';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String certificatesPath = 'certificates';
  
  // Default Values
  static const String defaultProfileImage = 'https://via.placeholder.com/150';
  
  // Google Maps
  static const double defaultZoom = 14.0;
  static const double nearbyRadius = 10.0; // 10 km radius
}
