abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection'])
      : super(message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed'])
      : super(message);
}

class LocationFailure extends Failure {
  const LocationFailure([String message = 'Could not get location'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Local data error']) : super(message);
}
