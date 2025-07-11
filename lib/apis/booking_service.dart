import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/apis/app_config.dart';
import 'package:pearlnest/models/booking.dart';

// Custom exceptions for better error handling
class BookingException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  BookingException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'BookingException: $message';
}

class BookingService {
  // Logging helper
  static void _logRequest(String endpoint, Map<String, dynamic>? data) {
    if (kDebugMode) {
      debugPrint('🏨 BOOKING REQUEST: $endpoint');
      if (data != null) {
        debugPrint('🏨 Request data: $data');
      }
    }
  }

  static void _logResponse(String endpoint, Response response) {
    if (kDebugMode) {
      debugPrint('📝 BOOKING RESPONSE [$endpoint]: Status ${response.statusCode}');
      debugPrint('📝 Response Body: ${response.data}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      debugPrint('❌ BOOKING ERROR [$operation]: $error');
      if (error is DioException) {
        debugPrint('❌ Response status: ${error.response?.statusCode}');
        debugPrint('❌ Response data: ${error.response?.data}');
      }
    }
  }

  /// Create a new booking
  static Future<Map<String, dynamic>> createBooking({
    required String propertyId,
    required String checkInDate,
    required String checkOutDate,
  }) async {
    try {
      final requestData = {
        'propertyId': propertyId,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
      };

      _logRequest('/booking/create', requestData);

      final response = await ApiClient.post('/booking/create', requestData);
      
      _logResponse('/booking/create', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Booking created successfully',
          'data': response.data,
        };
      } else {
        throw BookingException(
          'Failed to create booking: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('create booking', e);
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw BookingException('Connection timeout. Please check your internet connection.');
      }
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'Invalid booking data provided';
        
        if (errorData != null && errorData['message'] != null) {
          if (errorData['message'] is List) {
            // Handle list of error messages
            final messages = errorData['message'] as List;
            errorMessage = messages.join(', ');
          } else {
            errorMessage = errorData['message'].toString();
          }
        }
        
        throw BookingException(errorMessage, statusCode: 400);
      }
      
      if (e.response?.statusCode == 401) {
        throw BookingException('Authentication required', statusCode: 401);
      }
      
      if (e.response?.statusCode == 403) {
        throw BookingException('Not authorized to create bookings', statusCode: 403);
      }

      if (e.response?.statusCode == 404) {
        throw BookingException('Property not found', statusCode: 404);
      }

      if (e.response?.statusCode == 409) {
        throw BookingException('Property is not available for the selected dates', statusCode: 409);
      }
      
      throw BookingException(
        e.response?.data?['message'] ?? 'Failed to create booking',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('create booking', e);
      if (e is BookingException) {
        rethrow;
      }
      throw BookingException('Unexpected error: $e');
    }
  }

  static Future<List<Booking>> fetchBookings() async {
    final response = await http.get(Uri.parse('${AppConfig.getCurrentBaseUrl()}/booking/list'));
    final data = json.decode(response.body);
    if (data['success'] == true && data['data'] != null) {
      return (data['data'] as List).map((json) => Booking.fromApiJson(json)).toList();
    }
    return [];
  }
}
