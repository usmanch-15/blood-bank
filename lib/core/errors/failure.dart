abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Could not get location']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error']);
}
