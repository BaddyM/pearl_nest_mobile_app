import 'package:pearlnest/apis/api_client.dart';

class RefundTier {
  final String bookingStatus;
  final double refundPercent;

  const RefundTier({
    required this.bookingStatus,
    required this.refundPercent,
  });

  factory RefundTier.fromJson(Map<String, dynamic> json) {
    final rawPercent = json['refundPercent'];
    final percent = rawPercent is num
        ? rawPercent.toDouble()
        : double.tryParse(rawPercent?.toString() ?? '');
    return RefundTier(
      bookingStatus: json['bookingStatus']?.toString().trim() ?? '',
      refundPercent: percent != null && percent.isFinite
          ? percent.clamp(0, 100).toDouble()
          : 0,
    );
  }
}

class PolicyConfiguration {
  final String? privacyPolicy;
  final String? termsAndConditions;
  final List<RefundTier> refundTiers;

  const PolicyConfiguration({
    this.privacyPolicy,
    this.termsAndConditions,
    this.refundTiers = const [],
  });

  factory PolicyConfiguration.fromJson(Map<String, dynamic> json) {
    final rawTiers = json['refundTiers'];
    return PolicyConfiguration(
      privacyPolicy: _policyText(json['privacyPolicy']),
      termsAndConditions: _policyText(json['termsAndConditions']),
      refundTiers: rawTiers is List
          ? rawTiers
              .whereType<Map>()
              .map((item) => RefundTier.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((tier) => tier.bookingStatus.isNotEmpty)
              .toList()
          : const [],
    );
  }

  static String? _policyText(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}

class PolicyService {
  static Future<PolicyConfiguration> fetchPolicies() async {
    final response = await ApiClient.get('/configuration/policies');
    if (response.statusCode != 200 || response.data is! Map) {
      throw FormatException('The policy response was invalid.');
    }

    final responseBody = Map<String, dynamic>.from(response.data as Map);
    if (responseBody['success'] != true || responseBody['data'] is! Map) {
      throw FormatException('Policies could not be loaded from the server.');
    }
    return PolicyConfiguration.fromJson(
      Map<String, dynamic>.from(responseBody['data'] as Map),
    );
  }
}
