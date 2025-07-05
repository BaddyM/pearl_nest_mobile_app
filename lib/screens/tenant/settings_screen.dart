// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/theme_provider.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/tenant/contact_developer_screen.dart';
import 'package:pearlnest/screens/tenant/edit_profile_screen.dart';
import 'package:pearlnest/screens/tenant/help_and_support_screen.dart';
import 'package:pearlnest/screens/tenant/privacy_policy_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({
    super.key,
    required this.user,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _bioEnabled = false;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSettingsHeader(),
              _buildAccountSection(),
              _buildNotificationSection(),
              _buildAppearanceSection(themeProvider),
              _buildPrivacySection(),
              _buildSupportSection(),
              _buildAboutSection(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsHeader() {
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
          Icon(
            Icons.settings,
            size: 60,
            color: AppTheme.whiteColor,
          ),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Customize your PearlNest experience',
            style: TextStyle(
              color: AppTheme.whiteColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      'Account',
      [
        _buildSettingsItem(
          Icons.person_outline,
          'Edit Profile',
          'Update your personal information',
          () => _navigateToEditProfile(),
        ),
        _buildSettingsItem(
          Icons.lock_outline,
          'Change Password',
          'Update your account password',
          () => _showChangePasswordDialog(),
        ),
        _buildSettingsItem(
          Icons.email_outlined,
          'Email Preferences',
          'Manage email settings',
          () => _navigateToEmailPreferences(),
        ),
        _buildSettingsItem(
          Icons.verified_user_outlined,
          'Account Verification',
          widget.user.isVerified ? 'Verified' : 'Verify your account',
          () => _navigateToVerification(),
          trailing: widget.user.isVerified
              ? Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      'Notifications',
      [
        _buildSwitchItem(
          Icons.notifications_outlined,
          'Push Notifications',
          'Receive notifications on your device',
          _pushNotifications,
          (value) => setState(() => _pushNotifications = value),
        ),
        _buildSwitchItem(
          Icons.email_outlined,
          'Email Notifications',
          'Receive notifications via email',
          _emailNotifications,
          (value) => setState(() => _emailNotifications = value),
        ),
        _buildSwitchItem(
          Icons.sms_outlined,
          'SMS Notifications',
          'Receive notifications via SMS',
          _smsNotifications,
          (value) => setState(() => _smsNotifications = value),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(ThemeProvider themeProvider) {
    return _buildSection(
      'Appearance',
      [
        _buildSwitchItem(
          Icons.dark_mode_outlined,
          'Dark Mode',
          'Switch to dark theme',
          themeProvider.isDarkMode,
          (value) {
            themeProvider.toggleTheme();
          },
        ),
        _buildDropdownItem(
          Icons.language_outlined,
          'Language',
          'Choose your preferred language',
          _selectedLanguage,
          ['English', 'Spanish', 'French', 'German', 'Chinese'],
          (value) => setState(() => _selectedLanguage = value!),
        ),
        _buildDropdownItem(
          Icons.attach_money_outlined,
          'Currency',
          'Select your preferred currency',
          _selectedCurrency,
          ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
          (value) => setState(() => _selectedCurrency = value!),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      'Privacy & Security',
      [
        _buildSwitchItem(
          Icons.location_on_outlined,
          'Location Services',
          'Allow location access for better experience',
          _locationEnabled,
          (value) => setState(() => _locationEnabled = value),
        ),
        _buildSwitchItem(
          Icons.fingerprint,
          'Biometric Authentication',
          'Use fingerprint or face ID to login',
          _bioEnabled,
          (value) => setState(() => _bioEnabled = value),
        ),
        _buildSettingsItem(
          Icons.download_outlined,
          'Download My Data',
          'Get a copy of your data',
          () => _showDownloadDataDialog(),
        ),
        _buildSettingsItem(
          Icons.delete_outline,
          'Delete Account',
          'Permanently delete your account',
          () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      'Support',
      [
        _buildSettingsItem(
          Icons.help_outline,
          'Help Center',
          'Get help and find answers',
          () => _navigateToHelpCenter(),
        ),
        _buildSettingsItem(
          Icons.star_outline,
          'Rate the App',
          'Share your feedback',
          () => _navigateToRateApp(),
        ),
        _buildSettingsItem(
          Icons.star_outline,
          'Contact Developer',
          'Vawzen',
          () => _navigateToContactDeveloper(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      [
        _buildSettingsItem(
          Icons.info_outline,
          'App Version',
          '1.0.0',
          null,
        ),
        _buildSettingsItem(
          Icons.description_outlined,
          'Terms of Service',
          'Read our terms and conditions',
          () => _navigateToPrivacyPolicy(),
        ),
        _buildSettingsItem(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          'Learn about our privacy practices',
          () => _navigateToPrivacyPolicy(),
        ),
        _buildSettingsItem(
          Icons.gavel_outlined,
          'Licenses',
          'View open source licenses',
          () => _navigateToLicenses(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
          Card(
            elevation: 2,
            color: AppTheme.getCardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : AppTheme.primaryblue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppTheme.primaryblue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : AppTheme.getTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.getSecondaryTextColor(context),
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.getSecondaryTextColor(context),
                )
              : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryblue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryblue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.getTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.getSecondaryTextColor(context),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryblue,
      ),
    );
  }

  Widget _buildDropdownItem(
    IconData icon,
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryblue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryblue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.getTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.getSecondaryTextColor(context),
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: AppTheme.getCardColor(context),
            style: TextStyle(color: AppTheme.getTextColor(context)),
            iconEnabledColor: AppTheme.primaryblue,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: widget.user),
      ),
    );
  }

  void _navigateToEmailPreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email Preferences - Coming Soon', style: TextStyle(color: AppTheme.lightGreyColor),),
        duration: Duration(milliseconds: 500),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToVerification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account Verification - Coming Soon', style: TextStyle(color: AppTheme.lightGreyColor),),
        duration: Duration(milliseconds: 500),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpSupportScreen(user: widget.user,),
      ),
    );
  }

  void _navigateToContactDeveloper() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDeveloperScreen(),
      ),
    );
  }

  void _navigateToRateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rate App - Coming Soon', style: TextStyle(color: AppTheme.lightGreyColor),),
        duration: Duration(milliseconds: 500),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _navigateToLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'PearlNest Estates',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.home, size: 48),
      applicationLegalese: '© 2024 PearlNest Estates. All rights reserved.',
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_outline, color: AppTheme.primaryblue),
                  SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(color: AppTheme.getTextColor(context)),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordField(
                      controller: currentPasswordController,
                      labelText: 'Current Password',
                      obscureText: obscureCurrentPassword,
                      onToggleVisibility: () {
                        setDialogState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                      icon: Icons.lock_outline,
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: newPasswordController,
                      labelText: 'New Password',
                      obscureText: obscureNewPassword,
                      onToggleVisibility: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                      icon: Icons.lock_reset_outlined,
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      labelText: 'Confirm New Password',
                      obscureText: obscureConfirmPassword,
                      onToggleVisibility: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icons.lock_person_outlined,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _handlePasswordChange(
                      currentPasswordController.text,
                      newPasswordController.text,
                      confirmPasswordController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryblue,
                    foregroundColor: AppTheme.whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: AppTheme.getTextColor(context)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context),
        prefixIcon: Icon(icon, color: AppTheme.primaryblue),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryblue, width: 2),
        ),
      ),
    );
  }

  void _handlePasswordChange(String currentPassword, String newPassword, String confirmPassword) async {
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill all fields', Colors.red);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', Colors.red);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters', Colors.red);
      return;
    }

    Navigator.of(context).pop();
    
    // Show loading
    _showSnackBar('Changing password...', AppTheme.primaryblue);
    
    try {
      final result = await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (result['success'] == true) {
        _showSnackBar('Password changed successfully', AppTheme.primaryblue);
      } else {
        // Handle specific error codes
        final code = result['code'];
        final message = result['message'] ?? 'Password change failed';
        
        if (code == 'TOKEN_EXPIRED') {
          _showSnackBar('Session expired. Please login again.', Colors.red);
          // TODO: Navigate to login screen or trigger re-authentication
          // You can use Provider.of<AuthProvider>(context, listen: false).logout();
        } else if (code == 'NO_INTERNET') {
          _showSnackBar('No internet connection. Please try again.', Colors.red);
        } else {
          _showSnackBar(message, Colors.red);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Password change error: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSnackBar('Network error. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.download_outlined, color: AppTheme.primaryblue),
              SizedBox(width: 8),
              Text(
                'Download My Data',
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We will prepare a copy of your data and send it to your email address. This may take up to 24 hours.',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
              SizedBox(height: 16),
              Text(
                'Email: ${widget.user.email}',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Data download request submitted', AppTheme.primaryblue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                foregroundColor: AppTheme.whiteColor,
              ),
              child: Text('Request Download'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final confirmationController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDeleteEnabled = confirmationController.text.trim().toUpperCase() == 'DELETE';

            return Dialog(
              backgroundColor: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DANGER ZONE',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Delete Account',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Are you absolutely sure?',
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This action cannot be undone. This will permanently delete your account and remove all your data from our servers.',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This data will be permanently deleted:',
                                      style: TextStyle(
                                        color: AppTheme.getTextColor(context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildDeleteItem('All your property listings'),
                              _buildDeleteItem('Booking history and reservations'),
                              _buildDeleteItem('Personal profile information'),
                              _buildDeleteItem('Payment methods and transaction history'),
                              _buildDeleteItem('Reviews and ratings'),
                              _buildDeleteItem('Saved favorites and preferences'),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Please type "DELETE" to confirm:',
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: confirmationController,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type DELETE here',
                            hintStyle: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppTheme.getBackgroundColor(context),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {});
                          },
                        ),
                        SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppTheme.getSecondaryTextColor(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isDeleteEnabled
                                    ? () {
                                        _handleAccountDeletion();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDeleteEnabled
                                      ? Colors.red
                                      : Colors.grey.withOpacity(0.3),
                                  foregroundColor: AppTheme.whiteColor,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: isDeleteEnabled ? 2 : 0,
                                ),
                                child: Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleAccountDeletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Deleting account...',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      _showSnackBar('Account deletion initiated successfully', Colors.red);
    });
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.close,
            color: Colors.red,
            size: 16,
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
}