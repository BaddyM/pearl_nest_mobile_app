import 'package:pearlnest/models/user.dart';

/// Generic response wrapper for API calls
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final String? code;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.code,
    this.statusCode,
  });

  /// Success response
  factory ApiResponse.success({
    T? data,
    String message = 'Success',
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Error response
  factory ApiResponse.error({
    required String message,
    String? code,
    int? statusCode,
    T? data,
  }) {
    return ApiResponse(
      success: false,
      data: data,
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  /// Network error response
  factory ApiResponse.networkError({
    String message = 'Network error. Please check your connection.',
  }) {
    return ApiResponse(
      success: false,
      message: message,
      code: 'NETWORK_ERROR',
    );
  }

  /// Token expired response
  factory ApiResponse.tokenExpired({
    String message = 'Session expired. Please login again.',
  }) {
    return ApiResponse(
      success: false,
      message: message,
      code: 'TOKEN_EXPIRED',
      statusCode: 401,
    );
  }

  /// Validation error response
  factory ApiResponse.validationError({
    required String message,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      code: 'VALIDATION_ERROR',
      statusCode: 400,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, code: $code, statusCode: $statusCode}';
  }
}

/// Specific response types for authentication
class AuthResponse extends ApiResponse<AuthData> {
  const AuthResponse({
    required super.success,
    super.data,
    required super.message,
    super.code,
    super.statusCode,
  });

  factory AuthResponse.success({
    AuthData? data,
    String message = 'Success',
    int? statusCode,
  }) {
    return AuthResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory AuthResponse.error({
    required String message,
    String? code,
    int? statusCode,
  }) {
    return AuthResponse(
      success: false,
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  factory AuthResponse.tokenExpired() {
    return AuthResponse(
      success: false,
      message: 'Session expired. Please login again.',
      code: 'TOKEN_EXPIRED',
      statusCode: 401,
    );
  }
}

/// Data structure for authentication responses
class AuthData {
  final String? token;
  final User? user;
  final int? expiresIn;
  final bool? requiresVerification;

  const AuthData({
    this.token,
    this.user,
    this.expiresIn,
    this.requiresVerification,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      expiresIn: json['expiresIn'],
      requiresVerification: json['requiresVerification'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user?.toJson(),
      'expiresIn': expiresIn,
      'requiresVerification': requiresVerification,
    };
  }
}
