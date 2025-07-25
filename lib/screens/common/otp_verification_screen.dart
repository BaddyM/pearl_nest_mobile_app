import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/utils/custom_snackbar.dart'; // Add this import

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String tempToken;
  final String message;
  final String serverOtp; // The OTP code from server for client-side verification

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.tempToken,
    required this.message,
    required this.serverOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late List<TextEditingController> _controllers;

  late List<FocusNode> _focusNodes;


  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  _focusNodes = List.generate(widget.serverOtp.length, (index) => FocusNode());
    _controllers = List.generate(widget.serverOtp.length, (index) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        if (_resendCountdown > 0) {
          _startResendTimer();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < widget.serverOtp.length-1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit when all fields are filled
    if (_isOtpComplete()) {
      _verifyOtp();
    }
  }

  bool _isOtpComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getOtpCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _verifyOtp() {
    if (_isOtpComplete()) {
      final userInputOtp = _getOtpCode();
      context.read<AuthBloc>().add(
        AuthOtpVerificationRequested(
          email: widget.email,
          userInputOtp: userInputOtp,
          serverOtp: widget.serverOtp,
          tempToken: widget.tempToken,
        ),
      );
    } else {
      CustomSnackBar.showWarning(
        context,
        'Please enter the complete OTP',
      );
    }
  }

  void _resendOtp() {
    if (_canResend) {
      // For client-side verification, we just show a message that the code hasn't changed
      CustomSnackBar.showInfo(
        context,
        'The OTP code is still valid. Please check your email again.',
        duration: Duration(milliseconds: 2000),
      );
      _startResendTimer();
    }
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '${username}***@$domain';
    } else {
      final firstChar = username[0];
      final lastChar = username[username.length - 1];
      final maskedUsername = '$firstChar${'*' * (username.length - 2)}$lastChar';
      return '$maskedUsername@$domain';
    }
  }

  void _autofillOtp(String otp) {
    // Clear existing values first
    _clearOtp();
    
    // Fill each digit into the corresponding controller
    for (int i = 0; i < otp.length && i < _controllers.length; i++) {
      _controllers[i].text = otp[i];
    }
    
    // Focus on the last filled field
    int lastIndex = (otp.length - 1).clamp(0, _focusNodes.length - 1);
    _focusNodes[lastIndex].requestFocus();
    
    // Auto-submit if OTP is complete
    if (_isOtpComplete()) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          CustomSnackBar.showSuccess(
            context,
            'Email verified successfully! Welcome, ${state.user.name}!',
            duration: Duration(milliseconds: 1500),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(user: state.user)),
            (route) => false,
          );
        } else if (state is AuthFailure) {
          CustomSnackBar.showError(
            context,
            state.message,
            duration: Duration(milliseconds: 2000),
            onRetry: () => _verifyOtp(),
          );
          // Clear OTP fields on error
          _clearOtp();
        } else if (state is AuthOtpRequired) {
          // Show success message for resend
          if (state.message.toLowerCase().contains('resent') || state.message.toLowerCase().contains('new otp')) {
            CustomSnackBar.showSuccess(
              context,
              state.message,
              duration: Duration(milliseconds: 2000),
            );
          }
          _clearOtp();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthOtpVerificationLoading;

          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    // Back button and title
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Email Verification',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.getTextColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    SizedBox(height: 40),
                    // Email icon
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryblue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 60,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                    SizedBox(height: 32),
                    // Title and description
                    Text(
                      'Verify Your Email',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.getTextColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'We\'ve sent a verification code to',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _maskEmail(widget.email),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryblue,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter the ${widget.serverOtp.length}-digit code from your email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 40),
                    // OTP input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(widget.serverOtp.length, (index) {
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _controllers[index].text.isNotEmpty
                                  ? AppTheme.primaryblue
                                  : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.getCardColor(context),
                          ),
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            style: TextStyle(
                              color: AppTheme.getTextColor(context),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onOtpChanged(value, index),
                            onTap: () {
                              // Clear the field when tapped to allow easy editing
                              _controllers[index].selection = TextSelection.fromPosition(
                                TextPosition(offset: _controllers[index].text.length),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 40),
                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryblue,
                          foregroundColor: AppTheme.whiteColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                                ),
                              )
                            : Text(
                                'Verify Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Resend OTP section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                        ),
                        TextButton(
                          onPressed: _canResend && !isLoading ? _resendOtp : null,
                          child: Text(
                            _canResend ? 'Resend OTP' : 'Resend in ${_resendCountdown}s',
                            style: TextStyle(
                              color: _canResend && !isLoading
                                  ? AppTheme.primaryblue
                                  : AppTheme.getSecondaryTextColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Clear button
                    TextButton(
                      onPressed: isLoading ? null : _clearOtp,
                      child: Text(
                        'Clear Code',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    // Help text
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Check your spam folder if you don\'t see the email. The code will expire in 10 minutes.',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
