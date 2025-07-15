import 'package:pearlnest/apis/api_client.dart';

class PropertyInteractionsService {
  // Get views counter for a property
  static Future<Map<String, dynamic>> getViewsCounter(String propertyId) async {
    try {
      final response = await ApiClient.get('/views/counter/$propertyId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Views counter fetched successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to fetch views counter',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch views counter: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Get shares counter for a property
  static Future<Map<String, dynamic>> getSharesCounter(String propertyId) async {
    try {
      final response = await ApiClient.get('/shares/counter/$propertyId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Shares counter fetched successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to fetch shares counter',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch shares counter: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Get reviews for a property
  static Future<Map<String, dynamic>> getPropertyReviews(String propertyId) async {
    try {
      final response = await ApiClient.get('/review/property/$propertyId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Property reviews fetched successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to fetch property reviews',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch property reviews: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Add a review for a property
  static Future<Map<String, dynamic>> addReview({
    required String propertyId,
    required int stars,
    required String message,
  }) async {
    try {
      final response = await ApiClient.post('/review/add', {
        'propertyId': propertyId,
        'stars': stars,
        'message': message,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Review added successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to add review',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add review: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Increment view counter (call when property is viewed)
  static Future<Map<String, dynamic>> incrementViewCounter(String propertyId) async {
    try {
      final response = await ApiClient.put('/views/counter/$propertyId', {});
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'View counter incremented successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to increment view counter',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to increment view counter: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Increment share counter (call when property is shared)
  static Future<Map<String, dynamic>> incrementShareCounter(String propertyId) async {
    try {
      final response = await ApiClient.post('/shares/add', {
        'propertyId': propertyId,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Share counter incremented successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to increment share counter',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to increment share counter: ${e.toString()}',
        'data': null,
      };
    }
  }
}
