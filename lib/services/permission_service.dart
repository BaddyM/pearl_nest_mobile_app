import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static const String _tag = 'PermissionService';

  // Check if all essential permissions are granted
  static Future<bool> checkEssentialPermissions() async {
    try {
      final permissions = await _getEssentialPermissions();
      bool allGranted = true;

      for (Permission permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          allGranted = false;
          //debugPrint('$_tag: Essential permission ${permission.toString()} not granted');
        }
      }

      return allGranted;
    } catch (e) {
      //debugPrint('$_tag: Error checking essential permissions: $e');
      return false;
    }
  }

  // Request essential permissions
  static Future<bool> requestEssentialPermissions() async {
    try {
      //debugPrint('$_tag: Requesting essential permissions');

      final permissions = await _getEssentialPermissions();
      final Map<Permission, PermissionStatus> statuses = await permissions.request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        //debugPrint('$_tag: Permission ${permission.toString()}: ${status.toString()}');
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting essential permissions: $e');
      return false;
    }
  }

  // Get essential permissions list
  static Future<List<Permission>> _getEssentialPermissions() async {
    List<Permission> permissions = [];

    // Network and basic app functionality
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.phone,
        Permission.notification,
      ]);
    }

    return permissions;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      //debugPrint('$_tag: Requesting camera permission');

      final status = await Permission.camera.request();
      //debugPrint('$_tag: Camera permission status: ${status.toString()}');

      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting camera permission: $e');
      return false;
    }
  }

  // Request photo library permission
  static Future<bool> requestPhotoLibraryPermission() async {
    try {
      //debugPrint('$_tag: Requesting photo library permission');

      final status = await Permission.photos.request();
      //debugPrint('$_tag: Photo library permission status: ${status.toString()}');

      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting photo library permission: $e');
      return false;
    }
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    try {
      //debugPrint('$_tag: Requesting storage permission');

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        //debugPrint('$_tag: Storage permission status: ${status.toString()}');
        return status.isGranted;
      } else {
        // iOS uses photo library permission
        return await requestPhotoLibraryPermission();
      }
    } catch (e) {
      //debugPrint('$_tag: Error requesting storage permission: $e');
      return false;
    }
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      //debugPrint('$_tag: Requesting location permission');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        //debugPrint('$_tag: Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          //debugPrint('$_tag: Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        //debugPrint('$_tag: Location permission denied forever');
        return false;
      }

      //debugPrint('$_tag: Location permission granted');
      return true;
    } catch (e) {
      //debugPrint('$_tag: Error requesting location permission: $e');
      return false;
    }
  }

  // Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    try {
      //debugPrint('$_tag: Requesting microphone permission');

      final status = await Permission.microphone.request();
      //debugPrint('$_tag: Microphone permission status: ${status.toString()}');

      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting microphone permission: $e');
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      //debugPrint('$_tag: Requesting notification permission');

      final status = await Permission.notification.request();
      //debugPrint('$_tag: Notification permission status: ${status.toString()}');

      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting notification permission: $e');
      return false;
    }
  }

  // Request phone permission
  static Future<bool> requestPhonePermission() async {
    try {
      //debugPrint('$_tag: Requesting phone permission');

      final status = await Permission.phone.request();
      //debugPrint('$_tag: Phone permission status: ${status.toString()}');

      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting phone permission: $e');
      return false;
    }
  }

  // Request contacts permission
  static Future<bool> requestContactsPermission() async {
    try {
      //debugPrint('$_tag: Requesting contacts permission');

      final status = await Permission.contacts.request();
      //debugPrint('$_tag: Contacts permission status: ${status.toString()}');

      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting contacts permission: $e');
      return false;
    }
  }

  // Check specific permission status
  static Future<bool> checkPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      //debugPrint('$_tag: Error checking permission ${permission.toString()}: $e');
      return false;
    }
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    try {
      //debugPrint('$_tag: Opening app settings');
      await openAppSettings();
    } catch (e) {
      //debugPrint('$_tag: Error opening app settings: $e');
    }
  }

  // Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      //debugPrint('$_tag: Error checking if permission is permanently denied: $e');
      return false;
    }
  }

  // Get all permissions status
  static Future<Map<String, bool>> getAllPermissionsStatus() async {
    final Map<String, bool> permissions = {};

    try {
      permissions['camera'] = await Permission.camera.isGranted;
      permissions['photos'] = await Permission.photos.isGranted;
      permissions['microphone'] = await Permission.microphone.isGranted;
      permissions['notification'] = await Permission.notification.isGranted;
      permissions['phone'] = await Permission.phone.isGranted;
      permissions['contacts'] = await Permission.contacts.isGranted;
      permissions['location'] = await requestLocationPermission();

      if (Platform.isAndroid) {
        permissions['storage'] = await Permission.storage.isGranted;
      }

      //debugPrint('$_tag: All permissions status: $permissions');
      return permissions;
    } catch (e) {
      //debugPrint('$_tag: Error getting all permissions status: $e');
      return permissions;
    }
  }

  // Request all permissions at once
  static Future<bool> requestAllPermissions() async {
    try {
      //debugPrint('$_tag: Requesting all permissions');

      final Map<String, bool> results = {};

      // Request permissions individually with proper error handling
      results['camera'] = await requestCameraPermission();
      results['photos'] = await requestPhotoLibraryPermission();
      results['microphone'] = await requestMicrophonePermission();
      results['notification'] = await requestNotificationPermission();
      results['phone'] = await requestPhonePermission();
      results['location'] = await requestLocationPermission();

      if (Platform.isAndroid) {
        results['storage'] = await requestStoragePermission();
      }

      // Check if all critical permissions are granted
      bool allCriticalGranted = true;
      final criticalPermissions = ['notification', 'phone'];

      for (String permission in criticalPermissions) {
        if (results[permission] != true) {
          allCriticalGranted = false;
          //debugPrint('$_tag: Critical permission $permission not granted');
        }
      }

      //debugPrint('$_tag: All permissions request results: $results');
      //debugPrint('$_tag: All critical permissions granted: $allCriticalGranted');

      return allCriticalGranted;
    } catch (e) {
      //debugPrint('$_tag: Error requesting all permissions: $e');
      return false;
    }
  }
}
