import 'package:flutter/material.dart';
import 'package:pearlnest/providers/auth_provider.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:provider/provider.dart';

class LogoutButton extends StatelessWidget {
  final String? customText;
  final IconData? customIcon;
  final Color? customColor;
  final VoidCallback? onLogoutSuccess;

  const LogoutButton({
    super.key,
    this.customText,
    this.customIcon,
    this.customColor,
    this.onLogoutSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ElevatedButton.icon(
          onPressed: authProvider.isLoading ? null : () => _showLogoutDialog(context, authProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? Colors.red.withOpacity(0.1),
            foregroundColor: customColor ?? Colors.red,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: authProvider.isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(customColor ?? Colors.red),
                  ),
                )
              : Icon(customIcon ?? Icons.logout, size: 20),
          label: Text(
            authProvider.isLoading ? 'Logging out...' : (customText ?? 'Logout'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleLogout(context, authProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    try {
      await authProvider.logout();
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged out successfully',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            backgroundColor: AppTheme.primaryblue,
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
      
      // Call custom callback if provided
      onLogoutSuccess?.call();
      
    } catch (e, stackTrace) {
      debugPrint('Logout error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed. Please try again.',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// Simple logout menu item for use in drawers or menus
class LogoutMenuItem extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;

  const LogoutMenuItem({
    super.key,
    this.onLogoutSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text(
            'Logout',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: authProvider.isLoading 
              ? null 
              : () => LogoutButton()._showLogoutDialog(context, authProvider),
        );
      },
    );
  }
}
