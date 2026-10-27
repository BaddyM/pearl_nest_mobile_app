import 'package:pearlnest/apis/api_client.dart';

class WithdrawalService {
  static Future<void> requestWithdrawal({
    required int amount,
    required String destinationMethod,
    required String destinationName,
    required String destinationAccount,
    String? destinationProvider,
  }) async {
    final response = await ApiClient.post('/payments/landlord/withdrawals', {
      'amount': amount,
      'destinationMethod': destinationMethod,
      'destinationName': destinationName,
      'destinationAccount': destinationAccount,
      if (destinationProvider != null && destinationProvider.isNotEmpty)
        'destinationProvider': destinationProvider,
    });
    final data = response.data;
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data is! Map ||
        data['success'] != true) {
      throw Exception(
        data is Map && data['message'] is String
            ? data['message'] as String
            : 'The withdrawal request could not be submitted.',
      );
    }
  }
}
