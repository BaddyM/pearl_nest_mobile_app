// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/network/exceptions/network_exceptions.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final bool isChangePassword;
  final VoidCallback? onPasswordChangeSuccess;

  const ResetPasswordScreen({
    super.key, 
    required this.email,
    this.isChangePassword = false,
    this.onPasswordChangeSuccess,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
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
                  )),
              Text(
                'Create New Password',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.getTextColor(context),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Your new password must be different from your previous password.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryblue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
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
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your new password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                          return 'Password must contain uppercase, lowercase and number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryblue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
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
                      obscureText: !_isConfirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password must contain:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          _passwordRequirement('At least 8 characters'),
                          _passwordRequirement('One uppercase letter'),
                          _passwordRequirement('One lowercase letter'),
                          _passwordRequirement('One number'),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryblue,
                          foregroundColor: AppTheme.whiteColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppTheme.whiteColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Reset Password',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordRequirement(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await AuthService.resetPassword(_passwordController.text,widget.email);

        if (response['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: AppTheme.getBackgroundColor(context),
                  contentPadding: EdgeInsets.all(24),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryblue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 50,
                          color: AppTheme.primaryblue,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        widget.isChangePassword 
                          ? 'Password Changed Successfully!' 
                          : 'Password Reset Successful!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        widget.isChangePassword
                          ? 'Your password has been successfully changed.'
                          : 'Your password has been successfully reset. You can now sign in with your new password.',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (widget.isChangePassword) {
                              // Close the dialog first
                              Navigator.pop(context);
                              
                              // Get current user and navigate to home screen
                              try {
                                final currentUser = await AuthService.getCurrentUser();
                                if (currentUser != null && mounted) {
                                  // Navigate to HomeScreen and remove all previous routes
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeScreen(user: currentUser),
                                    ),
                                    (route) => false,
                                  );
                                  
                                  // Call the success callback
                                  widget.onPasswordChangeSuccess?.call();
                                } else {
                                  // Fallback: just pop all dialogs and screens
                                  Navigator.pop(context); // Pop ResetPasswordScreen
                                  Navigator.pop(context); // Pop VerifyCodeScreen  
                                  Navigator.pop(context); // Pop ForgotPasswordScreen
                                  widget.onPasswordChangeSuccess?.call();
                                }
                              } catch (e) {
                                // Fallback: just pop all dialogs and screens
                                Navigator.pop(context); // Pop ResetPasswordScreen
                                Navigator.pop(context); // Pop VerifyCodeScreen  
                                Navigator.pop(context); // Pop ForgotPasswordScreen
                                widget.onPasswordChangeSuccess?.call();
                              }
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryblue,
                            foregroundColor: AppTheme.whiteColor,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.isChangePassword ? 'Done' : 'Back to Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }
      } on ValidationException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
