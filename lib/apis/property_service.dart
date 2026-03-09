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
  NetworkException(super.message) : super(code: 'NETWORK_ERROR');
}

class ValidationException extends PropertyException {
  ValidationException(super.message) : super(code: 'VALIDATION_ERROR');
}

class PropertyService {
  // Logging helper
  static void _logRequest(String endpoint, Map<String, dynamic>? data, {String? token}) {
    if (kDebugMode) {
      //debugPrint('🏠 PROPERTY REQUEST: $endpoint');
      if (data != null) {
        //debugPrint('🏠 Request data: $data');
      }
      if (token != null) {
        //debugPrint('🔑 Full Token: $token');
      }
    }
  }

  static void _logResponse(String endpoint, Response response) {
    if (kDebugMode) {
      //debugPrint('📝 PROPERTY RESPONSE [$endpoint]: Status ${response.statusCode}');
      //debugPrint('📝 Response Body: ${response.data}');
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      //debugPrint('❌ PROPERTY ERROR [$operation]: $error');
      if (error is DioException) {
        //debugPrint('❌ Response status: ${error.response?.statusCode}');
        //debugPrint('❌ Response data: ${error.response?.data}');
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
  static Future<List<Property>> getProperties({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
    String? token,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (userId != null) queryParams['userId'] = userId;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (filters != null) queryParams.addAll(filters);

      _logRequest('/property/list', queryParams, token: token);

      // Set token temporarily if provided
      final originalToken = ApiClient.currentAuthToken;
      if (token != null) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get(
        '/property/list',
        queryParameters: queryParams,
      );

      // Restore original token
      if (token != null) {
        ApiClient.setAuthToken(originalToken);
      }
      _logResponse('/property/list', response);

      if (response.statusCode == 200) {
        // Parse properties list
        final propertiesData = response.data;
        List<Property> properties = [];

        if (propertiesData is List) {
          properties = propertiesData.map((propertyJson) => Property.fromJson(propertyJson)).toList();
          return properties;
        }

        return [];
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Failed to fetch properties',
          statusCode: response.statusCode,
        );
      }
    } catch (e, trace) {
      debugPrint("Properties Error: $e");
      debugPrint("Properties Error Location: $trace");
      throw PropertyException(
        'Failed to fetch properties',
        statusCode: 500,
      );
    }
  }

  // Search properties
  static Future<List<Property>> searchProperties({
    required String searchString,
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

      final endpoint = '/property/list?search=${Uri.encodeComponent(searchString.trim())}&sortOrder=$sortOrder&minBeds=${filters?["bedrooms"] ?? 0}&minBathrooms=${filters?["bathrooms"] ?? 0}&minPrice=0&maxPrice=${filters?["priceRange"] == 5000 ? '' : filters?["priceRange"]}';
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
        final propertiesData = response.data;
        List<Property> properties = [];

        if (propertiesData is List) {
          properties = propertiesData.map((propertyJson) => Property.fromJson(propertyJson)).toList();
          return properties;
        }

        return [];
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Search failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e, trace) {
      print("Search Error: $e");
      print("Search Error Trace: $trace");
      throw PropertyException(
        'Search failed',
        statusCode: 500,
      );
    }
  }

  // Search properties by price range
  static Future<Map<String, dynamic>> searchPropertiesByPrice({
    required double minPrice,
    required double maxPrice,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? token,
  }) async {
    try {
      // Input validation
      if (minPrice < 0 || maxPrice < 0) {
        throw ValidationException('Price values must be non-negative');
      }
      if (minPrice > maxPrice) {
        throw ValidationException('Minimum price cannot be greater than maximum price');
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final endpoint = '/property/search/price/${minPrice.round()}/${maxPrice.round()}';
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
          'minPrice': minPrice,
          'maxPrice': maxPrice,
          'total': responseData['total'] ?? properties.length,
          'page': responseData['page'] ?? page,
          'limit': responseData['limit'] ?? limit,
          'totalPages': responseData['totalPages'] ?? ((responseData['total'] ?? properties.length) / limit).ceil(),
          'hasNextPage': responseData['hasNextPage'] ?? false,
          'hasPrevPage': responseData['hasPrevPage'] ?? false,
          'message': responseData['message'] ?? 'Price search completed successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Price search failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'search properties by price');
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

  // Get featured properties
  static Future<Map<String, dynamic>> getFeaturedProperties({
    int page = 1,
    int limit = 20,
    String? token,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (userId != null) queryParams['userId'] = userId;

      _logRequest('/property/list/featured', queryParams, token: token);

      // Set token temporarily if provided
      final originalToken = ApiClient.currentAuthToken;
      if (token != null) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get('/property/list/featured', queryParameters: queryParams);

      // Restore original token
      if (token != null) {
        ApiClient.setAuthToken(originalToken);
      }

      _logResponse('/property/list/featured', response);

      if (response.statusCode == 200) {
        //debugPrint('✅ HTTP 200 - Processing featured properties response...');

        final responseData = response.data as Map<String, dynamic>;

        // Handle the case where data can be null
        List<Property> featuredProperties = [];

        if (responseData['data'] != null) {
          final propertiesData = responseData['data'];

          if (propertiesData is List) {
            //debugPrint('   - Properties count: ${propertiesData.length}');

            try {
              featuredProperties = propertiesData.map((propertyJson) {
                //debugPrint('     - Processing property: ${propertyJson['title'] ?? 'Unknown'}');
                return Property.fromJson(propertyJson);
              }).toList();

              //debugPrint('✅ Successfully parsed ${featuredProperties.length} featured properties');
            } catch (parseError) {
              //debugPrint('❌ Error parsing properties: $parseError');
              throw PropertyException('Failed to parse featured properties data');
            }
          } else {
            //debugPrint('⚠️ Properties data is not a List, treating as no properties');
          }
        } else {
          //debugPrint('ℹ️ No featured properties available (data is null)');
        }

        final result = {
          'success': true,
          'properties': featuredProperties,
          'total': featuredProperties.length,
          'page': page,
          'limit': limit,
          'hasData': responseData['data'] != null,
          'message': featuredProperties.isEmpty ? 'No featured properties available at the moment' : 'Featured properties loaded successfully',
          'statusCode': response.statusCode,
        };

        return result;
      } else {
        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Failed to fetch featured properties',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'get featured properties');
    } finally {
      //debugPrint('🏁 === FETCH FEATURED PROPERTIES END ===');
      //debugPrint('');
    }
  }

  // Clear any cached data (if implementing caching later)
  static Future<void> clearCache() async {
    try {
      // Implementation for clearing cached property data
      //debugPrint('🏠 Property cache cleared');
    } catch (e) {
      //debugPrint('❌ Error clearing property cache: $e');
    }
  }

  static PropertyStatus _parsePropertyStatus(String status) {
    switch (status) {
      case "BOOKED":
        return PropertyStatus.booked;
      case 'APPROVED':
        return PropertyStatus.approved;
      case 'REJECTED':
        return PropertyStatus.rejected;
      case 'PENDING':
        return PropertyStatus.pending;
      default:
        return PropertyStatus.pending;
    }
  }

  /// Get properties by landlord/user ID
  static Future<Map<String, dynamic>> getPropertiesByLandlord(String userId, {String? token}) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        //debugPrint('❌ User ID is empty');
        throw ValidationException('User ID is required');
      }

      // Set auth token if provided
      if (token != null && token.isNotEmpty) {
        ApiClient.setAuthToken(token);

        //debugPrint('🔑 Auth token set for request');
      }

      _logRequest('/property/landlord/$userId', null, token: token);

      final response = await ApiClient.get('/property/landlord/$userId');
      _logResponse('/property/landlord/$userId', response);

      if (response.statusCode == 200) {
        //debugPrint('✅ HTTP Success - Properties request successful');

        final responseData = _validateResponse(response);

        //debugPrint('📊 Response structure validated');

        List<Property> properties = [];

        if (responseData['data'] != null) {
          final data = responseData['data'];

          //debugPrint('📝 Processing properties data...');

          if (data is List) {
            //debugPrint('   - Data is List with ${data.length} items');

            for (var propertyData in data) {
              try {
                if (propertyData is Map<String, dynamic>) {
                  // Convert API response format to Property model format
                  final property = Property(
                    id: propertyData['id'] ?? '',
                    title: propertyData['propertyName'] ?? '',
                    description: propertyData['description'] ?? '',
                    price: (propertyData['price'] ?? 0).toDouble(),
                    deposit: (propertyData['deposit'] ?? 0).toDouble(),
                    isRent: propertyData['isRent'],
                    isSale: propertyData['isSale'],
                    parking: propertyData['parking'],
                    priceType: propertyData['period'] ?? 'per month',
                    location: propertyData['location'] ?? '',
                    address: propertyData['fullAddress'] ?? '',
                    type: _parsePropertyType(propertyData['propertyType'] ?? ''),
                    bedrooms: propertyData['numberOfBeds'] ?? 0,
                    bathrooms: propertyData['numberOfBathrooms'] ?? 0,
                    area: _parseArea(propertyData['areaMeasurement'] ?? ''),
                    amenities: _parseAmenities(propertyData['amenities'] ?? ''),
                    images: _parseImages(propertyData['media'] ?? ''),
                    landlordId: propertyData['userId'] ?? '',
                    landlordName: '', // Not provided in API response
                    landlordPhone: '', // Not provided in API response
                    landlordEmail: '', // Not provided in API response
                    rating: 0.0, // Not provided in API response
                    reviewCount: 0, // Not provided in API response
                    status: _parsePropertyStatus(propertyData['status']),
                    availabilityStatus: propertyData['availability'],
                    createdAt: DateTime.tryParse(propertyData['createdAt'] ?? '') ?? DateTime.now(),
                    updatedAt: DateTime.tryParse(propertyData['updatedAt'] ?? '') ?? DateTime.now(),
                    latitude: 0.0, // Not provided in API response
                    longitude: 0.0, // Not provided in API response
                    isFeatured: propertyData['featured'] ?? false,
                    isVerified: propertyData['isVerified'] ?? false,
                    views: [], // Not provided in API response
                    shares: [], // Not provided in API response
                    favourites: [], // Not provided in API response
                  );
                  properties.add(property);

                  //debugPrint('   ✓ Processed property: ${property.title}');
                }
              } catch (e) {
                //debugPrint('   ⚠️ Error processing property item: $e');
                // Continue processing other properties
              }
            }

            //debugPrint('✅ Successfully processed ${properties.length} properties');
          } else {
            //debugPrint('⚠️ Properties data is not a List, treating as no properties');
          }
        } else {
          //debugPrint('ℹ️ No properties available (data is null)');
        }

        final result = {
          'success': true,
          'properties': properties,
          'total': properties.length,
          'hasData': responseData['data'] != null,
          'message': properties.isEmpty ? 'No properties found for this landlord' : 'Properties loaded successfully',
          'statusCode': response.statusCode,
        };

        //debugPrint('✅ === LANDLORD PROPERTIES RESULT ===');
        //debugPrint('   - Success: ${result['success']}');
        //debugPrint('   - Properties count: ${properties.length}');
        //debugPrint('   - Has data: ${result['hasData']}');
        //debugPrint('   - Message: ${result['message']}');

        return result;
      } else {
        //debugPrint('❌ HTTP Error - Properties request failed:');
        //debugPrint('   - Status code: ${response.statusCode}');
        //debugPrint('   - Response data: ${response.data}');

        final errorData = response.data;
        throw PropertyException(
          errorData['message'] ?? 'Failed to fetch landlord properties',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      //debugPrint('');
      //debugPrint('❌ === LANDLORD PROPERTIES ERROR ===');
      //debugPrint('   - Error: $e');
      //debugPrint('   - Error type: ${e.runtimeType}');
      //debugPrint('   - Stack trace: $stackTrace');

      return _handleError(e, 'get landlord properties');
    } finally {
      //debugPrint('🏁 === FETCH LANDLORD PROPERTIES END ===');
      //debugPrint('');
    }
  }

  // Helper methods for parsing API response data
  static PropertyType _parsePropertyType(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'studio':
        return PropertyType.studio;
      case 'condo':
        return PropertyType.condo;
      case 'hostel':
        return PropertyType.hostel;
      default:
        return PropertyType.apartment;
    }
  }

  static double _parseArea(String areaMeasurement) {
    // Extract number from strings like "85 sq meters"
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(areaMeasurement);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  static List<String> _parseAmenities(String amenities) {
    if (amenities.isEmpty) return [];
    return amenities.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<String> _parseImages(String media) {
    if (media.isEmpty) return [];
    return media.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'undefined' && !e.contains('undefined')).toList();
  }

  /// Upload a new property
  static Future<Map<String, dynamic>> uploadProperty({
    required String propertyName,
    required String propertyType,
    required String location,
    required double price,
    required double deposit,
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
    required bool isSale,
    required bool isRent,
    required bool parking,
    required String distance,
    //required bool availability, // true for "Available Now", false for "Available Later"
    DateTime? availableFrom, // Only needed when availability is false
    List<File>? images,
  }) async {
    try {
      // Prepare fields map with actual types (like your working example)
      Map<String, dynamic> fields = {
        'propertyName': propertyName,
        'propertyType': propertyType,
        'location': location,
        'price': price.round(),
        'deposit': deposit.round(),
        'amenities': amenities,
        'distance': distance,
        'isRent': isRent,
        'isSale': isSale,
        'parking': parking,
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
        // 'availability': availability,
      };

      // Prepare files map
      Map<String, File> filesMap = {};

      // Add image files (limit to 10 images)
      if (images != null && images.isNotEmpty) {
        // Enforce limit of 10 images
        final limitedImages = images.take(10).toList();

        for (int i = 0; i < limitedImages.length; i++) {
          filesMap['image_$i'] = limitedImages[i];
        }
      }

      // Create FormData manually like your working example
      final formData = FormData();

      // Add text fields (convert to string like your working code does)
      fields.forEach((key, value) {
        //debugPrint('🏠 Adding field: $key = $value (${value.runtimeType})');
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // Add files
      for (var entry in filesMap.entries) {
        //debugPrint('🏠 Adding file: image = ${entry.value.path}');
        formData.files.add(
          MapEntry(
            'image', // Use same key 'image' for all files
            await MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split('/').last,
            ),
          ),
        );
      }

      _logRequest('/property/upload', fields..['images_count'] = filesMap.length);

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

      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
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

  // Search properties by type or criteria
  static Future<Map<String, dynamic>> searchPropertiesByType(String searchString) async {
    try {
      if (searchString.trim().isEmpty) {
        throw ValidationException('Search string cannot be empty');
      }

      final endpoint = '/property/search/${searchString.toLowerCase()}';

      _logRequest(endpoint, null);

      final response = await ApiClient.get(endpoint);
      _logResponse(endpoint, response);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final List<dynamic> propertiesData = responseData['data'] ?? [];

          // Convert the response data to Property objects
          final List<Property> properties = propertiesData.map((propertyData) {
            return Property.fromJson(propertyData);
          }).toList();

          //debugPrint('🔍 Search for "$searchString" returned ${properties.length} properties');

          return {
            'success': true,
            'properties': properties,
            'count': properties.length,
            'searchTerm': searchString,
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Search failed',
            'properties': <Property>[],
            'count': 0,
            'searchTerm': searchString,
            'statusCode': response.statusCode,
          };
        }
      } else {
        throw PropertyException(
          'Search request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'property search for "$searchString"');
    }
  }

  // Update property using PATCH API
  static Future<Map<String, dynamic>> updateProperty({
    required String propertyId,
    required String token,
    String? propertyName,
    String? propertyType,
    String? location,
    double? price,
    double? deposit,
    bool? parking,
    String? distance,
    bool? isRent,
    bool? isSale,
    String? amenities,
    String? safetyAndSecurity,
    String? description,
    String? nearbyPlaces,
    int? numberOfBeds,
    int? numberOfBathrooms,
    String? areaMeasurement,
    String? neighborhood,
    String? fullAddress,
    String? propertyMap,
    String? period,
    bool? featured,
    bool? isVerified,
    bool? availability, // true for "Available Now", false for "Available Later"
    DateTime? availableFrom, // Only needed when availability is false
  }) async {
    try {
      // Build the request body with only provided fields
      Map<String, dynamic> requestBody = {};

      if (propertyName != null) requestBody['propertyName'] = propertyName;
      if (propertyType != null) requestBody['propertyType'] = propertyType;
      if (location != null) requestBody['location'] = location;
      if (price != null) requestBody['price'] = price;
      if (deposit != null) requestBody['deposit'] = deposit;
      if (distance != null) requestBody['distance'] = distance;
      if (parking != null) requestBody['parking'] = parking;
      if (isRent != null) requestBody['isRent'] = isRent;
      if (isSale != null) requestBody['isSale'] = isSale;
      if (amenities != null) requestBody['amenities'] = amenities;
      if (safetyAndSecurity != null) requestBody['safetyAndSecurity'] = safetyAndSecurity;
      if (description != null) requestBody['description'] = description;
      if (nearbyPlaces != null) requestBody['nearbyPlaces'] = nearbyPlaces;
      if (numberOfBeds != null) requestBody['numberOfBeds'] = numberOfBeds;
      if (numberOfBathrooms != null) requestBody['numberOfBathrooms'] = numberOfBathrooms;
      if (areaMeasurement != null) requestBody['areaMeasurement'] = areaMeasurement;
      if (neighborhood != null) requestBody['neighborhood'] = neighborhood;
      if (fullAddress != null) requestBody['fullAddress'] = fullAddress;
      if (propertyMap != null) requestBody['propertyMap'] = propertyMap;
      if (period != null) requestBody['period'] = period;
      if (featured != null) requestBody['featured'] = featured;
      if (isVerified != null) requestBody['isVerified'] = isVerified;
      if (availability != null) requestBody['availability'] = availability;

      // Add availableFrom date if provided (only for "Available Later")
      if (availability == false && availableFrom != null) {
        // Format date as YYYY-MM-DD for API
        requestBody['availableFrom'] = availableFrom.toIso8601String().split('T')[0];
      }

      _logRequest('/property/update/$propertyId', requestBody, token: token);

      // Set auth token
      final originalToken = ApiClient.currentAuthToken;
      if (token.isNotEmpty) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.patch(
        '/property/update/$propertyId',
        requestBody,
      );

      // Restore original token
      if (token.isNotEmpty) {
        ApiClient.setAuthToken(originalToken);
      }

      _logResponse('/property/update/$propertyId', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Property updated successfully',
          'property': response.data['property'],
        };
      } else {
        throw PropertyException(
          'Update request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'property update for property ID: $propertyId');
    }
  }

  // Delete property using DELETE API
  static Future<Map<String, dynamic>> deleteProperty({
    required String propertyId,
    required String token,
  }) async {
    try {
      _logRequest('/property/delete/$propertyId', null, token: token);

      // Set auth token
      final originalToken = ApiClient.currentAuthToken;
      if (token.isNotEmpty) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.delete('/property/delete/$propertyId');

      // Restore original token
      if (token.isNotEmpty) {
        ApiClient.setAuthToken(originalToken);
      }

      _logResponse('/property/delete/$propertyId', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Property deleted successfully',
        };
      } else {
        throw PropertyException(
          'Delete request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'property deletion for property ID: $propertyId');
    }
  }

  // Upload property image using POST API
  static Future<Map<String, dynamic>> uploadPropertyImage({
    required String propertyId,
    required String token,
    required File imageFile,
  }) async {
    try {
      _logRequest('/property/upload/image/$propertyId', {'image': 'File upload'}, token: token);

      // Create form data for image upload
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      // Set auth token
      final originalToken = ApiClient.currentAuthToken;
      if (token.isNotEmpty) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.postMultipart(
        '/property/upload/image/$propertyId',
        formData,
      );

      // Restore original token
      if (token.isNotEmpty) {
        ApiClient.setAuthToken(originalToken);
      }

      _logResponse('/property/upload/image/$propertyId', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Image uploaded successfully',
          'imageUrl': response.data['imageUrl'],
        };
      } else {
        throw PropertyException(
          'Image upload failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'image upload for property ID: $propertyId');
    }
  }

  // Get property details by ID for editing
  static Future<Map<String, dynamic>> getPropertyForEdit(String propertyId, {String? token}) async {
    try {
      _logRequest('/property/$propertyId', null, token: token);

      // Set auth token
      final originalToken = ApiClient.currentAuthToken;
      if (token != null && token.isNotEmpty) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.get('/property/$propertyId');

      // Restore original token
      if (token != null && token.isNotEmpty) {
        ApiClient.setAuthToken(originalToken);
      }

      _logResponse('/property/$propertyId', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'property': response.data['data'], // Changed from 'property' to 'data' to match API response
        };
      } else {
        throw PropertyException(
          'Property fetch failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'property fetch for property ID: $propertyId');
    }
  }

  // Delete property image
  static Future<Map<String, dynamic>> deletePropertyImage(
    String propertyId,
    String imageString, {
    String? token,
  }) async {
    try {
      _logRequest('/property/delete/image/$propertyId/$imageString', null, token: token);

      // Set auth token
      final originalToken = ApiClient.currentAuthToken;
      if (token != null && token.isNotEmpty) {
        ApiClient.setAuthToken(token);
      }

      final response = await ApiClient.delete('/property/delete/image/$propertyId/$imageString');

      // Restore original token
      if (token != null && token.isNotEmpty) {
        ApiClient.setAuthToken(originalToken);
      }

      _logResponse('/property/delete/image/$propertyId/$imageString', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Image deleted successfully',
        };
      } else {
        throw PropertyException(
          'Image delete failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'image deletion for property ID: $propertyId');
    }
  }
}
