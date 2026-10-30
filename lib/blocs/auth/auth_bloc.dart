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
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);
    on<AuthOtpResendRequested>(_onOtpResendRequested);
    on<AuthRegistrationOtpRequested>(_onRegistrationOtpRequested);
    on<AuthRegistrationOtpResendRequested>(_onRegistrationOtpResendRequested);

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
      final result = await AuthService.login(event.email, event.password);

      //debugPrint('AuthBloc: Login result received: $result');
      if (result['success'] == true) {
        //for app review process. remove afterwards
        if (event.email == "arnoldhenry958@gmail.com" || event.email == "bulyeraliarnold@gmail.com") {
          final adminResult = await AuthService.verifyOtp(event.email, 'gid2023', '000000', result['tempToken']);
          //debugPrint('AuthBloc: Admin login result received: $adminResult');
          _currentUser = adminResult['user'];
          //debugPrint('AuthBloc: Current user set: $_currentUser');
          _currentToken = adminResult['token'];

          // Set token in ApiClient
          ApiClient.setAuthToken(_currentToken);
          emit(AuthSuccess(user: adminResult['user'], token: adminResult['token']));
          return; // Add this return to prevent continuing to regular login flow
        } else {
          // Check if OTP verification is required
          if (result['requiresOtp'] == true) {
            emit(AuthOtpRequired(
              email: result['email'] ?? event.email,
              tempToken: result['tempToken'] ?? '',
              message: result['message'] ?? 'Please verify your login with the OTP code',
              serverOtp: result['otp']?.toString() ?? '',
              role: result["role"],
            ));
            return;
          }
        }

        _currentUser = result['user'];
        //debugPrint('AuthBloc: Current user set: $_currentUser');
        _currentToken = result['token'];

        // Set token in ApiClient
        ApiClient.setAuthToken(_currentToken);
        emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
      } else {
        // Use the actual error message from the service instead of generic message
        final errorMessage = result['message'] ?? 'Login failed. Please try again.';

        ////debugPrint('AuthBloc: Login failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      print("Error:Bloc = $e");
      print("Location:Bloc = $stackTrace");
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
      //Logout from Backend
      final response = await ApiClient.get("/user/logout");

      if (response.statusCode == 200) {
        // Clear local session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
        await prefs.remove('last_login');
        await prefs.remove('token_expiry');
        await prefs.remove('user_id');
        await prefs.remove('role');
        _currentUser = null;
        _currentToken = null;
        ApiClient.setAuthToken(null);
        emit(AuthLogOut());
      }
    } catch (e) {
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
      //debugPrint('AuthBloc: Processing registration request for ${event.email}');

      final result = await AuthService.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
        userType: event.userType,
        acceptedTermsAndPrivacyPolicy: event.acceptedTermsAndPrivacyPolicy,
      );

      if (result['success'] == true) {
        if (result['requiresVerification'] == true) {
          emit(AuthRegistrationSuccess(
            message: result['message'] ?? 'Enter the verification code sent to your email.',
            email: event.email,
          ));
          return;
        }

        // Check if auto-login is possible
        if (result['token'] != null) {
          _currentUser = result['user'];
          _currentToken = result['token'];
          ApiClient.setAuthToken(_currentToken);

          //debugPrint('AuthBloc: Registration successful with auto-login');
          emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
        } else {
          //debugPrint('AuthBloc: Registration successful, manual login required');
          emit(AuthUnauthenticated());
        }
      } else {
        // Use the actual error message from the service
        final errorMessage = result['message'] ?? 'Registration failed. Please try again.';
        //debugPrint('AuthBloc: Registration failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      //debugPrint('AuthBloc: Registration error - $e');
      //debugPrint('AuthBloc: Stack trace - $stackTrace');

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
    //debugPrint('AuthBloc: Token expired, clearing session');

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
      await prefs.remove('role');
    } catch (e) {
      //debugPrint('AuthBloc: Error clearing session data - $e');
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
      //debugPrint('AuthBloc: Processing profile update request');

      final result = await AuthService.updateProfile(
        name: event.updates['name'] ?? _currentUser!.name,
        email: event.updates['email'] ?? _currentUser!.email,
        phone: event.updates['phone'] ?? _currentUser!.phone,
        bio: event.updates['bio'],
        imagePath: event.updates['imagePath'],
        pushNotifications: event.updates['pushNotifications'],
        smsNotifications: event.updates['smsNotifications'],
        emailNotifications: event.updates['emailNotifications'],
      );

      if (result['success'] == true) {
        _currentUser = result['user'];

        //debugPrint('AuthBloc: Profile updated successfully');
        emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
      } else {
        // Use the actual error message from the service
        final errorMessage = result['message'] ?? 'Profile update failed. Please try again.';
        //debugPrint('AuthBloc: Profile update failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      //debugPrint('AuthBloc: Profile update error - $e');
      //debugPrint('AuthBloc: Stack trace - $stackTrace');

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
      if (await AuthService.isSessionValid()) {
        final token = await AuthService.getCurrentToken();

        if (token != null) {
          // First try to get fresh user data from server
          final freshUser = await AuthService.refreshUserProfile();

          if (freshUser != null) {
            // Use fresh data from server
            _currentUser = freshUser;
            _currentToken = token;
            ApiClient.setAuthToken(_currentToken);
            emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
          } else {
            // Fallback to cached user data if server refresh fails
            final cachedUser = await AuthService.getCurrentUser();

            if (cachedUser != null) {
              _currentUser = cachedUser;
              _currentToken = token;
              ApiClient.setAuthToken(_currentToken);
              emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
            } else {
              emit(AuthUnauthenticated());
            }
          }
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onOtpVerificationRequested(
    AuthOtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthOtpVerificationLoading());

    try {
      final result = await AuthService.verifyOtp(event.email, event.userInputOtp, event.serverOtp, event.tempToken);

      if (result['success'] == true) {
        _currentUser = result['user'];
        _currentToken = result['token'];

        //print("Role = ${event.role}");

        // Set token in ApiClient
        ApiClient.setAuthToken(_currentToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', event.role.toString());

        emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
      } else {
        //debugPrint('AuthBloc: OTP verification error message - ${result['message']}');
        final errorMessage = result['message'] ?? 'OTP verification failed. Please try again.';
        //debugPrint('AuthBloc: OTP verification failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      // Provide more specific error messages based on error type
      String errorMessage;
      if (e.toString().contains('Invalid OTP') || e.toString().contains('INVALID_OTP')) {
        errorMessage = 'Invalid OTP. Please check the code and try again.';
      } else if (e.toString().contains('expired')) {
        errorMessage = 'OTP has expired. Please request a new one.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'OTP verification failed. Please try again.';
      }

      emit(AuthFailure(message: errorMessage));
    }
  }

  Future<void> _onOtpResendRequested(
    AuthOtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthOtpVerificationLoading());

    try {
      final result = await AuthService.resendOtp(event.email, event.tempToken);

      if (result['success'] == true) {
        //debugPrint('AuthBloc: OTP resend successful');

        // Return to OTP required state with updated message
        emit(AuthOtpRequired(
          email: event.email,
          tempToken: event.tempToken,
          message: result['message'] ?? 'A new OTP has been generated',
          serverOtp: result['otp']?.toString() ?? '', // Include new OTP if provided
        ));
      } else {
        //debugPrint('AuthBloc: OTP resend error message - ${result['message']}');
        final errorMessage = result['message'] ?? 'Failed to resend OTP. Please try again.';
        //debugPrint('AuthBloc: OTP resend failed - $errorMessage');
        emit(AuthFailure(message: errorMessage));
      }
    } catch (e, stackTrace) {
      // Provide more specific error messages based on error type
      String errorMessage;
      if (e.toString().contains('Too many requests') || e.toString().contains('TOO_MANY_REQUESTS')) {
        errorMessage = 'Too many requests. Please wait before requesting another OTP.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to resend OTP. Please try again.';
      }

      emit(AuthFailure(message: errorMessage));
    }

    Future<void> _onRegistrationOtpRequested(
      AuthRegistrationOtpRequested event,
      Emitter<AuthState> emit,
    ) async {
      emit(AuthOtpVerificationLoading());
      try {
        final result = await AuthService.verifyRegistrationOtp(event.email, event.otp);
        if (result['success'] == true) {
          _currentUser = result['user'];
          _currentToken = result['token'];
          ApiClient.setAuthToken(_currentToken);
          emit(AuthSuccess(user: _currentUser!, token: _currentToken!));
        } else {
          emit(AuthFailure(
            message: result['message'] ?? 'That code could not be verified. Please try again.',
          ));
        }
      } catch (error) {
        emit(AuthFailure(message: error.toString()));
      }
    }

    Future<void> _onRegistrationOtpResendRequested(
      AuthRegistrationOtpResendRequested event,
      Emitter<AuthState> emit,
    ) async {
      emit(AuthOtpVerificationLoading());
      try {
        final result = await AuthService.resendRegistrationOtp(event.email);
        if (result['success'] == true) {
          emit(AuthRegistrationSuccess(
            message: result['message'] ?? 'A new verification code has been sent.',
            email: event.email,
          ));
        } else {
          emit(AuthFailure(
            message: result['message'] ?? 'Could not resend the verification code.',
          ));
        }
      } catch (error) {
        emit(AuthFailure(message: error.toString()));
      }
    }
  }
}
