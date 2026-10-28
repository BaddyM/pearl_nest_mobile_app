import 'package:dio/dio.dart';
import 'package:pearlnest/apis/api_client.dart';

class RefundService {
  static Future<RefundEligibility> getEligibility(String paymentId) async {
    try {
      final response = await ApiClient.get(
        '/refunds/eligibility/${Uri.encodeComponent(paymentId)}',
      );
      final body = response.data;
      if (response.statusCode != 200 ||
          body is! Map ||
          body['success'] != true ||
          body['data'] is! Map) {
        throw RefundException(
          _errorMessage(body, 'Refund eligibility could not be checked.'),
        );
      }
      return RefundEligibility.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    } on DioException catch (error) {
      throw RefundException(_errorMessage(
        error.response?.data,
        'Unable to check refund eligibility. Check your connection and try again.',
      ));
    }
  }

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

class RefundEligibility {
  final String paymentId;
  final String bookingStatus;
  final double refundPercent;
  final double paymentAmount;
  final double maximumRefund;
  final double requestedAmount;
  final double remainingRefund;

  const RefundEligibility({
    required this.paymentId,
    required this.bookingStatus,
    required this.refundPercent,
    required this.paymentAmount,
    required this.maximumRefund,
    required this.requestedAmount,
    required this.remainingRefund,
  });

  factory RefundEligibility.fromJson(Map<String, dynamic> json) =>
      RefundEligibility(
        paymentId: json['paymentId']?.toString() ?? '',
        bookingStatus: json['bookingStatus']?.toString() ?? '',
        refundPercent: _number(json['refundPercent']),
        paymentAmount: _number(json['paymentAmount']),
        maximumRefund: _number(json['maximumRefund']),
        requestedAmount: _number(json['requestedAmount']),
        remainingRefund: _number(json['remainingRefund']),
      );

  static double _number(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed.isFinite ? parsed : 0;
  }

  double get requestLimit {
    final limit =
        maximumRefund < remainingRefund ? maximumRefund : remainingRefund;
    return limit < 0 ? 0 : limit;
  }
}

class RefundException implements Exception {
  final String message;
  const RefundException(this.message);

  @override
  String toString() => message;
}
