
import 'package:flutter/material.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/common/forgot_password_screen.dart';
import 'package:pearlnest/screens/common/register_screen.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
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
                )
              ),
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
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryblue,
                          foregroundColor: AppTheme.getTextColor(context),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: AppTheme.getTextColor(context))
                            : Text(
                                'Sign In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.whiteColor),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.getSecondaryTextColor(context))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.getSecondaryTextColor(context))),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _socialLoginButton(
                            icon: Icons.g_mobiledata,
                            label: 'Google',
                            onPressed: () {
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _socialLoginButton(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            onPressed: () {
                            },
                          ),
                        ),
                      ],
                    ),
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
        side: BorderSide(color: AppTheme.getSecondaryTextColor(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.getSecondaryTextColor(context)),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        User user;
        
        if (isLandlordCredentials(_emailController.text, _passwordController.text)) {
          user = createLandlordUser();
        } else {
          user = User(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            name: _emailController.text.split('@')[0],
            email: _emailController.text.trim(),
            phone: '+1234567890', 
            userType: UserType.tenant,
            profileImage: null,
            favoriteProperties: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.name}!', style: TextStyle(color: AppTheme.lightGreyColor),),
            backgroundColor: AppTheme.primaryblue,
            duration: Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
      }
      catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed. Please try again.', style: TextStyle(color: AppTheme.lightGreyColor),),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static bool isLandlordCredentials(String email, String password) {
    const landlordEmail = 'vawzen@gmail.com';
    const landlordPassword = 'vawzen123';
    
    return email.toLowerCase().trim() == landlordEmail && password == landlordPassword;
  }

  static User createLandlordUser() {
    return User(
      id: 'landlord_001',
      name: 'vawzen',
      email: 'vawzen@gmail.com',
      phone: '+256700123456',
      userType: UserType.landlord,
      profileImage: null,
      favoriteProperties: [],
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }
}
