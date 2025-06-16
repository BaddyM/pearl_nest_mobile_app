import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class CompleteRegistrationScreen extends StatefulWidget {
  final String name;
  final String password;
  final UserType userType;

  const CompleteRegistrationScreen({
    super.key,
    required this.name,
    required this.password,
    required this.userType,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CompleteRegistrationScreenState createState() => _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _profileImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.whiteColor,
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
                'Complete Your Profile',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.blackColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Add your details to finish registration',
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreyColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryblue,
                            width: 2,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppTheme.primaryblue,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      color: AppTheme.primaryblue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: AppTheme.blackColor),
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: AppTheme.blackColor),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: AppTheme.greyColor),
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryblue),
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
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCompleteRegistration,
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
                                'Complete Registration',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppTheme.primaryblue),
                title: Text('Photo Library'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: AppTheme.primaryblue),
                title: Text('Camera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _handleCompleteRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully! Please sign in.', style: TextStyle(color: AppTheme.lightGreyColor),),
          backgroundColor: AppTheme.primaryblue,
            duration: Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
        ),
      );

      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
