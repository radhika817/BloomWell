/// Base exception for BloomWell API communication.
/// Never displays raw server secrets or traces to users.
abstract class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.requestId,
    this.statusCode,
  });

  final String message;
  final String? code;
  final String? requestId;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(code: $code, message: $message, requestId: $requestId)';
}

/// Thrown when login credentials (email or password) are incorrect.
class InvalidCredentialsException extends ApiException {
  const InvalidCredentialsException({
    super.message = 'Invalid email or password.',
    super.code = 'INVALID_CREDENTIALS',
    super.requestId,
    super.statusCode = 401,
  });
}

/// Thrown when attempting to register with an email that is already registered.
class EmailAlreadyRegisteredException extends ApiException {
  const EmailAlreadyRegisteredException({
    super.message = 'An account with this email address already exists.',
    super.code = 'EMAIL_ALREADY_REGISTERED',
    super.requestId,
    super.statusCode = 409,
  });
}

/// Thrown when an endpoint rate limit is hit (HTTP 429).
class RateLimitException extends ApiException {
  const RateLimitException({
    required this.retryAfterSeconds,
    super.message = 'Too many requests. Please wait before trying again.',
    super.code = 'RATE_LIMITED',
    super.requestId,
    super.statusCode = 429,
  });

  final int retryAfterSeconds;
}

/// Thrown when request validation fails (HTTP 422).
class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    this.details,
    super.code = 'VALIDATION_ERROR',
    super.requestId,
    super.statusCode = 422,
  });

  final dynamic details;
}

/// Thrown when an access token or session is expired/invalid.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Authentication required or session expired.',
    super.code = 'UNAUTHORIZED',
    super.requestId,
    super.statusCode = 401,
  });
}

/// Thrown when network connection fails or times out.
class NetworkException extends ApiException {
  const NetworkException({
    super.message =
        'Unable to connect to the server. Please check your internet connection.',
    super.code = 'NETWORK_ERROR',
  });
}

/// Thrown when a 5xx server error occurs.
class ServerException extends ApiException {
  const ServerException({
    super.message = 'A server error occurred. Please try again later.',
    super.code = 'SERVER_ERROR',
    super.requestId,
    super.statusCode = 500,
  });
}

/// Thrown when an endpoint returns 403 because cycle tracking is disabled.
class CycleTrackingDisabledException extends ApiException {
  const CycleTrackingDisabledException({
    super.message = 'Cycle tracking is disabled for this account.',
    super.code = 'cycle_tracking_disabled',
    super.requestId,
    super.statusCode = 403,
  });
}

/// Thrown when a study plan already exists for the week and replace is false (HTTP 409).
class PlanExistsException extends ApiException {
  const PlanExistsException({
    super.message = 'A study plan already exists for this week.',
    super.code = 'plan_exists',
    super.requestId,
    super.statusCode = 409,
  });
}

/// Thrown when planner cycle consent requires cycle tracking to be enabled (HTTP 409).
class CycleTrackingRequiredException extends ApiException {
  const CycleTrackingRequiredException({
    super.message =
        'Cycle tracking must be enabled before planner cycle consent can be granted.',
    super.code = 'cycle_tracking_required',
    super.requestId,
    super.statusCode = 409,
  });
}

/// Thrown when a requested resource is not found (HTTP 404).
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.requestId,
    super.statusCode = 404,
  });
}
