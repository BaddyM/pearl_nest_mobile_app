// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/screens/common/verify_code_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

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
      backgroundColor: AppTheme.whiteColor,
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
                          color: AppTheme.blackColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Enter your email address and we\'ll send you a verification code to reset your password.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.greyColor,
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
                              style: TextStyle(color: AppTheme.blackColor),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(color: AppTheme.greyColor),
                                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryblue),
                                filled: true,
                                fillColor: AppTheme.lightGreyColor,
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
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => VerifyCodeScreen(email: _emailController.text),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
