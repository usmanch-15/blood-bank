class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'No internet connection'])
      : super(message, code: 'NETWORK_ERROR');
}

class FirestoreException extends AppException {
  FirestoreException([String message = 'Database error'])
      : super(message, code: 'FIRESTORE_ERROR');
}

class AuthException extends AppException {
  AuthException([String message = 'Authentication failed'])
      : super(message, code: 'AUTH_ERROR');
}

class LocationException extends AppException {
  LocationException([String message = 'Location access denied'])
      : super(message, code: 'LOCATION_ERROR');
}