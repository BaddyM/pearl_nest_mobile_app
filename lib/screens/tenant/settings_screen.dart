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
import 'package:pearlnest/utils/custom_snackbar.dart';

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
  late bool _emailNotifications;
  late bool _pushNotifications;
  late bool _smsNotifications;
  String _selectedCurrency = 'UGX'; // Default to UGX for Uganda
  bool _isUpdatingNotifications = false;

  @override
  void initState() {
    super.initState();
    // Initialize notification preferences from user data
    _emailNotifications = widget.user.emailNotifications;
    _pushNotifications = widget.user.pushNotifications;
    _smsNotifications = widget.user.smsNotifications;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSettingsHeader(),
              _buildAccountSection(),
              _buildNotificationSection(),
              _buildAppearanceSection(themeProvider),
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
          (value) => _updateNotificationPreference(
            preferenceType: 'push',
            value: value,
          ),
          isLoading: _isUpdatingNotifications,
        ),
        _buildSwitchItem(
          Icons.email_outlined,
          'Email Notifications',
          'Receive notifications via email',
          _emailNotifications,
          (value) => _updateNotificationPreference(
            preferenceType: 'email',
            value: value,
          ),
          isLoading: _isUpdatingNotifications,
        ),
        _buildSwitchItem(
          Icons.sms_outlined,
          'SMS Notifications',
          'Receive notifications via SMS',
          _smsNotifications,
          (value) => _updateNotificationPreference(
            preferenceType: 'sms',
            value: value,
          ),
          isLoading: _isUpdatingNotifications,
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
          Icons.attach_money_outlined,
          'Currency',
          'Select your preferred currency',
          _selectedCurrency,
          ['UGX']
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
        // _buildSettingsItem(
        //   Icons.star_outline,
        //   'Rate the App',
        //   'Share your feedback',
        //   () => _navigateToRateApp(),
        // ),
        _buildSettingsItem(
          Icons.star_outline,
          'Contact Developer',
          'Develop With Effect',
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
          color: isDestructive ? Colors.red.withOpacity(0.1) : AppTheme.primaryblue.withOpacity(0.1),
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
    ValueChanged<bool> onChanged, {
    bool isLoading = false,
  }) {
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
      trailing: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
              ),
            )
          : Switch(
              value: value,
              onChanged: isLoading ? null : onChanged,
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
    //ValueChanged<String?> onChanged,
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

            //disabled updating currency
            onChanged: (value) {},
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

  // Method to update notification preferences
  Future<void> _updateNotificationPreference({
    required String preferenceType,
    required bool value,
  }) async {
    if (_isUpdatingNotifications) return;

    setState(() {
      _isUpdatingNotifications = true;
    });

    try {
      // Update the specific preference locally first for immediate UI feedback
      switch (preferenceType) {
        case 'push':
          _pushNotifications = value;
          break;
        case 'email':
          _emailNotifications = value;
          break;
        case 'sms':
          _smsNotifications = value;
          break;
      }
      setState(() {});

      // Call the updateProfile method with all current values and the updated notification preferences
      final result = await AuthService.updateProfile(
        name: widget.user.name,
        email: widget.user.email,
        phone: widget.user.phone,
        bio: widget.user.bio,
        pushNotifications: _pushNotifications,
        smsNotifications: _smsNotifications,
        emailNotifications: _emailNotifications,
      );

      if (result['success'] == true) {
        // Show success feedback
        _showSnackBar(
          '${_getPreferenceDisplayName(preferenceType)} ${value ? 'enabled' : 'disabled'}',
          AppTheme.primaryblue,
        );
      } else {
        // Revert the local change if update failed
        switch (preferenceType) {
          case 'push':
            _pushNotifications = !value;
            break;
          case 'email':
            _emailNotifications = !value;
            break;
          case 'sms':
            _smsNotifications = !value;
            break;
        }
        setState(() {});

        _showSnackBar(
          'Failed to update notification preference: ${result['message'] ?? 'Unknown error'}',
          Colors.red,
        );
      }
    } catch (e) {
      // Revert the local change if update failed
      switch (preferenceType) {
        case 'push':
          _pushNotifications = !value;
          break;
        case 'email':
          _emailNotifications = !value;
          break;
        case 'sms':
          _smsNotifications = !value;
          break;
      }
      setState(() {});

      _showSnackBar(
        'Network error. Please try again.',
        Colors.red,
      );
    } finally {
      setState(() {
        _isUpdatingNotifications = false;
      });
    }
  }

  String _getPreferenceDisplayName(String preferenceType) {
    switch (preferenceType) {
      case 'push':
        return 'Push notifications';
      case 'email':
        return 'Email notifications';
      case 'sms':
        return 'SMS notifications';
      default:
        return 'Notification preference';
    }
  }

  // Method to update currency preference
  // Future<void> _updateCurrencyPreference(String currency) async {
   
  //   // Update local state first for immediate UI feedback
  //   final previousCurrency = _selectedCurrency;
  //   setState(() {
  //     _selectedCurrency = currency;
  //   });

  //   try {
  //     // Call the updateCurrency method
  //     final result = await AuthService.updateCurrency(currency: currency);
      
     
  //     if (result['success'] == true) {
  //       //print('✅ SettingsScreen: Currency update successful');
  //       // Show success feedback
  //       CustomSnackBar.showSuccess(
  //         context,
  //         'Currency updated to $currency',
  //       );
  //     } else {
        
  //       // Revert the local change if update failed
  //       setState(() {
  //         _selectedCurrency = previousCurrency;
  //       });

  //       CustomSnackBar.showError(
  //         context,
  //         'Failed to update currency: ${result['message'] ?? 'Unknown error'}',
  //       );
  //     }
  //   } catch (e) {
  //     // Revert the local change if update failed
  //     setState(() {
  //       _selectedCurrency = previousCurrency;
  //     });

  //     CustomSnackBar.showError(
  //       context,
  //       'Network error. Please try again.',
  //     );
  //   }
  // }

  void _navigateToEmailPreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email Preferences - Coming Soon',
          style: TextStyle(color: AppTheme.lightGreyColor),
        ),
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
        builder: (context) => HelpSupportScreen(
          user: widget.user,
        ),
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

//   void _navigateToRateApp() async {
//    final InAppReview inAppReview = InAppReview.instance;

//   if (await inAppReview.isAvailable()) {
//     await inAppReview.requestReview();
//   } else {
//     // Fallback: open the store listing
//     await inAppReview.openStoreListing(
//       appStoreId: '6749172641', // Only for iOS
//        // Only for Android
//     );
//   }
// }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
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
    } catch (e) {
      //debugPrint('Password change error: $e');
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

 

  

  

  
}
