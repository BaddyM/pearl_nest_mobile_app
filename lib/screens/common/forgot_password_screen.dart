// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/screens/common/verify_code_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/network/exceptions/network_exceptions.dart';
import 'package:pearlnest/utils/custom_snackbar.dart'; // Add this import

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          "assets/icon.png",
                          height: 150,
                          width: 150,
                        )
                      ),
                      Text(
                        'Reset Your Password',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.getTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Enter your email address and we\'ll send you a verification code to reset your password.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: AppTheme.getSecondaryTextColor(context),),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryblue),
                                filled: true,
                                fillColor: AppTheme.getCardColor(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryblue, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSendCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryblue,
                                  foregroundColor: AppTheme.whiteColor,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: AppTheme.whiteColor)
                                    : Text(
                                        'Send Verification Code',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryblue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleSendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await AuthService.sendResetPasswordOTP(_emailController.text);
        
        if (response['success'] == true) {
          final otp = response['otp'] as String;
          
          // Show success message
          if (mounted) {
            CustomSnackBar.showSuccess(
              context,
              response['message'] ?? 'Verification code sent successfully!',
            );
            
            // Navigate to verification screen with the OTP
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyCodeScreen(
                  email: _emailController.text,
                  serverOtp: otp,
                ),
              ),
            );
          }
        }
      } on ValidationException catch (e) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            e.message,
            onRetry: () => _handleSendCode(),
          );
        }
      } on TimeoutException catch (e) {
        if (mounted) {
          CustomSnackBar.showWarning(
            context,
            e.message,

          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            e.message,

          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            'An unexpected error occurred. Please try again.',
            onRetry: () => _handleSendCode(),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
