// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/common/complete_registration_screen.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/screens/tenant/privacy_policy_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  final UserType _selectedUserType = UserType.tenant;

  // Auto-validation flags
  bool _nameAutoValidate = false;
  bool _emailAutoValidate = false;
  bool _passwordAutoValidate = false;
  bool _confirmPasswordAutoValidate = false;

  @override
  void initState() {
    super.initState();

    // Add listeners to start validation once user starts typing
    _nameController.addListener(() {
      if (!_nameAutoValidate && _nameController.text.isNotEmpty) {
        setState(() {
          _nameAutoValidate = true;
        });
      }
    });

    _emailController.addListener(() {
      if (!_emailAutoValidate && _emailController.text.isNotEmpty) {
        setState(() {
          _emailAutoValidate = true;
        });
      }
    });

    _passwordController.addListener(() {
      if (!_passwordAutoValidate && _passwordController.text.isNotEmpty) {
        setState(() {
          _passwordAutoValidate = true;
        });
      }
    });

    _confirmPasswordController.addListener(() {
      if (!_confirmPasswordAutoValidate && _confirmPasswordController.text.isNotEmpty) {
        setState(() {
          _confirmPasswordAutoValidate = true;
        });
      }
    });
  }

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
                width: double.maxFinite,
                alignment: Alignment.centerLeft,
                child: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 20, child: BackButton()),
              ),
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    "assets/icon.png",
                    height: 150,
                    width: 150,
                  )),
              Text(
                'Join PearlNest',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.getTextColor(context),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Create your account to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryblue),
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      autovalidateMode: _nameAutoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      autovalidateMode: _emailAutoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                      onChanged: (value) {
                        // Convert to lowercase to prevent capital letters
                        if (value != value.toLowerCase()) {
                          final selection = _emailController.selection;
                          _emailController.value = _emailController.value.copyWith(
                            text: value.toLowerCase(),
                            selection: selection,
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        if (value != value.toLowerCase()) {
                          return 'Email should be in lowercase';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      autovalidateMode: _passwordAutoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                          return 'Password must contain letters and numbers';
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
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      autovalidateMode: _confirmPasswordAutoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryblue,
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return AppTheme.getSecondaryTextColor(context).withOpacity(0.3);
                              }
                              if (states.contains(MaterialState.selected)) {
                                return AppTheme.primaryblue;
                              }
                              return AppTheme.getCardColor(context);
                            }),
                            side: BorderSide(
                              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                              width: 2,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 14),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AppTheme.primaryblue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                                        );
                                      },
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.primaryblue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_agreeToTerms && !_isLoading) ? _handleRegister : null,
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
                                'Create Account',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text(
                            'Sign In',
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
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => CompleteRegistrationScreen(
            name: _nameController.text,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            userType: _selectedUserType,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
