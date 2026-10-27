import 'package:flutter/material.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/models/user.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _token;
  bool _isLoading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuth();
    // Set up automatic logout callback
    ApiClient.onTokenExpired = _handleTokenExpired;
  }

  // Handle automatic logout when token expires
  void _handleTokenExpired() {
    //debugPrint('Token expired - automatic logout triggered');
    _clearSessionSilently();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      // Check if session is valid (local check only)
      if (await AuthService.isSessionValid()) {
        final user = await AuthService.getCurrentUser();
        final token = await AuthService.getCurrentToken();

        if (user != null && token != null) {
          // Use locally stored data without backend validation
          _token = token;
          _user = user;
          _status = AuthStatus.authenticated;

          // Set token in ApiClient for future requests
          ApiClient.setAuthToken(_token);
        } else {
          await _clearSession();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e, stackTrace) {
      //debugPrint('Auth initialization error: $e');
      //debugPrint('Stack trace: $stackTrace');
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await AuthService.login(email, password);

      if (result['success'] == true) {
        _user = result['user'];
        _token = result['token'];

        // Set token in ApiClient for future requests
        ApiClient.setAuthToken(_token);

        // Update status and notify listeners with post-frame callback
        _status = AuthStatus.authenticated;

        //debugPrint('AuthProvider: Login successful, setting status to authenticated');
        //debugPrint('AuthProvider: User: ${_user?.name}');
        //debugPrint('AuthProvider: Status: $_status');
        //debugPrint('AuthProvider: About to notify listeners');

        // Use post-frame callback to ensure UI is ready for navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
          //debugPrint('AuthProvider: Listeners notified via post-frame callback');
        });

        // Also notify immediately for synchronous checks
        notifyListeners();
        //debugPrint('AuthProvider: Immediate notification sent');

        return {
          'success': true,
          'message': result['message'] ?? 'Login successful',
        };
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return result;
      }
    } catch (e, stackTrace) {
      //debugPrint('Login error: $e');
      //debugPrint('Stack trace: $stackTrace');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'code': 'NETWORK_ERROR',
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String userType = 'TENANT',
  }) async {
    _setLoading(true);
    try {
      final result = await AuthService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        userType: userType,
      );

      if (result['success'] == true) {
        // Check if auto-login is possible (token provided)
        if (result['token'] != null) {
          _user = result['user'];
          _token = result['token'];
          _status = AuthStatus.authenticated;

          // Set token in ApiClient for future requests
          ApiClient.setAuthToken(_token);

          notifyListeners();
        }
        return result;
      } else {
        return result;
      }
    } catch (e, stackTrace) {
      //debugPrint('Registration error: $e');
      //debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'code': 'NETWORK_ERROR',
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    _setLoading(true);
    try {
      final result = await AuthService.logout();
      await _clearSession();
      return result;
    } catch (e, stackTrace) {
      //debugPrint('Logout error: $e');
      //debugPrint('Stack trace: $stackTrace');
      await _clearSession();
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshToken() async {
    if (_token == null) return;

    try {
      final result = await AuthService.refreshToken(_token!);
      if (result['success'] == true) {
        _token = result['token'];
        if (result['user'] != null) {
          _user = result['user'];
        }

        // Set new token in ApiClient
        ApiClient.setAuthToken(_token);

        notifyListeners();
      } else {
        // Token refresh failed, logout user
        await logout();
      }
    } catch (e, stackTrace) {
      //debugPrint('Token refresh error: $e');
      //debugPrint('Stack trace: $stackTrace');
      await logout();
    }
  }

  Future<void> updateUser(User updatedUser) async {
    _user = updatedUser;
    await AuthService.saveUserData(updatedUser);
    notifyListeners();
  }

  // Refresh user data from storage
  Future<void> refreshUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      //debugPrint('Failed to refresh user data: $e');
      //debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _clearSession() async {
    try {
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;

      // Clear token from ApiClient
      ApiClient.setAuthToken(null);

      notifyListeners();
    } catch (e, stackTrace) {
      //debugPrint('Clear session error: $e');
      //debugPrint('Stack trace: $stackTrace');
    }
  }

  // Silent session clear (no UI notification)
  Future<void> _clearSessionSilently() async {
    try {
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;

      // Clear token from ApiClient
      ApiClient.setAuthToken(null);

      notifyListeners();
    } catch (e, stackTrace) {
      //debugPrint('Clear session silently error: $e');
      //debugPrint('Stack trace: $stackTrace');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Check if token needs refresh (call this periodically)
  Future<void> checkTokenExpiry() async {
    if (_token == null) return;

    try {
      // Check if token is expired locally
      if (await AuthService.isTokenExpired()) {
        await refreshToken();
      }
    } catch (e, stackTrace) {
      //debugPrint('Token expiry check error: $e');
      //debugPrint('Stack trace: $stackTrace');
    }
  }

  // Check if token exists locally (no backend validation)
  Future<bool> validateCurrentToken() async {
    if (_token == null) return false;

    try {
      // Just check if we have a token locally - trust it's valid
      // If the token is actually invalid, API calls will fail and handle the error
      final storedToken = await AuthService.getCurrentToken();
      if (storedToken != null && _token == storedToken) {
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e, stackTrace) {
      //debugPrint('Token check error: $e');
      //debugPrint('Stack trace: $stackTrace');
      await logout();
      return false;
    }
  }
}
