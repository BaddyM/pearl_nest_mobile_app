import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/apis/auth_service.dart';

class NotificationApiService {
  // Logging helper
  static void _logRequest(String endpoint, Map<String, dynamic>? data, {String? token}) {
    if (kDebugMode) {
      // //debugPrint('🚀 NOTIFICATION REQUEST: $endpoint');
      if (data != null) {
        // //debugPrint('📤 Request Data: ${jsonEncode(data)}');
      }
      if (token != null) {
        // //debugPrint('🔑 Token: ${token.substring(0, 10)}...');
      }
    }
  }

  static void _logResponse(String endpoint, Response response) {
    if (kDebugMode) {
      // //debugPrint('📥 NOTIFICATION RESPONSE: $endpoint');
      // //debugPrint('📊 Status Code: ${response.statusCode}');
      // //debugPrint('📝 Response Body: ${jsonEncode(response.data)}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      // //debugPrint('❌ NOTIFICATION ERROR [$operation]: $error');
      if (error is Error) {
        // //debugPrint('🔍 Stack Trace: ${error.stackTrace}');
      }
    }
  }

  /// Fetch notifications list from the server
  static Future<Map<String, dynamic>> fetchNotifications({
    int page = 1,
    int limit = 20,
    String? filter, // 'all', 'unread', 'read'
    String? type, // notification type filter
  }) async {
    try {
      // Get current token
      final token = await AuthService.getCurrentToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'code': 'NOT_AUTHENTICATED',
          'notifications': [],
        };
      }

      // Get current user ID
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        return {
          'success': false,
          'message': 'User ID not found. Please login again.',
          'code': 'USER_ID_MISSING',
          'notifications': [],
        };
      }

      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (filter != null && filter.isNotEmpty) {
        queryParams['status'] = filter; // 'read', 'unread', 'all'
      }

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      _logRequest('/notifications/list', queryParams, token: token);

      // Set the auth token for the request
      ApiClient.setAuthToken(token);

      // Make the API call
      final response = await ApiClient.get('/notifications/list', queryParameters: queryParams);
      _logResponse('/notifications/list', response);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Extract notifications data
        final notificationsData = responseData['data'] as List<dynamic>? ?? [];
        final totalCount = responseData['total'] ?? 0;
        final currentPage = responseData['page'] ?? page;
        final totalPages = responseData['totalPages'] ?? 1;

        return {
          'success': true,
          'notifications': notificationsData,
          'total': totalCount,
          'page': currentPage,
          'totalPages': totalPages,
          'hasMore': currentPage < totalPages,
          'message': responseData['message'] ?? 'Notifications fetched successfully',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'code': 'TOKEN_EXPIRED',
          'notifications': [],
        };
      } else {
        final errorData = response.data as Map<String, dynamic>? ?? {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch notifications',
          'code': 'FETCH_FAILED',
          'notifications': [],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logError('fetchNotifications', e);

      String message;
      String code;

      if (e.toString().contains('SocketException') || e.toString().contains('Please check your internet connection')) {
        message = 'No internet connection. Please check your network.';
        code = 'NO_INTERNET';
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('Connection timeout')) {
        message = 'Request timed out. Please try again.';
        code = 'TIMEOUT';
      } else {
        message = 'An unexpected error occurred. Please try again.';
        code = 'UNKNOWN_ERROR';
      }

      return {
        'success': false,
        'message': message,
        'code': code,
        'notifications': [],
      };
    }
  }

  /// Mark a notification as read
  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getCurrentToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'code': 'NOT_AUTHENTICATED',
        };
      }

      _logRequest('/notifications/read/$notificationId', {}, token: token);

      ApiClient.setAuthToken(token);

      final response = await ApiClient.patch('/notifications/read/$notificationId', {});
      _logResponse('/notifications/read/$notificationId', response);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification marked as read',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data as Map<String, dynamic>? ?? {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to mark notification as read',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logError('markAsRead', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Mark all notifications as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await AuthService.getCurrentToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'code': 'NOT_AUTHENTICATED',
        };
      }

      _logRequest('/notifications/mark-all-read', {}, token: token);

      ApiClient.setAuthToken(token);

      final response = await ApiClient.patch('/notifications/mark-all-read', {});
      _logResponse('/notifications/mark-all-read', response);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': responseData['message'] ?? 'All notifications marked as read',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data as Map<String, dynamic>? ?? {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to mark all notifications as read',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logError('markAllAsRead', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Delete a notification
  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final token = await AuthService.getCurrentToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'code': 'NOT_AUTHENTICATED',
        };
      }

      _logRequest('/notifications/$notificationId', {}, token: token);

      ApiClient.setAuthToken(token);

      final response = await ApiClient.delete('/notifications/delete/$notificationId');
      _logResponse('/notifications/$notificationId', response);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Notification deleted successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data as Map<String, dynamic>? ?? {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete notification',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logError('deleteNotification', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }
}
