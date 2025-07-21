import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearlnest/services/notification_service.dart';
import 'package:pearlnest/network/exceptions/network_exceptions.dart';

class AuthService {
  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _lastLoginKey = 'last_login';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  
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
    } else if (error.toString().contains('userId should not be empty')) {
      message = 'User session expired. Please login again.';
      code = 'USER_ID_MISSING';
    } else if (error.toString().contains('SocketException') || error.toString().contains('Please check your internet connection')) {
      message = 'No internet connection. Please check your network.';
      code = 'NO_INTERNET';
    } else if (error.toString().contains('TimeoutException') || error.toString().contains('Connection timeout') ) {
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
      } else if (operation == 'profile update') {
        message = 'Profile update failed. Please try again.';
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

  // Save user ID to local storage
  static Future<void> _saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      
      if (kDebugMode) {
        debugPrint('💾 User ID saved successfully: $userId');
        debugPrint('💾 UserID key used: $_userIdKey');
        
        // Verify it was saved
        final savedUserId = prefs.getString(_userIdKey);
        debugPrint('💾 Verification - Retrieved user ID: $savedUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving user ID: $e');
      }
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

      // Create request data according to API specification
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

      // Get real FCM token
      final fcmToken = await _getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        throw AuthException('Unable to retrieve device notification token. Please check your network and try again.');
      }

      // Create request data for login
      final requestData = {
        'email': email.trim().toLowerCase(),
        'password': password,
        'fcmToken': fcmToken,
      };

      _logRequest('/user/login', requestData);

      final response = await ApiClient.post('/user/login', requestData);
      _logResponse('/user/login', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['accessToken']);
        
        // Save userId if provided in the response
        if (responseData['userId'] != null) {
          await _saveUserId(responseData['userId'].toString());
        }
        
        // Check if OTP verification is required
        if (responseData['otp'] != null) {
          // Don't save token yet - only save after OTP verification
          // Don't set token globally yet - only set temporarily for OTP verification
          return {
            'success': true,
            'requiresOtp': true,
            'tempToken': responseData['accessToken'],
            'email': email.trim().toLowerCase(),
            'otp': responseData['otp'].toString(), // Include the OTP from response
            'message': 'An OTP has been sent to your email. Please verify your login.',
            'statusCode': response.statusCode,
          };
        }
        
        // If no OTP required, save token and proceed with normal login
        await _saveToken(responseData['accessToken'], expiresIn: responseData['expiresIn']);
        
        // Set the token for subsequent requests
        ApiClient.setAuthToken(responseData['accessToken']);
        
        // Fetch user profile data after successful login
        try {
          final profileResponse = await ApiClient.get('/user/userProfile/fetch');
          _logResponse('/user/userProfile/fetch', profileResponse);
          
          if (profileResponse.statusCode == 200) {
            final profileData = _validateResponse(profileResponse, requiredFields: ['data']);
            
            // Create user object from profile data
            final userData = profileData['data'];
            
            // If profile data doesn't have ID, use the one from login response
            if ((userData['id'] == null || userData['id'].toString().isEmpty) && responseData['userId'] != null) {
              userData['id'] = responseData['userId'].toString();
              if (kDebugMode) {
                debugPrint('🔧 Profile data missing ID, using login userId: ${responseData['userId']}');
              }
            }
            
            final user = User.fromJson(userData);
            
            // Save user data and last login
            await saveUserData(user);
            
            return {
              'success': true,
              'user': user,
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
      debugPrint('AuthService: Login error - $e');
      return _handleError(e, 'login');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String userInputOtp, String serverOtp, String tempToken) async {
    try {
      // Input validation
      if (email.trim().isEmpty) throw ValidationException('Email is required');
      if (userInputOtp.trim().isEmpty) throw ValidationException('OTP is required');
      if (serverOtp.isEmpty) throw ValidationException('Server OTP is required');
      if (tempToken.isEmpty) throw ValidationException('Temporary token is required');

      debugPrint('🔐 Client-side OTP verification:');
      debugPrint('User Input: ${userInputOtp.trim()}');
      debugPrint('Server OTP: $serverOtp');
      
      // Client-side OTP verification
      if (userInputOtp.trim() != serverOtp.trim()) {
        throw AuthException('Invalid OTP. Please check the code and try again.', code: 'INVALID_OTP');
      }
      
      debugPrint('✅ OTP verification successful - proceeding with user profile fetch');
      
      // Save the token only after successful OTP verification
      await _saveToken(tempToken);
      
      // Set the token for subsequent requests
      ApiClient.setAuthToken(tempToken);
      
      // Fetch user profile data after successful OTP verification
      try {
        final profileResponse = await ApiClient.get('/user/userProfile/fetch');
        _logResponse('/user/userProfile/fetch', profileResponse);
        
        if (profileResponse.statusCode == 200) {
          final profileData = _validateResponse(profileResponse, requiredFields: ['data']);
          
          // Create user object from profile data
          final userData = profileData['data'];
          
          final user = User.fromJson(userData);
          
          // Save user data and last login
          await saveUserData(user);
          
          return {
            'success': true,
            'user': user,
            'token': tempToken,
            'message': 'OTP verification successful',
            'statusCode': 200,
          };
        } else {
          // If profile fetch fails, still return successful verification
          return {
            'success': true,
            'token': tempToken,
            'message': 'OTP verification successful',
            'statusCode': 200,
          };
        }
      } catch (profileError) {
        // If profile fetch fails, still return successful verification
        _logError('profile fetch after OTP', profileError);
        return {
          'success': true,
          'token': tempToken,
          'message': 'OTP verification successful',
          'statusCode': 200,
        };
      }
    } catch (e) {
      debugPrint('AuthService: OTP verification error - $e');
      return _handleError(e, 'OTP verification');
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String email, String tempToken) async {
    try {
      // Input validation
      if (email.trim().isEmpty) throw ValidationException('Email is required');
      if (tempToken.isEmpty) throw ValidationException('Temporary token is required');

      final requestData = {
        'email': email.trim().toLowerCase(),
      };

      _logRequest('/auth/resend-otp', requestData, token: tempToken);

      // Set the temporary token for this request
      final originalToken = ApiClient.currentAuthToken;
      ApiClient.setAuthToken(tempToken);
      
      try {
        final response = await ApiClient.post('/auth/resend-otp', requestData);
        _logResponse('/auth/resend-otp', response);

        if (response.statusCode == 200) {
          final responseData = _validateResponse(response);
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'OTP has been resent to your email',
            'statusCode': response.statusCode,
          };
        } else if (response.statusCode == 429) {
          final errorData = response.data;
          throw AuthException(
            errorData['message'] ?? 'Too many requests. Please wait before requesting another OTP.',
            code: 'TOO_MANY_REQUESTS',
          );
        } else {
          final errorData = response.data;
          throw AuthException(
            errorData['message'] ?? 'Failed to resend OTP',
            statusCode: response.statusCode,
          );
        }
      } finally {
        // Restore original token
        ApiClient.setAuthToken(originalToken);
      }
    } catch (e) {
      debugPrint('AuthService: OTP resend error - $e');
      return _handleError(e, 'OTP resend');
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
        prefs.remove(_userIdKey),
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
        
        // Check if user ID is missing in user data but exists in separate storage
        if ((userData['id'] == null || userData['id'].toString().isEmpty)) {
          final separateUserId = prefs.getString(_userIdKey);
          if (separateUserId != null && separateUserId.isNotEmpty) {
            userData['id'] = separateUserId;
            if (kDebugMode) {
              debugPrint('🔧 getCurrentUser: Fixed missing user ID from separate storage: $separateUserId');
            }
          }
        }
        
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

  // Get the saved user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      
      if (kDebugMode) {
        debugPrint('🔍 AuthService.getUserId() called');
        debugPrint('🔍 Retrieved user ID from storage: $userId');
        debugPrint('🔍 UserID key: $_userIdKey');
      }
      
      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user ID: $e');
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
      
      // Only save user ID if it's not empty to avoid overwriting existing valid ID
      if (user.id.isNotEmpty) {
        await _saveUserId(user.id);
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ User data has empty ID, preserving existing user ID');
        }
      }
      
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

  // Refresh user profile data from server
  static Future<User?> refreshUserProfile() async {
    try {
      final token = await getCurrentToken();
      if (token == null) {
        debugPrint('🔄 No token available for profile refresh');
        return null;
      }

      debugPrint('🔄 Refreshing user profile from server...');
      
      // Set the token for the request
      ApiClient.setAuthToken(token);
      
      final response = await ApiClient.get('/user/userProfile/fetch');
      _logResponse('/user/userProfile/fetch', response);
      
      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Create user object from fresh profile data
        final userData = responseData['data'];
        final user = User.fromJson(userData);
        
        // Save the fresh user data
        await saveUserData(user);
        
        debugPrint('✅ User profile refreshed successfully');
        debugPrint('🔄 Fresh profile image: ${user.profileImage}');
        
        return user;
      } else {
        debugPrint('❌ Failed to refresh user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing user profile: $e');
      return null;
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

  // Update profile picture using dedicated endpoint
  static Future<Map<String, dynamic>> updateProfilePicture({
    required String imagePath,
  }) async {
    try {
      // Get current user data to get userId
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw AuthException('User not found. Please login again.');
      }

      if (currentUser.id.isEmpty) {
        debugPrint('🔧 User ID is empty, attempting manual fix...');
        final fixResult = await fixMissingUserId();
        if (!fixResult) {
          throw AuthException('User ID not found. Please login again.');
        }
        // Try to get user again after fixing
        final updatedUser = await getCurrentUser();
        if (updatedUser == null || updatedUser.id.isEmpty) {
          throw AuthException('Unable to retrieve user ID. Please login again.');
        }
      }

      final userId = currentUser.id;
      debugPrint('🔧 Updating profile picture for userId: $userId');
      debugPrint('🔧 Image path: $imagePath');

      // Create multipart form data for the image
      final formData = FormData();
      formData.files.add(MapEntry('image', await MultipartFile.fromFile(imagePath, filename: 'profile_image.jpg')));

      _logRequest('/user/profilePicture/$userId', {'multipart': 'true', 'hasImage': true});

      // Use the dedicated profile picture endpoint
      final response = await ApiClient.patchMultipart('/user/profilePicture/$userId', formData);
      _logResponse('/user/profilePicture/$userId', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Update stored user data with new profile image
        final updatedUser = User.fromJson(responseData['data']);
        await saveUserData(updatedUser);
        
        return {
          'success': true,
          'user': updatedUser,
          'message': responseData['message'] ?? 'Profile picture updated successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = response.data;
        throw AuthException(
          errorData['message'] ?? 'Profile picture update failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return _handleError(e, 'profile picture update');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? bio,
    String? imagePath,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? emailNotifications,
  }) async {
    try {
      // Input validation
      if (name.trim().isEmpty) throw ValidationException('Name is required');
      if (email.trim().isEmpty) throw ValidationException('Email is required');
      if (phone.trim().isEmpty) throw ValidationException('Phone number is required');

      // Get current user data to get userId and role
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw AuthException('User not found. Please login again.');
      }

      // Check if userId is still empty after getCurrentUser() fix
      if (currentUser.id.isEmpty) {
        debugPrint('🔧 User ID is empty even after getCurrentUser() fix, attempting manual fix...');
        final fixResult = await fixMissingUserId();
        if (!fixResult) {
          throw AuthException('User ID not found. Please login again.');
        }
        // Try to get user again after fixing
        final updatedUser = await getCurrentUser();
        if (updatedUser == null || updatedUser.id.isEmpty) {
          throw AuthException('Unable to retrieve user ID. Please login again.');
        }
        debugPrint('🔧 Using updated user with ID: ${updatedUser.id}');
      }

      Map<String, dynamic> profileUpdateResult = {};
      
      // First, update the profile picture if provided using the dedicated endpoint
      if (imagePath != null && imagePath.isNotEmpty) {
        debugPrint('🔧 Updating profile picture using dedicated endpoint...');
        profileUpdateResult = await updateProfilePicture(imagePath: imagePath);
        
        if (profileUpdateResult['success'] != true) {
          // If profile picture update fails, return the error
          return profileUpdateResult;
        }
        
        debugPrint('🔧 Profile picture updated successfully');
      }

      // Then update other profile information using the regular endpoint
      final requestData = <String, dynamic>{
        'userId': currentUser.id,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'contact': phone.trim(),
        'role': currentUser.userType.toString().split('.').last.toUpperCase(),
        'isVerified': currentUser.isVerified,
      };

      // Add optional fields if provided
      if (bio != null) requestData['bio'] = bio;
      if (pushNotifications != null) requestData['pushNotifications'] = pushNotifications;
      if (smsNotifications != null) requestData['smsNotifications'] = smsNotifications;
      if (emailNotifications != null) requestData['emailNotifications'] = emailNotifications;

      _logRequest('/user/userProfile/update', requestData);

      final response = await ApiClient.patch('/user/userProfile/update', requestData);
      _logResponse('/user/userProfile/update', response);

      if (response.statusCode == 200) {
        final responseData = _validateResponse(response, requiredFields: ['data']);
        
        // Update stored user data
        final finalUpdatedUser = User.fromJson(responseData['data']);
        await saveUserData(finalUpdatedUser);
        
        return {
          'success': true,
          'user': finalUpdatedUser,
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

  /// Delete user account permanently
  /// This is a destructive action that cannot be undone
  static Future<Map<String, dynamic>> deleteAccount({
    required String userId,
    String? reason,
  }) async {
    try {
      _logRequest('/user/delete/$userId', {
        'reason': reason,
      });

      final token = await getCurrentToken();
      if (token == null) {
        throw AuthException('No authentication token found');
      }

      // Set the auth token for the request
      ApiClient.setAuthToken(token);

      final response = await ApiClient.delete('/user/delete/$userId');

      _logResponse('/user/delete/$userId', response);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Account deleted successfully, clear all local data
        await clearUserData();
        
        if (kDebugMode) {
          debugPrint('✅ Account deleted successfully and local data cleared');
        }

        return {
          'success': true,
          'message': response.data?['message'] ?? 'Account deleted successfully',
        };
      } else {
        final errorMessage = response.data?['message'] ?? 'Failed to delete account';
        if (kDebugMode) {
          debugPrint('❌ Account deletion failed: $errorMessage');
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on DioException catch (e) {
      _logError('deleteAccount', e);
      
      String errorMessage;
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'You do not have permission to delete this account.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Account not found.';
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'Account cannot be deleted due to pending transactions.';
      } else {
        errorMessage = e.response?.data?['message'] ?? 
                      'Network error occurred while deleting account. Please try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      _logError('deleteAccount', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred while deleting account. Please try again.',
      };
    }
  }

  /// Clear all stored user data (used during account deletion and logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_userDataKey),
        prefs.remove(_tokenKey),
        prefs.remove(_lastLoginKey),
        prefs.remove(_tokenExpiryKey),
        prefs.remove(_userIdKey),
      ]);
      
      if (kDebugMode) {
        debugPrint('🧹 All user data cleared from local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing user data: $e');
      }
    }
  }

  // Debug method to check all stored data
  static Future<void> debugStoredData() async {
    if (!kDebugMode) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint('🔍 === AUTH SERVICE STORED DATA DEBUG ===');
      debugPrint('🔍 Token exists: ${prefs.getString(_tokenKey) != null}');
      debugPrint('🔍 User data exists: ${prefs.getString(_userDataKey) != null}');
      debugPrint('🔍 User ID exists: ${prefs.getString(_userIdKey) != null}');
      debugPrint('🔍 User ID value: ${prefs.getString(_userIdKey)}');
      debugPrint('🔍 Last login exists: ${prefs.getInt(_lastLoginKey) != null}');
      debugPrint('🔍 Token expiry exists: ${prefs.getInt(_tokenExpiryKey) != null}');
      
      // Try to get and parse user data
      final userDataJson = prefs.getString(_userDataKey);
      if (userDataJson != null) {
        try {
          final userData = jsonDecode(userDataJson);
          debugPrint('🔍 User data ID field: ${userData['id']}');
          debugPrint('🔍 User data name field: ${userData['name']}');
        } catch (e) {
          debugPrint('❌ Error parsing stored user data: $e');
        }
      }
      
      debugPrint('🔍 === END STORED DATA DEBUG ===');
    } catch (e) {
      debugPrint('❌ Error in debugStoredData: $e');
    }
  }

  // Emergency method to fix user ID if it's missing but user data exists
  static Future<bool> fixMissingUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      
      if (userId != null && userId.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ User ID already exists: $userId');
        }
        return true;
      }
      
      // Try to get user ID from stored user data
      final userDataJson = prefs.getString(_userDataKey);
      if (userDataJson != null) {
        try {
          final userData = jsonDecode(userDataJson);
          if (kDebugMode) {
            debugPrint('🔍 Full user data from storage: $userData');
            debugPrint('🔍 Available keys: ${userData.keys.toList()}');
            debugPrint('🔍 ID field: ${userData['id']}');
            debugPrint('🔍 _id field: ${userData['_id']}');
            debugPrint('🔍 userId field: ${userData['userId']}');
            debugPrint('🔍 user_id field: ${userData['user_id']}');
          }
          
          // Try different possible ID fields
          String? userIdFromData;
          if (userData['id'] != null && userData['id'].toString().isNotEmpty) {
            userIdFromData = userData['id'].toString();
          } else if (userData['_id'] != null && userData['_id'].toString().isNotEmpty) {
            userIdFromData = userData['_id'].toString();
          } else if (userData['userId'] != null && userData['userId'].toString().isNotEmpty) {
            userIdFromData = userData['userId'].toString();
          } else if (userData['user_id'] != null && userData['user_id'].toString().isNotEmpty) {
            userIdFromData = userData['user_id'].toString();
          }
          
          if (userIdFromData != null && userIdFromData.isNotEmpty) {
            await _saveUserId(userIdFromData);
            if (kDebugMode) {
              debugPrint('🔧 Fixed missing user ID by extracting from user data: $userIdFromData');
            }
            return true;
          } else {
            if (kDebugMode) {
              debugPrint('❌ No valid user ID found in any expected fields');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error parsing user data to fix user ID: $e');
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('❌ Cannot fix user ID - no user data found');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in fixMissingUserId: $e');
      }
      return false;
    }
  }

  static Future<String?> _getFcmToken() async {
    try {
      return NotificationService.fcmToken ?? await NotificationService.refreshFCMToken();
    } catch (e, stack) {
      debugPrint('FCM token fetch error: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }

  /// Send OTP for password reset
  static Future<Map<String, dynamic>> sendResetPasswordOTP(String email) async {
    try {
      // Validate email
      if (email.trim().isEmpty) {
        throw ValidationException('Email is required');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
        throw ValidationException('Please enter a valid email address');
      }

      final requestData = {
        'email': email.trim(),
      };

      _logRequest('/user/sendResetPasswordOTP', requestData);

      final response = await ApiClient.patch('/user/sendResetPasswordOTP', requestData);
      _logResponse('/user/sendResetPasswordOTP', response);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'OTP sent successfully',
            'otp': responseData['otp']?['otp']?.toString() ?? '',
          };
        } else {
          throw AuthException(
            responseData['message'] ?? 'Failed to send OTP',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw AuthException(
          'Failed to send OTP: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('send reset password OTP', e);
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw TimeoutException('Connection timeout. Please check your internet connection.');
      }
      
      if (e.response?.statusCode == 404) {
        throw AuthException(
          'Email not found. Please check your email address.',
          statusCode: 404,
        );
      }
      
      throw AuthException(
        e.response?.data?['message'] ?? 'Failed to send OTP',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('send reset password OTP', e);
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Unexpected error: $e');
    }
  }

  /// Reset password with new password
  static Future<Map<String, dynamic>> resetPassword(String newPassword) async {
    try {
      // Validate password
      if (newPassword.trim().isEmpty) {
        throw ValidationException('Password is required');
      }
      if (newPassword.length < _passwordMinLength) {
        throw ValidationException('Password must be at least $_passwordMinLength characters long');
      }

      final requestData = {
        'password': newPassword.trim(),
      };

      _logRequest('/user/resetPassword', requestData);

      final response = await ApiClient.post('/user/resetPassword', requestData);
      _logResponse('/user/resetPassword', response);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Password reset successfully',
          };
        } else {
          throw AuthException(
            responseData['message'] ?? 'Failed to reset password',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw AuthException(
          'Failed to reset password: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logError('reset password', e);
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw TimeoutException('Connection timeout. Please check your internet connection.');
      }
      
      throw AuthException(
        e.response?.data?['message'] ?? 'Failed to reset password',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logError('reset password', e);
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Unexpected error: $e');
    }
  }
}
