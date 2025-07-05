import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class ApiClient {
  static Dio? _dio;
  static String? _authToken;
  static VoidCallback? onTokenExpired;

  static Future<void> initialize() async {
    debugPrint('ApiClient: Initializing...');
    
    final baseUrl = AppConfig.getCurrentBaseUrl();
    debugPrint('ApiClient: Using base URL: $baseUrl');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Load saved auth token
    await _loadSavedToken();
    
    debugPrint('ApiClient: Initialization complete');
  }

  static Future<void> _loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (_authToken != null) {
        debugPrint('ApiClient: Loaded saved auth token');
      }
    } catch (e) {
      debugPrint('ApiClient: Error loading saved token: $e');
    }
  }

  static void setAuthToken(String? token) {
    _authToken = token;
    debugPrint('ApiClient: Auth token ${token != null ? 'set' : 'cleared'}');
  }

  static String? get currentAuthToken => _authToken;

  static Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  static void _logRequest(String method, String endpoint, {Map<String, dynamic>? data, Map<String, String>? headers}) {
    final baseUrl = _dio?.options.baseUrl ?? 'unknown';
    final fullUrl = '$baseUrl$endpoint';
    debugPrint('ApiClient: [$method] $fullUrl');
    if (headers != null && headers.isNotEmpty) {
      final safeHeaders = Map<String, String>.from(headers);
      if (safeHeaders.containsKey('Authorization')) {
        safeHeaders['Authorization'] = 'Bearer ***';
      }
      debugPrint('ApiClient: Headers: $safeHeaders');
    }
    if (data != null && data.isNotEmpty) {
      debugPrint('ApiClient: Request data: $data');
    }
  }

  static void _logResponse(Response response) {
    final fullUrl = '${response.requestOptions.baseUrl}${response.requestOptions.path}';
    debugPrint('ApiClient: Response from $fullUrl - Status: ${response.statusCode}');
    debugPrint('ApiClient: Response data: ${response.data}');
  }

  static void _logError(DioException error) {
    final fullUrl = '${error.requestOptions.baseUrl}${error.requestOptions.path}';
    debugPrint('ApiClient: Error for $fullUrl - Type: ${error.type}, Message: ${error.message}');
    if (error.response != null) {
      debugPrint('ApiClient: Error status: ${error.response!.statusCode}');
      debugPrint('ApiClient: Error data: ${error.response!.data}');
    }
  }

  static String _handleError(DioException error) {
    debugPrint('ApiClient: Handling error...');
    
    // Check for token expiration (401 status)
    if (error.response?.statusCode == 401) {
      debugPrint('ApiClient: Token expired, calling token expiration handler');
      onTokenExpired?.call();
      return 'Your session has expired. Please log in again.';
    }

    // Network/connection errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    // HTTP errors with response
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final responseData = error.response!.data;

      // Try to extract error message from JSON response
      String? errorMessage;
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] as String? ?? 
                      responseData['error'] as String? ??
                      responseData['detail'] as String?;
      } else if (responseData is String) {
        try {
          final decoded = jsonDecode(responseData);
          if (decoded is Map<String, dynamic>) {
            errorMessage = decoded['message'] as String? ?? 
                          decoded['error'] as String? ??
                          decoded['detail'] as String?;
          }
        } catch (_) {
          // Response is not JSON, use as is if it's reasonable length
          if (responseData.length < 200) {
            errorMessage = responseData;
          }
        }
      }

      switch (statusCode) {
        case 400:
          return errorMessage ?? 'Invalid request. Please check your input.';
        case 403:
          return errorMessage ?? 'Access denied. You don\'t have permission to perform this action.';
        case 404:
          return errorMessage ?? 'The requested resource was not found.';
        case 409:
          return errorMessage ?? 'Conflict occurred. The resource already exists or there\'s a data conflict.';
        case 422:
          return errorMessage ?? 'Validation error. Please check your input.';
        case 429:
          return errorMessage ?? 'Too many requests. Please wait a moment and try again.';
        case 500:
          return errorMessage ?? 'Server error. Please try again later.';
        case 502:
          return 'Bad gateway. The server is temporarily unavailable.';
        case 503:
          return 'Service unavailable. Please try again later.';
        default:
          return errorMessage ?? 'An error occurred (Code: $statusCode). Please try again.';
      }
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again.';
  }

  static Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call ApiClient.initialize() first.');
    }

    try {
      final headers = _getHeaders();
      _logRequest('GET', endpoint, headers: headers);

      final response = await _dio!.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      _logResponse(response);
      return response;
    } on DioException catch (e) {
      _logError(e);
      throw Exception(_handleError(e));
    }
  }

  static Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call ApiClient.initialize() first.');
    }

    try {
      final headers = _getHeaders();
      _logRequest('POST', endpoint, data: data, headers: headers);

      final response = await _dio!.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      _logResponse(response);
      return response;
    } on DioException catch (e) {
      _logError(e);
      throw Exception(_handleError(e));
    }
  }

  static Future<Response> put(String endpoint, Map<String, dynamic> data) async {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call ApiClient.initialize() first.');
    }

    try {
      final headers = _getHeaders();
      _logRequest('PUT', endpoint, data: data, headers: headers);

      final response = await _dio!.put(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      _logResponse(response);
      return response;
    } on DioException catch (e) {
      _logError(e);
      throw Exception(_handleError(e));
    }
  }

  static Future<Response> delete(String endpoint) async {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call ApiClient.initialize() first.');
    }

    try {
      final headers = _getHeaders();
      _logRequest('DELETE', endpoint, headers: headers);

      final response = await _dio!.delete(
        endpoint,
        options: Options(headers: headers),
      );

      _logResponse(response);
      return response;
    } on DioException catch (e) {
      _logError(e);
      throw Exception(_handleError(e));
    }
  }

  static Future<Response> postMultipart(String endpoint, FormData formData) async {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call ApiClient.initialize() first.');
    }

    try {
      final headers = _getHeaders(additionalHeaders: {
        'Content-Type': 'multipart/form-data',
      });
      
      _logRequest('POST (multipart)', endpoint, headers: headers);
      debugPrint('ApiClient: FormData fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      debugPrint('ApiClient: FormData files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').join(', ')}');

      final response = await _dio!.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );

      _logResponse(response);
      return response;
    } on DioException catch (e) {
      _logError(e);
      throw Exception(_handleError(e));
    }
  }
}
