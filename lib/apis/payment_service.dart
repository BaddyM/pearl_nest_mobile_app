import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';

class PaymentService {
  static Future<Map<String, dynamic>> getLandlordWallet() async {
    try {
      final response = await ApiClient.get('/payments/landlord/wallet');
      final data = response.data;
      if (response.statusCode != 200 || data is! Map || data['success'] != true || data['data'] is! Map) {
        throw PaymentException('Wallet earnings could not be loaded. Please try again.');
      }
      return Map<String, dynamic>.from(data['data'] as Map);
    } on DioException catch (error) {
      final message = error.response?.data is Map
          ? error.response?.data['message']?.toString()
          : null;
      throw PaymentException(message?.isNotEmpty == true
          ? message!
          : 'Unable to connect to the wallet service. Check your connection and try again.');
    }
  }

  static void _logRequest(String endpoint, Map<String, dynamic>? data) {
    if (kDebugMode) {
      //debugPrint('💳 PAYMENT REQUEST: $endpoint');
      if (data != null) {
        //debugPrint('💳 Request data: $data');
      }
    }
  }

  static void _logResponse(String endpoint, Response response) {
    if (kDebugMode) {
      //debugPrint('💳 PAYMENT RESPONSE [$endpoint]: Status ${response.statusCode}');
      //debugPrint('💳 Response Body: ${response.data}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      //debugPrint('❌ PAYMENT ERROR [$operation]: $error');
      if (error is DioException) {
        //debugPrint('❌ Response status: ${error.response?.statusCode}');
        //debugPrint('❌ Response data: ${error.response?.data}');
      }
    }

    class PaymentException implements Exception {
      final String message;
      const PaymentException(this.message);

      @override
      String toString() => message;
    }
  }

  /// Create a payment for a booking
  static Future<Map<String, dynamic>> createPayment({
    required String userId,
    required String propertyId,
    required String bookingId,
    required double amount,
    String paymentType = 'MOBILE_MONEY',
  }) async {
    try {
      final requestData = {
        'userId': userId,
        'propertyId': propertyId,
        'bookingId': bookingId,
        'amount': amount,
        'paymentType': paymentType,
      };

      _logRequest('/payments/create', requestData);

      final response = await ApiClient.post('/payments/create', requestData);
      _logResponse('/payments/create', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Payment created successfully',
            'payment': data['data']?['data'],
            'paymentInfo': data['data']?['paymentInfo'],
            'redirectUrl': data['data']?['paymentInfo']?['redirect_url'],
            'orderTrackingId': data['data']?['paymentInfo']?['order_tracking_id'],
            'merchantReference': data['data']?['paymentInfo']?['merchant_reference'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to create payment',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to create payment. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logError('create payment', e);
      return {
        'success': false,
        'message': 'Network error occurred while creating payment',
        'error': e.toString(),
      };
    }
  }

  /// Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderTrackingId) async {
    try {
      _logRequest('/payments/status/$orderTrackingId', null);

      final response = await ApiClient.get('/payments/status/$orderTrackingId');
      _logResponse('/payments/status/$orderTrackingId', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check payment status',
        };
      }
    } catch (e) {
      _logError('check payment status', e);
      return {
        'success': false,
        'message': 'Network error occurred while checking payment status',
        'error': e.toString(),
      };
    }
  }

  /// Get user payments
  static Future<Map<String, dynamic>> getUserPayments(String userId) async {
    try {
      _logRequest('/payments/user/$userId', null);

      final response = await ApiClient.get('/payments/user/$userId');
      _logResponse('/payments/user/$userId', response);

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'payments': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch user payments',
        };
      }
    } catch (e) {
      _logError('get user payments', e);
      return {
        'success': false,
        'message': 'Network error occurred while fetching payments',
        'error': e.toString(),
      };
    }
  }
}
