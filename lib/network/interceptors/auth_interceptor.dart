import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication interceptor for automatic token injection and 401 handling
class AuthInterceptor extends Interceptor {
  static Function()? onTokenExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Add Authorization header if token exists and not already present
      if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      if (kDebugMode) {
        debugPrint('🔐 Auth: Token ${token != null ? "added" : "not available"} for ${options.method} ${options.path}');
      }

      handler.next(options);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Auth Interceptor Error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized responses
    if (err.response?.statusCode == 401) {
      await _handleTokenExpired(err.requestOptions.path);
    }

    handler.next(err);
  }

  /// Handle token expiry by clearing local storage and triggering callback
  static Future<void> _handleTokenExpired(String endpoint) async {
    if (kDebugMode) {
      debugPrint('🔒 401 Unauthorized received for $endpoint - Token expired, logging out user');
    }

    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('auth_token'),
        prefs.remove('user_data'),
        prefs.remove('last_login'),
        prefs.remove('token_expiry'),
      ]);

      if (kDebugMode) {
        debugPrint('🧹 Local auth data cleared due to token expiry');
      }

      // Trigger logout callback if available
      if (onTokenExpired != null) {
        try {
          onTokenExpired!();
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Error in token expired callback: $e');
            debugPrint('❌ Stack trace: $stackTrace');
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error handling token expiry: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
    }
  }
}
