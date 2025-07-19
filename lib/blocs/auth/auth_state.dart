import 'package:equatable/equatable.dart';
import 'package:pearlnest/models/user.dart';

// States that AuthBloc can emit
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthInitializing extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  final String token;
  
  const AuthSuccess({required this.user, required this.token});
  
  @override
  List<Object?> get props => [user, token];
}

class AuthFailure extends AuthState {
  final String message;
  final String? code;
  
  const AuthFailure({required this.message, this.code});
  
  @override
  List<Object?> get props => [message, code];
}

class AuthUnauthenticated extends AuthState {}

class AuthOtpRequired extends AuthState {
  final String email;
  final String tempToken;
  final String message;
  final String serverOtp; // The OTP code from server response for client-side verification
  
  const AuthOtpRequired({
    required this.email,
    required this.tempToken,
    required this.message,
    required this.serverOtp,
  });
  
  @override
  List<Object?> get props => [email, tempToken, message, serverOtp];
}

class AuthOtpVerificationLoading extends AuthState {}

class AuthRegistrationSuccess extends AuthState {
  final String message;
  final String email;
  
  const AuthRegistrationSuccess({required this.message, required this.email});
  
  @override
  List<Object?> get props => [message, email];
}

class AuthProfileUpdated extends AuthState {
  final User user;
  
  const AuthProfileUpdated({required this.user});
  
  @override
  List<Object?> get props => [user];
}
