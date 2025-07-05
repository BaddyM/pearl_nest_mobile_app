/// Network-related exceptions for the Pearl Nest Estates app
/// Provides comprehensive error handling for API requests

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
    String message, {
    String? code,
    int? statusCode,
    dynamic data,
  }) : super(message, code: code, statusCode: statusCode, data: data);

  @override
  String toString() => 'AuthException: $message';
}

// Network connectivity exceptions
class ConnectivityException extends NetworkException {
  const ConnectivityException(String message, {String? code})
      : super(message, code: code);

  @override
  String toString() => 'ConnectivityException: $message';
}

// Request timeout exceptions
class TimeoutException extends NetworkException {
  const TimeoutException(String message, {String? code})
      : super(message, code: code);

  @override
  String toString() => 'TimeoutException: $message';
}

// Server error exceptions (5xx)
class ServerException extends NetworkException {
  const ServerException(
    String message, {
    String? code,
    int? statusCode,
    dynamic data,
  }) : super(message, code: code, statusCode: statusCode, data: data);

  @override
  String toString() => 'ServerException: $message';
}

// Client error exceptions (4xx)
class ClientException extends NetworkException {
  const ClientException(
    String message, {
    String? code,
    int? statusCode,
    dynamic data,
  }) : super(message, code: code, statusCode: statusCode, data: data);

  @override
  String toString() => 'ClientException: $message';
}

// Validation exceptions
class ValidationException extends NetworkException {
  const ValidationException(String message, {String? code})
      : super(message, code: code);

  @override
  String toString() => 'ValidationException: $message';
}

// Parsing exceptions
class ParseException extends NetworkException {
  const ParseException(String message, {String? code})
      : super(message, code: code);

  @override
  String toString() => 'ParseException: $message';
}

// Request cancellation exceptions
class CancelException extends NetworkException {
  const CancelException(String message, {String? code})
      : super(message, code: code);

  @override
  String toString() => 'CancelException: $message';
}

// Generic unknown exceptions
class UnknownException extends NetworkException {
  const UnknownException(String message, {String? code})
      : super(message, code: code);

  @override
  String toString() => 'UnknownException: $message';
}
