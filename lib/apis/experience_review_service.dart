import 'package:pearlnest/apis/api_client.dart';

class ExperienceReviewService {
  static Future<List<Map<String, dynamic>>> getReviews() async {
    final response = await ApiClient.get('/review/experience');
    final data = response.data;
    if (response.statusCode != 200 ||
        data is! Map ||
        data['success'] != true ||
        data['data'] is! List) {
      throw Exception('Could not load community reviews.');
    }
    return (data['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> saveReview({
    required int stars,
    required String message,
  }) async {
    final response = await ApiClient.post('/review/experience', {
      'stars': stars,
      'message': message.trim(),
    });
    final data = response.data;
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data is! Map ||
        data['success'] != true) {
      throw Exception(
        data is Map
            ? data['message']?.toString() ?? 'Could not save your review.'
            : 'Could not save your review.',
      );
    }
  }

  static Future<void> reply({
    required String reviewId,
    required String message,
  }) async {
    final response = await ApiClient.post(
      '/review/experience/$reviewId/replies',
      {'message': message.trim()},
    );
    final data = response.data;
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data is! Map ||
        data['success'] != true) {
      throw Exception(
        data is Map
            ? data['message']?.toString() ?? 'Could not post your reply.'
            : 'Could not post your reply.',
      );
    }
  }

  static Future<void> report({
    required String type,
    required String targetId,
    required String reason,
  }) async {
    final response = await ApiClient.post(
      '/review/experience/$type/$targetId/reports',
      {'reason': reason.trim()},
    );
    final data = response.data;
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data is! Map ||
        data['success'] != true) {
      throw Exception(
        data is Map
            ? data['message']?.toString() ?? 'Could not submit the report.'
            : 'Could not submit the report.',
      );
    }
  }
}
