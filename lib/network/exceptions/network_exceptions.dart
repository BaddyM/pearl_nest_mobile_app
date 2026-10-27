/// Network-related exceptions for the Pearl Nest Estates app
/// Provides comprehensive error handling for API requests
library;

// Base network exception
abstract class NetworkException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic data;

  const NetworkException(
    this.message, {
    this.code,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'NetworkException: $message';
}

// Authentication related exceptions
class AuthException extends NetworkException {
  const AuthException(
    super.message, {
    super.code,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'AuthException: $message';
}

// Network connectivity exceptions
class ConnectivityException extends NetworkException {
  const ConnectivityException(super.message, {super.code});

  @override
  String toString() => 'ConnectivityException: $message';
}

// Request timeout exceptions
class TimeoutException extends NetworkException {
  const TimeoutException(super.message, {super.code});

  @override
  String toString() => 'TimeoutException: $message';
}

// Server error exceptions (5xx)
class ServerException extends NetworkException {
  const ServerException(
    super.message, {
    super.code,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'ServerException: $message';
}

// Client error exceptions (4xx)
class ClientException extends NetworkException {
  const ClientException(
    super.message, {
    super.code,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'ClientException: $message';
}

// Validation exceptions
class ValidationException extends NetworkException {
  const ValidationException(super.message, {super.code});

  @override
  String toString() => 'ValidationException: $message';
}

// Parsing exceptions
class ParseException extends NetworkException {
  const ParseException(super.message, {super.code});

  @override
  String toString() => 'ParseException: $message';
}

// Request cancellation exceptions
class CancelException extends NetworkException {
  const CancelException(super.message, {super.code});

  @override
  String toString() => 'CancelException: $message';
}

// Generic unknown exceptions
class UnknownException extends NetworkException {
  const UnknownException(super.message, {super.code});

  @override
  String toString() => 'UnknownException: $message';
}
