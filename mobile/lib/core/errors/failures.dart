/// Typed failures the UI layer can switch on.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class ConnectionFailure extends AppFailure {
  const ConnectionFailure([super.message = 'No connection to the server.']);
}

class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure([super.message = 'Your session has expired.']);
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'You do not have access.']);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.details});
  final Map<String, Object?>? details;
}

class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure(
      [super.message = 'Too many requests. Try again shortly.']);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Something went wrong on our side.']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unexpected error.']);
}
