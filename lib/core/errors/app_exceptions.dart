class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException([super.message = 'No internet connection'])
    : super(code: 'NETWORK_ERROR');
}

class FirestoreException extends AppException {
  FirestoreException([super.message = 'Database error'])
    : super(code: 'FIRESTORE_ERROR');
}

class AuthException extends AppException {
  AuthException([super.message = 'Authentication failed'])
    : super(code: 'AUTH_ERROR');
}

class LocationException extends AppException {
  LocationException([super.message = 'Location access denied'])
    : super(code: 'LOCATION_ERROR');
}
