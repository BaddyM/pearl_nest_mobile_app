import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/screens/common/forgot_password_screen.dart';
import 'package:pearlnest/screens/common/register_screen.dart';
import 'package:pearlnest/screens/common/otp_verification_screen.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/utils/custom_snackbar.dart'; // Add this import
import 'package:pearlnest/widgets/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          CustomSnackBar.showSuccess(
            context,
            'Welcome, ${state.user.name}!',
            duration: Duration(milliseconds: 1500),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                user: state.user,
              ),
            ),
          );
        } else if (state is AuthOtpRequired) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: state.email,
                tempToken: state.tempToken,
                serverOtp: state.serverOtp,
                message: state.message,
                role: state.role,
              ),
            ),
          );
        } else if (state is AuthFailure) {
          CustomSnackBar.showError(
            context,
            state.message,
            duration: Duration(milliseconds: 2000),
            onRetry: () => _handleLogin(), // Add retry functionality
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

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
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.getTextColor(context),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to find your dream property',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: AppTheme.getTextColor(context)),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryblue),
                              filled: true,
                              fillColor: AppTheme.getCardColor(context),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
                                  width: 1,
                                ),
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
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            style: TextStyle(color: AppTheme.getTextColor(context)),
                            decoration: InputDecoration(
                              labelText: 'Password',
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
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppTheme.primaryblue),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryblue,
                                foregroundColor: AppTheme.getTextColor(context),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      'Sign In',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.whiteColor),
                                    ),
                            ),
                          ),
                          // SizedBox(height: 24),
                          // Row(
                          //   children: [
                          //     Expanded(child: Divider(color: AppTheme.getSecondaryTextColor(context))),
                          //     Padding(
                          //       padding: EdgeInsets.symmetric(horizontal: 16),
                          //       child: Text(
                          //         'OR',
                          //         style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                          //       ),
                          //     ),
                          //     Expanded(child: Divider(color: AppTheme.getSecondaryTextColor(context))),
                          //   ],
                          // ),
                          // SizedBox(height: 24),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: _socialLoginButton(
                          //         icon: Icons.g_mobiledata,
                          //         label: 'Google',
                          //         onPressed: () {
                          //           // TODO: Implement Google login
                          //         },
                          //       ),
                          //     ),
                          //     SizedBox(width: 16),
                          //     Expanded(
                          //       child: _socialLoginButton(
                          //         icon: Icons.facebook,
                          //         label: 'Facebook',
                          //         onPressed: () {
                          //           // TODO: Implement Facebook login
                          //         },
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppTheme.primaryblue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _socialLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.getTextColor(context)),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
        ],
      ),
    );
  }
}
