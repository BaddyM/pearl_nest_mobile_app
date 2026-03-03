import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';
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
      //debugPrint('🏨 BOOKING REQUEST: $endpoint');
      if (data != null) {
        //debugPrint('🏨 Request data: $data');
      }
    }
  }

  static void _logDioResponse(String endpoint, Response response) {
    if (kDebugMode) {
      //debugPrint('📝 BOOKING RESPONSE [$endpoint]: Status ${response.statusCode}');
      //debugPrint('📝 Response Body: ${response.data}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      //debugPrint('❌ BOOKING ERROR [$operation]: $error');
      if (error is DioException) {
        //debugPrint('❌ Response status: ${error.response?.statusCode}');
        //debugPrint('❌ Response data: ${error.response?.data}');
      }
    }
  }

  /// Create a new booking
  static Future<Map<String, dynamic>> createBooking({
    required String propertyId,
    String? checkInDate,
    String? checkOutDate,
    required int deposit,
  }) async {
    try {
      final requestData = {
        'propertyId': propertyId,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
        'deposit': deposit,
      };

      _logRequest('/booking/create', requestData);

      final response = await ApiClient.post('/booking/create', requestData);

      _logDioResponse('/booking/create', response);

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

      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
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

  static Future<List<Booking>> fetchBookings({String? status}) async {
    try {
      final endpoint = status != null ? '/booking/list?status=$status' : '/booking/list';
      _logRequest(endpoint, null);

      final response = await ApiClient.get(endpoint);

      _logDioResponse(endpoint, response);

      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final bookings = (data['data'] as List).map((json) => Booking.fromApiJson(json)).toList();
          return bookings;
        } else {
          //debugPrint('🏨 API returned success: false or no data');
          return [];
        }
      } else if (response.statusCode == 401) {
        throw BookingException('Authentication required', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw BookingException('Not authorized to fetch bookings', statusCode: 403);
      } else {
        throw BookingException(
          'Failed to fetch bookings: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, trace) {
      print("Error:$e");
      print("Location:$trace");
      if (e is BookingException) {
        rethrow;
      }
      throw BookingException('Unexpected error while fetching bookings: $e');
    }
  }

  /// Fetch only pending bookings
  static Future<List<Booking>> fetchPendingBookings() async {
    final bookings = await fetchBookings();
    // Additional client-side filter to ensure only pending bookings are returned
    final pendingOnly = bookings.where((booking) => booking.status == BookingStatus.pending).toList();

    //debugPrint('🏨 Server returned ${bookings.length} bookings, filtered to ${pendingOnly.length} pending bookings');
    return pendingOnly;
  }

  /// Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final endpoint = '/booking/status/update/$bookingId/$status';
      _logRequest(endpoint, {'bookingId': bookingId, 'status': status});

      final response = await ApiClient.patch(endpoint, {});

      _logDioResponse(endpoint, response);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          //debugPrint('🏨 Successfully updated booking status to $status');
          return {
            'success': true,
            'message': data['message'] ?? 'Booking status updated successfully',
            'data': data['data'],
          };
        } else {
          throw BookingException(
            data['message'] ?? 'Failed to update booking status',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 400) {
        final errorData = response.data;
        throw BookingException(
          errorData?['message'] ?? 'Invalid booking status or booking ID',
          statusCode: 400,
        );
      } else if (response.statusCode == 401) {
        throw BookingException('Authentication required', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw BookingException('Not authorized to update booking status', statusCode: 403);
      } else if (response.statusCode == 404) {
        throw BookingException('Booking not found', statusCode: 404);
      } else {
        throw BookingException(
          'Failed to update booking status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('update booking status', e);

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        throw BookingException(
          errorData?['message'] ?? 'Invalid booking status or booking ID',
          statusCode: 400,
        );
      }

      if (e.response?.statusCode == 401) {
        throw BookingException('Authentication required', statusCode: 401);
      }

      if (e.response?.statusCode == 403) {
        throw BookingException('Not authorized to update booking status', statusCode: 403);
      }

      if (e.response?.statusCode == 404) {
        throw BookingException('Booking not found', statusCode: 404);
      }

      throw BookingException(
        e.response?.data?['message'] ?? 'Failed to update booking status',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('update booking status', e);
      if (e is BookingException) {
        rethrow;
      }
      throw BookingException('Unexpected error: $e');
    }
  }

  /// Fetch booking requests for landlord
  static Future<List<Booking>> fetchLandlordBookings() async {
    try {
      const endpoint = '/booking/landlord/list';
      _logRequest(endpoint, null);

      final response = await ApiClient.get(endpoint);
      _logDioResponse(endpoint, response);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final bookingsJson = data['data'] as List;
          final bookings = bookingsJson.map((json) => Booking.fromApiJson(json as Map<String, dynamic>)).toList();

          //debugPrint('📋 Fetched ${bookings.length} landlord bookings');
          return bookings;
        } else {
          //debugPrint('⚠️ No booking data found in response');
          return [];
        }
      } else {
        throw BookingException(
          'Failed to fetch landlord bookings: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('fetch landlord bookings', e);

      if (e.response?.statusCode == 401) {
        throw BookingException(
          'Authentication failed. Please login again.',
          statusCode: 401,
        );
      }

      throw BookingException(
        e.response?.data?['message'] ?? 'Failed to fetch landlord bookings',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('fetch landlord bookings', e);
      if (e is BookingException) {
        rethrow;
      }
      throw BookingException('Unexpected error: $e');
    }
  }
}
