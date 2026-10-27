// Events that can be sent to AuthBloc
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String userType;

  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.userType = 'TENANT',
  });
}

class AuthTokenExpired extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final Map<String, dynamic> updates;

  AuthProfileUpdateRequested({required this.updates});
}

class AuthCheckSessionRequested extends AuthEvent {}

class AuthOtpVerificationRequested extends AuthEvent {
  final String email;
  final String userInputOtp;
  final String serverOtp;
  final String tempToken;
  final String? role;

  AuthOtpVerificationRequested({
    required this.email,
    required this.userInputOtp,
    required this.serverOtp,
    required this.tempToken,
    this.role,
  });
}

class AuthOtpResendRequested extends AuthEvent {
  final String email;
  final String tempToken;

  AuthOtpResendRequested({
    required this.email,
    required this.tempToken,
  });
}
