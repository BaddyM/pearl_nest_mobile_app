import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

// Custom response class to maintain compatibility with existing code
class ApiResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });
}

class ApiService {
  static late Dio _dio;
  static String get baseUrl => AppConfig.getCurrentBaseUrl();

  // Callback for handling token expiry - will be set by AuthProvider
  static Function()? onTokenExpired;

  // Initialize Dio instance
  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add request interceptor for logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logRequest(options.method, options.path, data: options.data, token: options.headers['Authorization']?.toString());
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response.requestOptions.method, response.requestOptions.path, response);
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _handleUnauthorized(error.requestOptions.path);
        }
        _logError(error.requestOptions.method, error.requestOptions.path, error);
        handler.next(error);
      },
    ));
  }

  // Helper to log requests and responses
  static void _logRequest(String method, String endpoint, {dynamic data, String? token}) {
    if (kDebugMode) {
      //debugPrint('🌐 API $method: $baseUrl$endpoint');
      if (data != null) {
        if (data is FormData) {
          //debugPrint('📤 Request Data: FormData (multipart)');
          // Log form fields without sensitive data
          for (var field in data.fields) {
            if (field.key != 'password' && field.key != 'token') {
              //debugPrint('  📋 ${field.key}: ${field.value}');
            }
          }
          //debugPrint('  📎 Files: ${data.files.length} file(s)');
          for (var file in data.files) {
            //debugPrint('  📄 File: ${file.key} -> ${file.value.filename}');
          }
        } else {
          // Don't log sensitive data like passwords
          dynamic sanitizedData = data;
          if (data is Map<String, dynamic>) {
            sanitizedData = Map<String, dynamic>.from(data);
            if (sanitizedData.containsKey('password')) {
              sanitizedData['password'] = '[REDACTED]';
            }
            if (sanitizedData.containsKey('currentPassword')) {
              sanitizedData['currentPassword'] = '[REDACTED]';
            }
            if (sanitizedData.containsKey('newPassword')) {
              sanitizedData['newPassword'] = '[REDACTED]';
            }
          }
          //debugPrint('📤 Request Data: ${jsonEncode(sanitizedData)}');
        }
      }
      if (token != null) {
        // Extract just the token part from "Bearer token"
        final tokenValue = token.startsWith('Bearer ') ? token.substring(7) : token;
        if (tokenValue.length > 10) {
          //debugPrint('🔑 Token: ${tokenValue.substring(0, 10)}...');
        }
      }
    }
  }

  static void _logResponse(String method, String endpoint, Response response) {
    if (kDebugMode) {
      //debugPrint('📥 API $method Response: $endpoint');
      //debugPrint('📊 Status Code: ${response.statusCode}');
      //debugPrint('📋 Headers: ${response.headers}');

      // Log response body (be careful with sensitive data)
      try {
        if (response.data is Map<String, dynamic>) {
          final sanitizedResponse = Map<String, dynamic>.from(response.data);
          if (sanitizedResponse.containsKey('token')) {
            final token = sanitizedResponse['token'];
            if (token is String && token.isNotEmpty) {
              sanitizedResponse['token'] = '${token.substring(0, 10)}...';
            }
          }
          //debugPrint('📝 Response Body: ${jsonEncode(sanitizedResponse)}');
        } else {
          //debugPrint('📝 Response Body: ${response.data}');
        }
      } catch (e) {
        //debugPrint('📝 Response Body (raw): ${response.data}');
      }
    }
  }

  static void _logError(String method, String endpoint, DioException error) {
    if (kDebugMode) {
      //debugPrint('❌ API $method Error: $endpoint');
      //debugPrint('💥 Error Type: ${error.type}');
      //debugPrint('📊 Status Code: ${error.response?.statusCode}');
      //debugPrint('📝 Error Message: ${error.message}');
      if (error.response?.data != null) {
        //debugPrint('📋 Error Response: ${error.response!.data}');
      }
    }
  }

  // Private method to handle 401 responses and automatic logout
  static Future<void> _handleUnauthorized(String endpoint) async {
    if (kDebugMode) {
      //debugPrint('🔒 401 Unauthorized received for $endpoint - Token expired, logging out user');
    }

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('auth_token'),
      prefs.remove('user_data'),
      prefs.remove('last_login'),
      prefs.remove('token_expiry'),
    ]);

    if (kDebugMode) {
      //debugPrint('🧹 Local auth data cleared due to token expiry');
    }

    // Trigger logout callback if available
    if (onTokenExpired != null) {
      try {
        onTokenExpired!();
      } catch (e) {
        if (kDebugMode) {
          //debugPrint('❌ Error in token expired callback: $e');
        }
      }
    }
  }

  // Convert Dio response to ApiResponse for backward compatibility
  static ApiResponse _convertResponse(Response response) {
    return ApiResponse(
      statusCode: response.statusCode ?? 200,
      body: response.data is String ? response.data : jsonEncode(response.data),
      headers: response.headers.map.map((key, value) => MapEntry(key, value.join(', '))),
    );
  }

  // Handle Dio errors and convert them to appropriate exceptions
  static Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return Exception('Network error. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error occurred';
        return Exception('HTTP $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
      default:
        return Exception('Network error: ${error.message}');
    }
  }

  static Future<ApiResponse> post(String endpoint, Map<String, dynamic> data) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final response = await _dio.post(endpoint, data: data);
      return _convertResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ POST $endpoint error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiResponse> get(String endpoint) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await _dio.get(endpoint, options: options);
      return _convertResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ GET $endpoint error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  // GET request with specific token
  static Future<ApiResponse> getWithToken(String endpoint, String token) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final options = Options(
        headers: {'Authorization': 'Bearer $token'},
      );

      final response = await _dio.get(endpoint, options: options);
      return _convertResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ GET (with token) $endpoint error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  // POST request with specific token
  static Future<ApiResponse> postWithToken(String endpoint, Map<String, dynamic> data, String token) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final options = Options(
        headers: {'Authorization': 'Bearer $token'},
      );

      final response = await _dio.post(endpoint, data: data, options: options);
      return _convertResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ POST (with token) $endpoint error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  // PUT request with token
  static Future<ApiResponse> put(String endpoint, Map<String, dynamic> data) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await _dio.put(endpoint, data: data, options: options);
      return _convertResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ PUT $endpoint error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  // DELETE request with token
  static Future<ApiResponse> delete(String endpoint) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await _dio.delete(endpoint, options: options);
      return _convertResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ DELETE $endpoint error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  // Helper method to check if user is authenticated
  static Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Helper method to get current token
  static Future<String?> getCurrentToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  // File upload method
  static Future<ApiResponse> uploadFile(String endpoint, String filePath, {String? title}) async {
    try {
      if (_dio.options.baseUrl != baseUrl) {
        _dio.options.baseUrl = baseUrl;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Create multipart file
      String fileName = filePath.split('/').last;
      MultipartFile multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      // Create form data - matching your API specification
      FormData formData = FormData.fromMap({
        'file': multipartFile,
        if (title != null) 'title': title,
      });

      // Don't set Content-Type header - let Dio handle it for multipart
      final options = Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        //debugPrint('📤 Uploading file: $fileName');
        //debugPrint('📁 File path: $filePath');
        //debugPrint('📋 Title: $title');
        //debugPrint('🔑 Has token: ${token != null}');
      }

      final response = await _dio.post(endpoint, data: formData, options: options);

      if (kDebugMode) {
        //debugPrint('✅ Upload response status: ${response.statusCode}');
        //debugPrint('📝 Upload response data: ${response.data}');
      }

      return _convertResponse(response);
    } on DioException catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ File upload DioException: ${e.type}');
        //debugPrint('📊 Status Code: ${e.response?.statusCode}');
        //debugPrint('📝 Error Data: ${e.response?.data}');
        //debugPrint('💥 Error Message: ${e.message}');
        //debugPrint('🔗 Request URI: ${e.requestOptions.uri}');
        //debugPrint('📋 Request Headers: ${e.requestOptions.headers}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('❌ FILE UPLOAD $endpoint error: $e');
        //debugPrint('🔍 Error type: ${e.runtimeType}');
      }
      throw Exception('Network error: $e');
    }
  }
}
