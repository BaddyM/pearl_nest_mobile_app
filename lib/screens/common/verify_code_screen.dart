import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pearlnest/screens/common/reset_password_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  // ignore: library_private_types_in_public_api
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.whiteColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                        'Enter Verification Code',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.blackColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: AppTheme.greyColor, fontSize: 16),
                          children: [
                            TextSpan(text: 'We\'ve sent a 6-digit verification code to\n'),
                            TextSpan(
                              text: widget.email,
                              style: TextStyle(
                                color: AppTheme.blackColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 50,
                            height: 60,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.blackColor,
                              ),
                              decoration: InputDecoration(
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerifyCode,
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
                                  'Verify Code',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(color: AppTheme.greyColor),
                          ),
                          TextButton(
                            onPressed: _canResend ? _handleResendCode : null,
                            child: Text(
                              _canResend ? 'Resend' : 'Resend in ${_resendTimer}s',
                              style: TextStyle(
                                color: _canResend ? AppTheme.primaryblue : AppTheme.greyColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  void _handleVerifyCode() async {
    String code = _controllers.map((controller) => controller.text).join();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete 6-digit code', style: TextStyle(color: AppTheme.lightGreyColor),),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

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
        builder: (context) => ResetPasswordScreen(email: widget.email),
      ),
    );
  }

  void _handleResendCode() async {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });
    
    _startResendTimer();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code sent successfully!', style: TextStyle(color: AppTheme.lightGreyColor),),
        backgroundColor: AppTheme.primaryblue,
        duration: Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
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
}
