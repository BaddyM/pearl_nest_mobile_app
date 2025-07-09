import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/models/property.dart';

// Custom exceptions for better error handling
class PropertyException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  PropertyException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'PropertyException: $message';
}

class NetworkException extends PropertyException {
  NetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class ValidationException extends PropertyException {
  ValidationException(String message) : super(message, code: 'VALIDATION_ERROR');
}

class PropertyService {

  // Logging helper
  static void _logRequest(String endpoint, Map<String, dynamic>? data, {String? token}) {
    if (kDebugMode) {
      debugPrint('🏠 PROPERTY REQUEST: $endpoint');
      if (data != null) {
        debugPrint('🏠 Request data: $data');
      }
      if (token != null) {
        debugPrint('🔑 Full Token: $token');
      }
    }
  }

  static void _logResponse(String endpoint, Response response) {
    if (kDebugMode) {
      debugPrint('📝 PROPERTY RESPONSE [$endpoint]: Status ${response.statusCode}');
      debugPrint('📝 Response Body: ${response.data}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      debugPrint('❌ PROPERTY ERROR [$operation]: $error');
      if (error is DioException) {
        debugPrint('❌ Response status: ${error.response?.statusCode}');
        debugPrint('❌ Response data: ${error.response?.data}');
      }
    }
  }

  static Map<String, dynamic> _validateResponse(Response response, {List<String> requiredFields = const []}) {
    final data = response.data as Map<String, dynamic>;
    
    for (String field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        throw ValidationException('Missing required field: $field');
      }
    }
    return data;
  }

  // Private method for consistent error handling
  static Map<String, dynamic> _handleError(dynamic error, String operation) {
    _logError(operation, error);
    
    String message;
    String? code;
    int? statusCode;
    
    if (error is PropertyException) {
      message = error.message;
      code = error.code;
      statusCode = error.statusCode;
    } else if (error.toString().contains('SocketException')) {
      message = 'No internet connection. Please check your network.';
      code = 'NO_INTERNET';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Request timed out. Please try again.';
      code = 'TIMEOUT';
    } else if (error.toString().contains('HandshakeException')) {
      message = 'Connection security error. Please try again.';
      code = 'SSL_ERROR';
    } else if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timeout. Please try again.';
          code = 'TIMEOUT';
          break;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            message = 'Authentication required. Please log in again.';
            code = 'UNAUTHORIZED';
          } else if (statusCode == 403) {
            message = 'Access denied. You don\'t have permission.';
            code = 'FORBIDDEN';
          } else if (statusCode == 404) {
            message = 'Properties not found.';
            code = 'NOT_FOUND';
          } else if (statusCode == 429) {
            message = 'Too many requests. Please wait and try again.';
            code = 'RATE_LIMIT';
          } else if (statusCode! >= 500) {
            message = 'Server error. Please try again later.';
            code = 'SERVER_ERROR';
          } else {
            final errorData = error.response?.data;
            message = errorData?['message'] ?? 'Request failed';
            code = 'API_ERROR';
          }
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled';
          code = 'CANCELLED';
          break;
        default:
          message = 'Network error occurred';
          code = 'NETWORK_ERROR';
      }
      statusCode = error.response?.statusCode;
    } else {
      message = 'An unexpected error occurred';
      code = 'UNKNOWN_ERROR';
    }

    return {
      'success': false,
      'message': message,
      'code': code,
      'statusCode': statusCode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Get list of properties
  static Future<Map<String, dynamic>> getProperties({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
    String? token,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (filters != null) queryParams.addAll(filters);

      _logRequest('/property/list', queryParams, token: token);

      // Set token temporarily if provided
      final originalToken = ApiClient.currentAuthToken;
      if (token != null) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get('/property/list', queryParameters: queryParams);
      
      // Restore original token
      if (token != null) {
        ApiClient.setAuthToken(originalToken);
      }
      _logResponse('/property/list', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Parse properties list
        final propertiesData = responseData['data'];
        List<Property> properties = [];
        
        if (propertiesData is List) {
          properties = propertiesData.map((propertyJson) => Property.fromJson(propertyJson)).toList();
        }

        return {
          'success': true,
          'properties': properties,
          'total': responseData['total'] ?? properties.length,
          'page': responseData['page'] ?? page,
          'limit': responseData['limit'] ?? limit,
          'totalPages': responseData['totalPages'] ?? ((responseData['total'] ?? properties.length) / limit).ceil(),
          'hasNextPage': responseData['hasNextPage'] ?? false,
          'hasPrevPage': responseData['hasPrevPage'] ?? false,
          'message': responseData['message'] ?? 'Properties loaded successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Failed to fetch properties',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'get properties');
    }
  }

  // Search properties
  static Future<Map<String, dynamic>> searchProperties({
    required String searchString,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
    String? token,
  }) async {
    try {
      // Input validation
      if (searchString.trim().isEmpty) {
        throw ValidationException('Search string cannot be empty');
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (filters != null) queryParams.addAll(filters);

      final endpoint = '/property/search/${Uri.encodeComponent(searchString.trim())}';
      _logRequest(endpoint, queryParams, token: token);

      // Set token temporarily if provided
      final originalToken = ApiClient.currentAuthToken;
      if (token != null) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get(endpoint, queryParameters: queryParams);
      
      // Restore original token
      if (token != null) {
        ApiClient.setAuthToken(originalToken);
      }
      _logResponse(endpoint, response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Parse properties list
        final propertiesData = responseData['data'];
        List<Property> properties = [];
        
        if (propertiesData is List) {
          properties = propertiesData.map((propertyJson) => Property.fromJson(propertyJson)).toList();
        }

        return {
          'success': true,
          'properties': properties,
          'searchString': searchString.trim(),
          'total': responseData['total'] ?? properties.length,
          'page': responseData['page'] ?? page,
          'limit': responseData['limit'] ?? limit,
          'totalPages': responseData['totalPages'] ?? ((responseData['total'] ?? properties.length) / limit).ceil(),
          'hasNextPage': responseData['hasNextPage'] ?? false,
          'hasPrevPage': responseData['hasPrevPage'] ?? false,
          'message': responseData['message'] ?? 'Search completed successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Search failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'search properties');
    }
  }

  // Get property by ID (if needed)
  static Future<Map<String, dynamic>> getPropertyById(String propertyId, {String? token}) async {
    try {
      if (propertyId.trim().isEmpty) {
        throw ValidationException('Property ID is required');
      }

      final endpoint = '/property/${propertyId.trim()}';
      _logRequest(endpoint, null, token: token);

      // Set token temporarily if provided
      final originalToken = ApiClient.currentAuthToken;
      if (token != null) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get(endpoint);
      
      // Restore original token
      if (token != null) {
        ApiClient.setAuthToken(originalToken);
      }
      _logResponse(endpoint, response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        final property = Property.fromJson(responseData['data']);

        return {
          'success': true,
          'property': property,
          'message': responseData['message'] ?? 'Property loaded successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Failed to fetch property',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'get property by ID');
    }
  }

  // Get featured properties (if the endpoint exists)
  static Future<Map<String, dynamic>> getFeaturedProperties({int limit = 10, String? token}) async {
    try {
      final queryParams = {'limit': limit, 'featured': true};
      
      _logRequest('/property/list', queryParams, token: token);

      // Set token temporarily if provided
      final originalToken = ApiClient.currentAuthToken;
      if (token != null) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get('/property/list', queryParameters: queryParams);
      
      // Restore original token
      if (token != null) {
        ApiClient.setAuthToken(originalToken);
      }
      _logResponse('/property/list', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        final propertiesData = responseData['data'];
        List<Property> properties = [];
        
        if (propertiesData is List) {
          properties = propertiesData.map((propertyJson) => Property.fromJson(propertyJson)).toList();
        }

        return {
          'success': true,
          'properties': properties,
          'total': properties.length,
          'message': 'Featured properties loaded successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Failed to fetch featured properties',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'get featured properties');
    }
  }

  // Clear any cached data (if implementing caching later)
  static Future<void> clearCache() async {
    try {
      // Implementation for clearing cached property data
      debugPrint('🏠 Property cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing property cache: $e');
    }
  }

  /// Upload a new property
  static Future<Map<String, dynamic>> uploadProperty({
    required String propertyName,
    required String propertyType,
    required String location,
    required double price,
    required String amenities,
    required String safetyAndSecurity,
    required String description,
    required String nearbyPlaces,
    required int numberOfBeds,
    required int numberOfBathrooms,
    required String areaMeasurement,
    required String neighborhood,
    required String fullAddress,
    required String propertyMap,
    required String period,
    bool featured = false,
    bool isVerified = false,
    bool availability = true,
    List<File>? images,
    String? userId,
  }) async {
    try {
      // Create FormData for multipart request
      final formData = FormData();

      // Add text fields with proper data types
      formData.fields.addAll([
        MapEntry('userId', userId ?? ''), // Add userId field
        MapEntry('propertyName', propertyName),
        MapEntry('propertyType', propertyType),
        MapEntry('location', location),
        MapEntry('price', price.round().toString()), // Ensure it's an integer string
        MapEntry('amenities', amenities),
        MapEntry('safetyAndSecurity', safetyAndSecurity),
        MapEntry('description', description),
        MapEntry('nearbyPlaces', nearbyPlaces),
        MapEntry('numberOfBeds', numberOfBeds.toString()),
        MapEntry('numberOfBathrooms', numberOfBathrooms.toString()),
        MapEntry('areaMeasurement', areaMeasurement),
        MapEntry('neighborhood', neighborhood),
        MapEntry('fullAddress', fullAddress),
        MapEntry('propertyMap', propertyMap),
        MapEntry('period', period),
        MapEntry('featured', featured ? 'true' : 'false'),
        MapEntry('isVerified', isVerified ? 'true' : 'false'),
        MapEntry('availability', availability ? 'true' : 'false'),
      ]);

      // Add image files (limit to 10 images)
      if (images != null && images.isNotEmpty) {
        // Enforce limit of 10 images
        final limitedImages = images.take(10).toList();
        
        for (int i = 0; i < limitedImages.length; i++) {
          final file = limitedImages[i];
          final fileName = file.path.split('/').last;
          formData.files.add(MapEntry(
            'image',
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
            ),
          ));
        }
      }

      _logRequest('/property/upload', {
        'propertyName': propertyName,
        'propertyType': propertyType,
        'location': location,
        'price': price,
        'amenities': amenities,
        'safetyAndSecurity': safetyAndSecurity,
        'description': description,
        'nearbyPlaces': nearbyPlaces,
        'numberOfBeds': numberOfBeds,
        'numberOfBathrooms': numberOfBathrooms,
        'areaMeasurement': areaMeasurement,
        'neighborhood': neighborhood,
        'fullAddress': fullAddress,
        'propertyMap': propertyMap,
        'period': period,
        'featured': featured,
        'isVerified': isVerified,
        'availability': availability,
        'images_count': images != null ? (images.length > 10 ? 10 : images.length) : 0,
      });

      final response = await ApiClient.postMultipart('/property/upload', formData);
      
      _logResponse('/property/upload', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Property uploaded successfully',
          'data': response.data,
        };
      } else {
        throw PropertyException(
          'Failed to upload property: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('upload property', e);
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('Connection timeout. Please check your internet connection.');
      }
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'Invalid property data provided';
        
        if (errorData != null && errorData['message'] != null) {
          if (errorData['message'] is List) {
            // Handle list of error messages
            final messages = errorData['message'] as List;
            errorMessage = messages.join(', ');
          } else {
            errorMessage = errorData['message'].toString();
          }
        }
        
        throw ValidationException(errorMessage);
      }
      
      if (e.response?.statusCode == 401) {
        throw PropertyException('Authentication required', statusCode: 401);
      }
      
      if (e.response?.statusCode == 403) {
        throw PropertyException('Not authorized to upload properties', statusCode: 403);
      }
      
      throw PropertyException(
        e.response?.data?['message'] ?? 'Failed to upload property',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('upload property', e);
      throw PropertyException('Unexpected error: $e');
    }
  }
}
