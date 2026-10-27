import 'package:dio/dio.dart';
import 'package:pearlnest/apis/api_client.dart';

class RefundService {
  static Future<List<Map<String, dynamic>>> getTenantRequests() async {
    return _getList('/refunds/mine');
  }

  static Future<List<Map<String, dynamic>>> getLandlordRequests() async {
    return _getList('/refunds/landlord');
  }

  static Future<List<Map<String, dynamic>>> _getList(String endpoint) async {
    try {
      final response = await ApiClient.get(endpoint);
      return _parseList(response.data, response.statusCode);
    } on DioException catch (error) {
      throw RefundException(_errorMessage(
        error.response?.data,
        'Unable to connect to refunds. Check your connection and try again.',
      ));
    }
  }

  static Future<Map<String, dynamic>> requestRefund({
    required String paymentId,
    required int amount,
    required String reason,
    required String destinationMethod,
    required String destinationName,
    required String destinationAccount,
    String? destinationProvider,
  }) async {
    try {
      final response = await ApiClient.post('/refunds', {
        'paymentId': paymentId,
        'amount': amount,
        'reason': reason,
        'destinationMethod': destinationMethod,
        'destinationName': destinationName,
        'destinationAccount': destinationAccount,
        if (destinationProvider != null && destinationProvider.trim().isNotEmpty)
          'destinationProvider': destinationProvider.trim(),
      });
      final body = response.data;
      if (response.statusCode != 200 && response.statusCode != 201 ||
          body is! Map || body['success'] != true) {
        throw RefundException(_errorMessage(body, 'Refund request could not be submitted.'));
      }
      return Map<String, dynamic>.from(body['data'] as Map);
    } on DioException catch (error) {
      throw RefundException(_errorMessage(
        error.response?.data,
        'Unable to connect to refunds. Check your connection and try again.',
      ));
    }
  }

  static Future<Map<String, dynamic>> reviewAsLandlord({
    required String requestId,
    required String decision,
    String? note,
  }) async {
    try {
      final response = await ApiClient.post(
        '/refunds/$requestId/landlord-review',
        {'decision': decision, if (note != null) 'note': note},
      );
      final body = response.data;
      if (body is! Map || body['success'] != true) {
        throw RefundException(_errorMessage(body, 'Refund recommendation could not be saved.'));
      }
      return Map<String, dynamic>.from(body['data'] as Map);
    } on DioException catch (error) {
      throw RefundException(_errorMessage(
        error.response?.data,
        'Unable to connect to refunds. Check your connection and try again.',
      ));
    }
  }

  static List<Map<String, dynamic>> _parseList(dynamic body, int? statusCode) {
    if (statusCode != 200 || body is! Map || body['success'] != true || body['data'] is! List) {
      throw RefundException(_errorMessage(body, 'Refund requests could not be loaded.'));
    }
    return (body['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _errorMessage(dynamic body, String fallback) {
    if (body is Map && body['message'] != null) {
      final message = body['message'];
      return message is List ? message.join(', ') : message.toString();
    }
    return fallback;
  }
}

class RefundException implements Exception {
  final String message;
  const RefundException(this.message);

  @override
  String toString() => message;
}
