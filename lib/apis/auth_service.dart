import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Custom exceptions for better error handling
class AuthException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  AuthException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'AuthException: $message';
}

class NetworkException extends AuthException {
  NetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class ValidationException extends AuthException {
  ValidationException(String message) : super(message, code: 'VALIDATION_ERROR');
}

class AuthService {
  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _lastLoginKey = 'last_login';
  static const String _tokenExpiryKey = 'token_expiry';
  
  // Configuration constants
  static const int _passwordMinLength = 6;
  static const int _maxSessionDays = 90; // 90 days as per requirement

  // Logging helper
  static void _logRequest(String endpoint, Map<String, dynamic>? data, {String? token}) {
    if (kDebugMode) {
      debugPrint('🚀 AUTH REQUEST: $endpoint');
      if (data != null) {
        // Don't log sensitive data like passwords
        final sanitizedData = Map<String, dynamic>.from(data);
        if (sanitizedData.containsKey('password')) {
          sanitizedData['password'] = '[REDACTED]';
        }
        if (sanitizedData.containsKey('currentPassword')) {
          sanitizedData['currentPassword'] = '[REDACTED]';
        }
        if (sanitizedData.containsKey('newPassword')) {
          sanitizedData['newPassword'] = '[REDACTED]';
        }
        debugPrint('📤 Request Data: ${jsonEncode(sanitizedData)}');
      }
      if (token != null) {
        debugPrint('🔑 Token: ${token.substring(0, 10)}...');
      }
    }
  }

  static void _logResponse(String endpoint, Response response) {
    if (kDebugMode) {
      debugPrint('📥 AUTH RESPONSE: $endpoint');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📋 Headers: ${response.headers}');
      
      // Log response body (be careful with sensitive data)
      try {
        final responseData = response.data;
        // Don't log sensitive data
        if (responseData is Map<String, dynamic>) {
          final sanitizedResponse = Map<String, dynamic>.from(responseData);
          if (sanitizedResponse.containsKey('token')) {
            final token = sanitizedResponse['token'];
            if (token is String && token.isNotEmpty) {
              sanitizedResponse['token'] = '${token.substring(0, 10)}...';
            }
          }
          debugPrint('📝 Response Body: ${jsonEncode(sanitizedResponse)}');
        } else {
          debugPrint('📝 Response Body: $responseData');
        }
      } catch (e) {
        debugPrint('📝 Response Body (raw): ${response.data}');
      }
    }
  }

  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      debugPrint('❌ AUTH ERROR [$operation]: $error');
      if (error is Error) {
        debugPrint('🔍 Stack Trace: ${error.stackTrace}');
      }
    }
  }

  // Private method to validate API response structure
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
    
    if (error is AuthException) {
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
    } else if (error.toString().contains('FormatException')) {
      message = 'Invalid server response. Please try again later.';
      code = 'FORMAT_ERROR';
    } else if (error.toString().contains('Cannot POST') || error.toString().contains('Cannot GET')) {
      // Handle HTTP method errors - likely server is down or endpoint doesn't exist
      if (operation == 'login') {
        message = 'Login service is temporarily unavailable. Please try again later.';
      } else if (operation == 'registration') {
        message = 'Registration service is temporarily unavailable. Please try again later.';
      } else {
        message = 'Service is temporarily unavailable. Please try again later.';
      }
      code = 'SERVICE_UNAVAILABLE';
    } else if (error.toString().contains('XMLHttpRequest error')) {
      message = 'Connection failed. Please check your internet connection.';
      code = 'CONNECTION_ERROR';
    } else if (error.toString().contains('Connection refused') || error.toString().contains('Connection failed')) {
      message = 'Unable to connect to server. Please try again later.';
      code = 'CONNECTION_REFUSED';
    } else {
      // Generic fallback with operation-specific messages
      if (operation == 'login') {
        message = 'Login failed. Please check your credentials and try again.';
      } else if (operation == 'registration') {
        message = 'Registration failed. Please try again.';
      } else if (operation == 'password change') {
        message = 'Password change failed. Please try again.';
      } else {
        message = 'An unexpected error occurred. Please try again.';
      }
      code = 'UNKNOWN_ERROR';
    }

    return {
      'success': false,
      'message': message,
      'code': code,
      'statusCode': statusCode,
    };
  }

  // Save token with expiry
  static Future<void> _saveToken(String token, {int? expiresIn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Calculate expiry time (default to 90 days if not provided)
    final expiryDuration = expiresIn != null 
        ? Duration(seconds: expiresIn) 
        : Duration(days: _maxSessionDays);
    
    final expiryTime = DateTime.now().add(expiryDuration);
    await prefs.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);
    
    if (kDebugMode) {
      debugPrint('💾 Token saved with expiry: ${expiryTime.toIso8601String()}');
    }
  }

  // Check if token is expired locally
  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTime = prefs.getInt(_tokenExpiryKey);
      
      if (expiryTime == null) return true;
      
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTime);
      final isExpired = DateTime.now().isAfter(expiry);
      
      if (kDebugMode) {
        debugPrint('🕐 Token expiry check: ${isExpired ? "EXPIRED" : "VALID"} (expires: ${expiry.toIso8601String()})');
      }
      
      return isExpired;
    } catch (e) {
      _logError('token expiry check', e);
      return true;
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String userType = 'TENANT',
  }) async {
    try {
      // Input validation
      if (name.trim().isEmpty) throw ValidationException('Name is required');
      if (email.trim().isEmpty) throw ValidationException('Email is required');
      if (password.length < _passwordMinLength) {
        throw ValidationException('Password must be at least $_passwordMinLength characters');
      }
      if (phone.trim().isEmpty) throw ValidationException('Phone number is required');

      final requestData = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'contact': phone.trim(),
        'role': userType.toUpperCase(),
      };

      _logRequest('/user/register', requestData);

      final response = await ApiClient.post('/user/register', requestData);
      _logResponse('/user/register', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Save token if provided (check both token and accessToken)
        final token = responseData['token'] ?? responseData['accessToken'];
        if (token != null) {
          await _saveToken(token, expiresIn: responseData['expiresIn']);
        }
        
        return {
          'success': true,
          'user': User.fromJson(responseData['data']),
          'token': token,
          'message': responseData['message'] ?? 'Registration successful',
          'requiresVerification': responseData['requiresVerification'] ?? false,
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw AuthException(
          errorData['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'registration');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Input validation
      if (email.trim().isEmpty) throw ValidationException('Email is required');
      if (password.isEmpty) throw ValidationException('Password is required');

      final requestData = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      _logRequest('/user/login', requestData);

      final response = await ApiClient.post('/user/login', requestData);
      _logResponse('/user/login', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['accessToken']);
        
        // Save token with expiry
        await _saveToken(responseData['accessToken'], expiresIn: responseData['expiresIn']);
        
        // Set the token for subsequent requests
        ApiClient.setAuthToken(responseData['accessToken']);
        
        // Fetch user profile data after successful login
        try {
          final profileResponse = await ApiClient.get('/user/userProfile/fetch');
          _logResponse('/user/userProfile/fetch', profileResponse);
          
          if (profileResponse.statusCode == 200) {
            final profileData = _validateResponse(profileResponse, requiredFields: ['data']);
            
            // Save user data and last login
            await saveUserData(User.fromJson(profileData['data']));
            
            return {
              'success': true,
              'user': User.fromJson(profileData['data']),
              'token': responseData['accessToken'],
              'message': responseData['message'] ?? 'Login successful',
              'expiresIn': responseData['expiresIn'],
              'statusCode': response.statusCode,
            };
          } else {
            // If profile fetch fails, still return successful login
            return {
              'success': true,
              'token': responseData['accessToken'],
              'message': responseData['message'] ?? 'Login successful',
              'expiresIn': responseData['expiresIn'],
              'statusCode': response.statusCode,
            };
          }
        } catch (profileError) {
          // If profile fetch fails, still return successful login
          _logError('profile fetch', profileError);
          return {
            'success': true,
            'token': responseData['accessToken'],
            'message': responseData['message'] ?? 'Login successful',
            'expiresIn': responseData['expiresIn'],
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        throw AuthException('Invalid email or password');
      } else if (response.statusCode == 403) {
        final errorData = response.data;
        throw AuthException(
          errorData['message'] ?? 'Account verification required',
          code: 'VERIFICATION_REQUIRED',
        );
      } else {
        final errorData = response.data;
        throw AuthException(
          errorData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'login');
    }
  }

  static Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      if (token.isEmpty) throw ValidationException('Token is required');

      // Check local expiry first
      if (await isTokenExpired()) {
        return {
          'success': false,
          'message': 'Token has expired locally',
          'code': 'TOKEN_EXPIRED',
          'isValid': false,
        };
      }

      _logRequest('/auth/validate', null, token: token);

      // Temporarily set the token for this request
      final originalToken = ApiClient.currentAuthToken;
      ApiClient.setAuthToken(token);
      
      try {
        final response = await ApiClient.get('/auth/validate');
        _logResponse('/auth/validate', response);
      
        if (response.statusCode == 200) {
          final responseData = _validateResponse(response, requiredFields: ['data']);
          
          return {
            'success': true,
            'user': User.fromJson(responseData['data']),
            'isValid': true,
            'message': 'Token is valid',
            'statusCode': response.statusCode,
          };
        } else if (response.statusCode == 401) {
          return {
            'success': false,
            'message': 'Token has expired',
            'code': 'TOKEN_EXPIRED',
            'isValid': false,
            'statusCode': response.statusCode,
          };
        } else {
          throw AuthException('Token validation failed');
        }
      } finally {
        // Restore original token
        ApiClient.setAuthToken(originalToken);
      }
    } catch (e) {
      return _handleError(e, 'token validation');
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String currentToken) async {
    try {
      if (currentToken.isEmpty) throw ValidationException('Current token is required');

      _logRequest('/auth/refresh', {}, token: currentToken);

      // Temporarily set the token for this request
      final originalToken = ApiClient.currentAuthToken;
      ApiClient.setAuthToken(currentToken);
      
      try {
        final response = await ApiClient.post('/auth/refresh', {});
        _logResponse('/auth/refresh', response);
      
        if (response.statusCode == 200) {
          final data = _validateResponse(response, requiredFields: ['token']);
          
          // Save new token
          await _saveToken(data['token'], expiresIn: data['expiresIn']);
          
          return {
            'success': true,
            'token': data['token'],
            'user': data['user'] != null ? User.fromJson(data['user']) : null,
            'expiresIn': data['expiresIn'],
            'message': 'Token refreshed successfully',
            'statusCode': response.statusCode,
          };
        } else if (response.statusCode == 401) {
          throw AuthException('Refresh token has expired', code: 'REFRESH_TOKEN_EXPIRED');
        } else {
          throw AuthException('Token refresh failed');
        }
      } finally {
        // Restore original token
        ApiClient.setAuthToken(originalToken);
      }
    } catch (e) {
      return _handleError(e, 'token refresh');
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      // Try to call logout endpoint if token exists
      if (token != null && token.isNotEmpty) {
        try {
          _logRequest('/auth/logout', {}, token: token);
          
          // Temporarily set the token for this request
          final originalToken = ApiClient.currentAuthToken;
          ApiClient.setAuthToken(token);
          
          try {
            final response = await ApiClient.post('/auth/logout', {});
            _logResponse('/auth/logout', response);
          } finally {
            ApiClient.setAuthToken(originalToken);
          }
        } catch (e) {
          // Log but don't fail logout on network error
          _logError('logout API call', e);
        }
      }
      
      // Always clear local storage
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_userDataKey),
        prefs.remove(_lastLoginKey),
        prefs.remove(_tokenExpiryKey),
      ]);
      
      if (kDebugMode) {
        debugPrint('🚪 User logged out and local data cleared');
      }
      
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      _logError('logout', e);
      return {
        'success': true, // Always return success for logout
        'message': 'Logged out successfully',
      };
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Input validation
      if (currentPassword.isEmpty) throw ValidationException('Current password is required');
      if (newPassword.length < _passwordMinLength) {
        throw ValidationException('New password must be at least $_passwordMinLength characters');
      }
      if (currentPassword == newPassword) {
        throw ValidationException('New password must be different from current password');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token == null || token.isEmpty) {
        throw AuthException('Authentication required', code: 'NOT_AUTHENTICATED');
      }

      // Check if token is expired locally
      if (await isTokenExpired()) {
        throw AuthException('Session expired. Please login again.', code: 'TOKEN_EXPIRED');
      }

      final requestData = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      _logRequest('/auth/change-password', requestData, token: token);

      // Temporarily set the token for this request
      final originalToken = ApiClient.currentAuthToken;
      ApiClient.setAuthToken(token);
      
      try {
        final response = await ApiClient.post('/auth/change-password', requestData);
        _logResponse('/auth/change-password', response);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Password changed successfully',
            'statusCode': response.statusCode,
          };
        } else if (response.statusCode == 400) {
          final errorData = response.data;
          throw AuthException(errorData['message'] ?? 'Invalid current password');
        } else if (response.statusCode == 401) {
          throw AuthException('Session expired. Please login again.', code: 'TOKEN_EXPIRED');
        } else {
          final errorData = response.data;
          throw AuthException(errorData['message'] ?? 'Password change failed');
        }
      } finally {
        ApiClient.setAuthToken(originalToken);
      }
    } catch (e) {
      return _handleError(e, 'password change');
    }
  }

  // Improved user data handling
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);
        return User.fromJson(userData);
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error getting current user: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return null;
    }
  }

  // Helper method to save user data
  static Future<bool> saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userDataKey, userJson);
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error saving user data: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  // Check if user session is still valid
  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final lastLogin = prefs.getInt(_lastLoginKey);
      
      if (token == null || lastLogin == null) return false;
      
      // Check if token is expired
      if (await isTokenExpired()) return false;
      
      // Check if session is older than configured max days
      final sessionAge = DateTime.now().millisecondsSinceEpoch - lastLogin;
      final maxSessionAge = _maxSessionDays * 24 * 60 * 60 * 1000; // days in milliseconds
      
      return sessionAge < maxSessionAge;
    } catch (e) {
      return false;
    }
  }

  // Get current token
  static Future<String?> getCurrentToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? bio,
    String? profilePicture,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? emailNotifications,
  }) async {
    try {
      // Input validation
      if (name.trim().isEmpty) throw ValidationException('Name is required');
      if (email.trim().isEmpty) throw ValidationException('Email is required');
      if (phone.trim().isEmpty) throw ValidationException('Phone number is required');

      final requestData = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'contact': phone.trim(),
      };

      // Add optional fields if provided
      if (bio != null) requestData['bio'] = bio;
      if (profilePicture != null) requestData['profilePicture'] = profilePicture;
      if (pushNotifications != null) requestData['pushNotifications'] = pushNotifications;
      if (smsNotifications != null) requestData['smsNotifications'] = smsNotifications;
      if (emailNotifications != null) requestData['emailNotifications'] = emailNotifications;

      _logRequest('/user/userProfile/update', requestData);

      final response = await ApiClient.patch('/user/userProfile/update', requestData);
      _logResponse('/user/userProfile/update', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Update stored user data
        final updatedUser = User.fromJson(responseData['data']);
        await saveUserData(updatedUser);
        
        return {
          'success': true,
          'user': updatedUser,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw AuthException(
          errorData['message'] ?? 'Profile update failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'profile update');
    }
  }
}
