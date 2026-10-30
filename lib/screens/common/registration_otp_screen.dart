import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class RegistrationOtpScreen extends StatefulWidget {
  final String email;

  const RegistrationOtpScreen({super.key, required this.email});

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds > 0) setState(() => _resendSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      CustomSnackBar.showWarning(context, 'Enter the six-digit code from your email.');
      return;
    }
    context.read<AuthBloc>().add(
          AuthRegistrationOtpRequested(email: widget.email, otp: otp),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(user: state.user)),
            (route) => false,
          );
        } else if (state is AuthFailure) {
          CustomSnackBar.showError(context, state.message);
        } else if (state is AuthRegistrationSuccess) {
          _otpController.clear();
          CustomSnackBar.showSuccess(context, state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthOtpVerificationLoading;
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            appBar: AppBar(
              backgroundColor: AppTheme.getBackgroundColor(context),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(context)),
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/icon.png', height: 110),
                        const SizedBox(height: 24),
                        Text(
                          'Verify your email',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter the six-digit code we sent to ${widget.email}. This confirms you can access this email address.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _otpController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onSubmitted: (_) => _verify(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                letterSpacing: 12,
                                color: AppTheme.getTextColor(context),
                              ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '------',
                            filled: true,
                            fillColor: AppTheme.getCardColor(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: isLoading ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryblue,
                            foregroundColor: AppTheme.whiteColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify and continue'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: isLoading || _resendSeconds > 0
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                        AuthRegistrationOtpResendRequested(
                                          email: widget.email,
                                        ),
                                      );
                                  setState(() => _resendSeconds = 60);
                                },
                          child: Text(
                            _resendSeconds > 0
                                ? 'Resend code in $_resendSeconds seconds'
                                : 'Resend verification code',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
