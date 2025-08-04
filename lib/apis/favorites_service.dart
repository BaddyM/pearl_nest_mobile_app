import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/models/property.dart';

// Custom exceptions for better error handling
class FavoritesException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  FavoritesException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'FavoritesException: $message';
}

class FavoritesService {
  // Logging helper
  static void _logRequest(String endpoint, Map<String, dynamic>? data) {
    if (kDebugMode) {
      //debugPrint('⭐ FAVORITES REQUEST: $endpoint');
      if (data != null) {
        //debugPrint('⭐ Request data: $data');
      }
    }
  }

  static void _logDioResponse(String endpoint, Response response) {
    if (kDebugMode) {
      //debugPrint('📝 FAVORITES RESPONSE [$endpoint]: Status ${response.statusCode}');
      //debugPrint('📝 Response Body: ${response.data}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      //debugPrint('❌ FAVORITES ERROR [$operation]: $error');
      if (error is DioException) {
        //debugPrint('❌ Response status: ${error.response?.statusCode}');
        //debugPrint('❌ Response data: ${error.response?.data}');
      }
    }
  }

  /// Fetch user's favorite properties
  static Future<List<Property>> fetchFavorites() async {
    try {
      _logRequest('/favourite/list', null);

      final response = await ApiClient.get('/favourite/list');

      _logDioResponse('/favourite/list', response);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final favorites = (data['data'] as List).map((favoriteItem) {
            // Extract the property object from each favorite item
            final propertyData = favoriteItem['property'];
            return Property.fromJson(propertyData);
          }).toList();

          //debugPrint('⭐ Successfully fetched ${favorites.length} favorite properties');
          return favorites;
        } else {
          //debugPrint('⭐ API returned success: false or no data');
          return [];
        }
      } else if (response.statusCode == 401) {
        throw FavoritesException('Authentication required', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw FavoritesException('Not authorized to fetch favorites', statusCode: 403);
      } else {
        throw FavoritesException(
          'Failed to fetch favorites: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('fetch favorites', e);

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Bad request';
        throw FavoritesException(errorMessage, statusCode: 400);
      }

      if (e.response?.statusCode == 401) {
        throw FavoritesException('Authentication required', statusCode: 401);
      }

      if (e.response?.statusCode == 403) {
        throw FavoritesException('Not authorized to fetch favorites', statusCode: 403);
      }

      if (e.response?.statusCode == 404) {
        throw FavoritesException('Favorites not found', statusCode: 404);
      }

      throw FavoritesException(
        e.response?.data?['message'] ?? 'Failed to fetch favorites',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('fetch favorites', e);
      if (e is FavoritesException) {
        rethrow;
      }
      throw FavoritesException('Unexpected error: $e');
    }
  }

  /// Add property to favorites
  static Future<Map<String, dynamic>> addToFavorites(String propertyId) async {
    try {
      final requestData = {
        'propertyId': propertyId,
      };

      _logRequest('/favourite/add', requestData);

      final response = await ApiClient.post('/favourite/add', requestData);

      _logDioResponse('/favourite/add', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Added to favorites successfully',
          'data': response.data,
        };
      } else {
        throw FavoritesException(
          'Failed to add to favorites: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('add to favorites', e);

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Property already in favorites or invalid request';
        throw FavoritesException(errorMessage, statusCode: 400);
      }

      if (e.response?.statusCode == 401) {
        throw FavoritesException('Authentication required', statusCode: 401);
      }

      if (e.response?.statusCode == 404) {
        throw FavoritesException('Property not found', statusCode: 404);
      }

      throw FavoritesException(
        e.response?.data?['message'] ?? 'Failed to add to favorites',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('add to favorites', e);
      if (e is FavoritesException) {
        rethrow;
      }
      throw FavoritesException('Unexpected error: $e');
    }
  }

  /// Remove property from favorites
  static Future<Map<String, dynamic>> removeFromFavorites(String propertyId) async {
    try {
      _logRequest('/favourite/remove/$propertyId', null);

      final response = await ApiClient.delete('/favourite/remove/$propertyId');

      _logDioResponse('/favourite/remove/$propertyId', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Removed from favorites successfully',
          'data': response.data,
        };
      } else {
        throw FavoritesException(
          'Failed to remove from favorites: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('remove from favorites', e);

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Property not in favorites or invalid request';
        throw FavoritesException(errorMessage, statusCode: 400);
      }

      if (e.response?.statusCode == 401) {
        throw FavoritesException('Authentication required', statusCode: 401);
      }

      if (e.response?.statusCode == 404) {
        throw FavoritesException('Property not found in favorites', statusCode: 404);
      }

      throw FavoritesException(
        e.response?.data?['message'] ?? 'Failed to remove from favorites',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('remove from favorites', e);
      if (e is FavoritesException) {
        rethrow;
      }
      throw FavoritesException('Unexpected error: $e');
    }
  }

  /// Toggle property favorite status (add/remove)
  static Future<Map<String, dynamic>> toggleFavorite(String propertyId) async {
    try {
      _logRequest('/favourite/toggle/$propertyId', null);

      final response = await ApiClient.patch('/favourite/toggle/$propertyId', {});

      _logDioResponse('/favourite/toggle/$propertyId', response);

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'message': data['message'] ?? 'Favorite status updated successfully',
          'isFavorite': data['isFavorite'] ?? false,
          'data': data,
        };
      } else {
        throw FavoritesException(
          'Failed to toggle favorite: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('toggle favorite', e);

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Invalid request';
        throw FavoritesException(errorMessage, statusCode: 400);
      }

      if (e.response?.statusCode == 401) {
        throw FavoritesException('Authentication required', statusCode: 401);
      }

      if (e.response?.statusCode == 404) {
        throw FavoritesException('Property not found', statusCode: 404);
      }

      throw FavoritesException(
        e.response?.data?['message'] ?? 'Failed to toggle favorite',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('toggle favorite', e);
      if (e is FavoritesException) {
        rethrow;
      }
      throw FavoritesException('Unexpected error: $e');
    }
  }
}
