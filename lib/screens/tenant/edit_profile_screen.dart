// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Notification settings
  bool _pushNotifications = true;
  bool _smsNotifications = true;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phone;
    _bioController.text = widget.user.bio ?? '';

    // Initialize notification settings
    _pushNotifications = widget.user.pushNotifications;
    _smsNotifications = widget.user.smsNotifications;
    _emailNotifications = widget.user.emailNotifications;

    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: AppTheme.whiteColor),
        actions: [
          if (_hasChanges || _selectedImage != null)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileImageSection(),
              _buildFormSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.whiteColor, width: 3),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.getCardColor(context),
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (widget.user.profileImage != null && widget.user.profileImage!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                ImageHelper.getFullImageUrl(widget.user.profileImage!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.primaryblue,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.primaryblue,
                            )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.whiteColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppTheme.primaryblue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'change profile photo',
            style: TextStyle(
              color: AppTheme.whiteColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Personal Information'),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            _buildSectionTitle('About'),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _bioController,
              label: 'Bio (Optional)',
              icon: Icons.info_outline,
              maxLines: 4,
              hintText: 'Tell us a little about yourself...',
              validator: null,
            ),
            SizedBox(height: 24),
            _buildSectionTitle('Notification Preferences'),
            SizedBox(height: 16),
            _buildNotificationSettings(),
            SizedBox(height: 24),
            _buildAccountInfoSection(),
            SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.getTextColor(context),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.getTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.primaryblue),
        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryblue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.getCardColor(context),
      ),
      validator: validator,
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildNotificationTile(
            'Push Notifications',
            'Receive notifications on your device',
            Icons.notifications,
            _pushNotifications,
            (value) => setState(() {
              _pushNotifications = value;
              _onFieldChanged();
            }),
          ),
          _buildNotificationTile(
            'SMS Notifications',
            'Receive notifications via text message',
            Icons.sms,
            _smsNotifications,
            (value) => setState(() {
              _smsNotifications = value;
              _onFieldChanged();
            }),
          ),
          _buildNotificationTile(
            'Email Notifications',
            'Receive notifications via email',
            Icons.email,
            _emailNotifications,
            (value) => setState(() {
              _emailNotifications = value;
              _onFieldChanged();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryblue,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryblue,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.greyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 12),
          _buildReadOnlyInfoRow(
            'Account Type',
            _getUserTypeString(widget.user.userType),
            Icons.account_circle,
          ),
          SizedBox(height: 8),
          _buildReadOnlyInfoRow(
            'Member Since',
            '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
            Icons.calendar_today,
          ),
          if (widget.user.isVerified) ...[
            SizedBox(height: 8),
            _buildReadOnlyInfoRow(
              'Verification Status',
              'Verified',
              Icons.verified,
              valueColor: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.getSecondaryTextColor(context)),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_hasChanges || _selectedImage != null) && !_isLoading ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryblue,
          foregroundColor: AppTheme.whiteColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePickerOption(
                      Icons.camera_alt,
                      'Camera',
                      () => _pickImage(ImageSource.camera),
                    ),
                    _buildImagePickerOption(
                      Icons.photo_library,
                      'Gallery',
                      () => _pickImage(ImageSource.gallery),
                    ),
                    if (widget.user.profileImage != null || _selectedImage != null)
                      _buildImagePickerOption(
                        Icons.delete,
                        'Remove',
                        _removeImage,
                        isDestructive: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.withOpacity(0.1) : AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : AppTheme.primaryblue,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDestructive ? Colors.red : AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasChanges = true;
        });
      }
    } catch (e, stackTrace) {
      //debugPrint('Image picker error: $e');
      //debugPrint('Stack trace: $stackTrace');
      _showErrorDialog('Error picking image: $e');
    }
  }

  void _removeImage() {
    Navigator.pop(context);
    setState(() {
      _selectedImage = null;
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      //debugPrint('🔧 EditProfileScreen: Starting profile update...');

      // Call the AuthService to update profile
      final result = await AuthService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        imagePath: _selectedImage?.path,
        pushNotifications: _pushNotifications,
        smsNotifications: _smsNotifications,
        emailNotifications: _emailNotifications,
      );

      //debugPrint('🔧 EditProfileScreen: Profile update result: ${result['success']}');

      if (result['success'] == true) {
        // Trigger AuthBloc to refresh the user state with updated data
        if (mounted) {
          context.read<AuthBloc>().add(AuthCheckSessionRequested());
        }

        _showSuccessSnackBar(result['message'] ?? 'Profile updated successfully!');

        setState(() {
          _hasChanges = false;
          _isLoading = false;
          _selectedImage = null; // Clear selected image after successful update
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to update profile. Please try again.');
      }
    } catch (e, stackTrace) {
      //debugPrint('🔧 EditProfileScreen: Profile update error: $e');
      //debugPrint('🔧 EditProfileScreen: Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to update profile. Please try again.');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getBackgroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getUserTypeString(UserType userType) {
    switch (userType) {
      case UserType.tenant:
        return 'Tenant';
      case UserType.landlord:
        return 'Landlord';
      case UserType.admin:
        return 'Admin';
    }
  }
}
