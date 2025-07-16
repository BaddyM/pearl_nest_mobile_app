import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/models/user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  User? _currentUser;
  String? _currentToken;
  
  User? get currentUser => _currentUser;
  String? get currentToken => _currentToken;
  bool get isAuthenticated => _currentUser != null && _currentToken != null;

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthTokenExpired>(_onTokenExpired);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthCheckSessionRequested>(_onCheckSessionRequested);
    
    // Initialize session check
    add(AuthCheckSessionRequested());
    
    // Set up automatic logout callback
    ApiClient.onTokenExpired = () {
      add(AuthTokenExpired());
    };
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      debugPrint('AuthBloc: Processing login request for ${event.email}');
      
      final result = await AuthService.login(event.email, event.password);
      
      debugPrint('AuthBloc: Login result received: ${result.keys}');
      debugPrint('AuthBloc: Success flag: ${result['success']}');
      debugPrint('AuthBloc: User present: ${result['user'] != null}');
      debugPrint('AuthBloc: Token present: ${result['token'] != null}');
      
      if (result['success'] == true) {
        _currentUser = result['user'];
        _currentToken = result['token'];
        
        // Set token in ApiClient
        ApiClient.setAuthToken(_currentToken);
        
        debugPrint('AuthBloc: Login successful, user: ${_currentUser?.name}');
        debugPrint('AuthBloc: About to emit AuthSuccess state');
        
        emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
        
        debugPrint('AuthBloc: AuthSuccess state emitted');
      } else {
        debugPrint('AuthBloc: Login error message - ${result['message']}');
        debugPrint('Error result: $result');
        // Use the actual error message from the service instead of generic message
        final errorMessage = result['message'] ?? 'Login failed. Please try again.';
        debugPrint('AuthBloc: Login failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      debugPrint('AuthBloc: Login error - $e');
      debugPrint('AuthBloc: Stack trace - $stackTrace');
      
      // Provide more specific error messages based on error type
      String errorMessage;
      if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('No address associated with hostname')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      } else {
        errorMessage = 'Login failed. Please try again.';
      }
      
      emit(AuthFailure(message: errorMessage));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      debugPrint('AuthBloc: Processing logout request');
      
      // Clear local session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('last_login');
      await prefs.remove('token_expiry');
      
      _currentUser = null;
      _currentToken = null;
      ApiClient.setAuthToken(null);
      
      debugPrint('AuthBloc: Logout successful');
      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint('AuthBloc: Logout error - $e');
      // Even if logout fails, clear local state
      _currentUser = null;
      _currentToken = null;
      ApiClient.setAuthToken(null);
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      debugPrint('AuthBloc: Processing registration request for ${event.email}');
      
      final result = await AuthService.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
        userType: event.userType,
      );
      
      if (result['success'] == true) {
        // Check if auto-login is possible
        if (result['token'] != null) {
          _currentUser = result['user'];
          _currentToken = result['token'];
          ApiClient.setAuthToken(_currentToken);
          
          debugPrint('AuthBloc: Registration successful with auto-login');
          emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
        } else {
          debugPrint('AuthBloc: Registration successful, manual login required');
          emit(AuthUnauthenticated());
        }
      } else {
        // Use the actual error message from the service
        final errorMessage = result['message'] ?? 'Registration failed. Please try again.';
        debugPrint('AuthBloc: Registration failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      debugPrint('AuthBloc: Registration error - $e');
      debugPrint('AuthBloc: Stack trace - $stackTrace');
      
      // Provide more specific error messages based on error type
      String errorMessage;
      if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('No address associated with hostname')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      } else {
        errorMessage = 'Registration failed. Please try again.';
      }
      
      emit(AuthFailure(message: errorMessage));
    }
  }

  Future<void> _onTokenExpired(
    AuthTokenExpired event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('AuthBloc: Token expired, clearing session');
    
    _currentUser = null;
    _currentToken = null;
    ApiClient.setAuthToken(null);
    
    // Clear stored session data manually
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('last_login');
      await prefs.remove('token_expiry');
    } catch (e) {
      debugPrint('AuthBloc: Error clearing session data - $e');
    }
    
    emit(AuthUnauthenticated());
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser == null) {
      emit(AuthFailure(message: 'User not authenticated'));
      return;
    }
    
    emit(AuthLoading());
    
    try {
      debugPrint('AuthBloc: Processing profile update request');
      
      final result = await AuthService.updateProfile(
        name: event.updates['name'] ?? _currentUser!.name,
        email: event.updates['email'] ?? _currentUser!.email,
        phone: event.updates['phone'] ?? _currentUser!.phone,
        bio: event.updates['bio'],
        profilePicture: event.updates['profilePicture'],
        pushNotifications: event.updates['pushNotifications'],
        smsNotifications: event.updates['smsNotifications'],
        emailNotifications: event.updates['emailNotifications'],
      );
      
      if (result['success'] == true) {
        _currentUser = result['user'];
        
        debugPrint('AuthBloc: Profile updated successfully');
        emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
      } else {
        // Use the actual error message from the service
        final errorMessage = result['message'] ?? 'Profile update failed. Please try again.';
        debugPrint('AuthBloc: Profile update failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      debugPrint('AuthBloc: Profile update error - $e');
      debugPrint('AuthBloc: Stack trace - $stackTrace');
      
      // Provide more specific error messages based on error type
      String errorMessage;
      if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('No address associated with hostname')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      } else {
        errorMessage = 'Profile update failed. Please try again.';
      }
      
      emit(AuthFailure(message: errorMessage));
    }
  }

  Future<void> _onCheckSessionRequested(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthInitializing());
    
    try {
      debugPrint('AuthBloc: Checking session validity');
      
      if (await AuthService.isSessionValid()) {
        final user = await AuthService.getCurrentUser();
        final token = await AuthService.getCurrentToken();
        
        if (user != null && token != null) {
          _currentUser = user;
          _currentToken = token;
          ApiClient.setAuthToken(_currentToken);
          
          debugPrint('AuthBloc: Session valid, user: ${_currentUser?.name}');
          emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
        } else {
          debugPrint('AuthBloc: Session invalid, missing user or token');
          emit(AuthUnauthenticated());
        }
      } else {
        debugPrint('AuthBloc: Session invalid');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('AuthBloc: Session check error - $e');
      emit(AuthUnauthenticated());
    }
  }
}
