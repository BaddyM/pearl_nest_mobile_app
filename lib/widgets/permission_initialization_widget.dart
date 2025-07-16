import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/permission_service.dart';
import '../widgets/app_theme.dart';

class PermissionInitializationWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const PermissionInitializationWidget({
    Key? key,
    required this.child,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
  }) : super(key: key);

  @override
  State<PermissionInitializationWidget> createState() => _PermissionInitializationWidgetState();
}

class _PermissionInitializationWidgetState extends State<PermissionInitializationWidget> {
  bool _isCheckingPermissions = true;
  bool _showPermissionDialog = false;
  String _permissionMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      // Check if essential permissions are already granted
      final essentialGranted = await PermissionService.checkEssentialPermissions();
      
      if (essentialGranted) {
        setState(() {
          _isCheckingPermissions = false;
        });
        widget.onPermissionsGranted?.call();
        return;
      }
      
      // Show permission dialog
      setState(() {
        _showPermissionDialog = true;
        _permissionMessage = 'PearlNest needs certain permissions to work properly. Please grant the required permissions.';
      });
      
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      setState(() {
        _permissionMessage = 'Requesting permissions...';
      });
      
      final granted = await PermissionService.requestAllPermissions();
      
      if (granted) {
        setState(() {
          _showPermissionDialog = false;
          _isCheckingPermissions = false;
        });
        widget.onPermissionsGranted?.call();
      } else {
        setState(() {
          _permissionMessage = 'Some permissions were denied. The app may not work properly without them.';
        });
        widget.onPermissionsDenied?.call();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      setState(() {
        _permissionMessage = 'Error requesting permissions. Please try again.';
      });
    }
  }

  Future<void> _openSettings() async {
    try {
      await PermissionService.openAppSettings();
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions && !_showPermissionDialog) {
      return _buildLoadingScreen();
    }
    
    if (_showPermissionDialog) {
      return _buildPermissionDialog();
    }
    
    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryblue,
            ),
            const SizedBox(height: 24),
            Text(
              'Checking permissions...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDialog() {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: AppTheme.primaryblue,
              ),
              const SizedBox(height: 32),
              Text(
                'App Permissions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _permissionMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getSecondaryTextColor(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPermissionList(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryblue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Grant Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showPermissionDialog = false;
                          _isCheckingPermissions = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.getSecondaryTextColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Skip for Now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: _openSettings,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryblue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionList() {
    final permissions = [
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'description': 'Receive important updates and messages',
      },
      {
        'icon': Icons.phone,
        'title': 'Phone',
        'description': 'Make calls to property owners',
      },
      {
        'icon': Icons.camera_alt,
        'title': 'Camera',
        'description': 'Take photos of properties',
      },
      {
        'icon': Icons.photo_library,
        'title': 'Photo Library',
        'description': 'Select and share property images',
      },
      {
        'icon': Icons.location_on,
        'title': 'Location',
        'description': 'Find properties near you',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: permissions.map((permission) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  permission['icon'] as IconData,
                  color: AppTheme.primaryblue,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        permission['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
