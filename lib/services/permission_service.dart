import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static const String _tag = 'PermissionService';

  static Future<bool> checkEssentialPermissions() async {
    try {
      final permissions = await _getEssentialPermissions();
      var allGranted = true;

      for (final permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          allGranted = false;
          debugPrint('$_tag: Essential permission ${permission.toString()} not granted');
        }
      }

      return allGranted;
    } catch (e) {
      debugPrint('$_tag: Error checking essential permissions: $e');
      return false;
    }
  }

  static Future<bool> requestEssentialPermissions() async {
    try {
      final permissions = await _getEssentialPermissions();
      final Map<permission_handler.Permission, permission_handler.PermissionStatus> statuses = await permissions.request();

      var allGranted = true;
      statuses.forEach((permission, status) {
        debugPrint('$_tag: Permission ${permission.toString()}: ${status.toString()}');
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting essential permissions: $e');
      return false;
    }
  }

  static Future<List<permission_handler.Permission>> _getEssentialPermissions() async {
    final permissions = <permission_handler.Permission>[];

    if (Platform.isAndroid) {
      permissions.addAll([
        permission_handler.Permission.phone,
        permission_handler.Permission.notification,
      ]);
    }

    return permissions;
  }

  static Future<bool> requestCameraPermission() async {
    try {
      final status = await permission_handler.Permission.camera.request();
      debugPrint('$_tag: Camera permission status: ${status.toString()}');
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting camera permission: $e');
      return false;
    }
  }

  static Future<bool> requestPhotoLibraryPermission() async {
    try {
      final status = await permission_handler.Permission.photos.request();
      debugPrint('$_tag: Photo library permission status: ${status.toString()}');
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting photo library permission: $e');
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await permission_handler.Permission.storage.request();
        debugPrint('$_tag: Storage permission status: ${status.toString()}');
        return status.isGranted;
      }

      return await requestPhotoLibraryPermission();
    } catch (e) {
      debugPrint('$_tag: Error requesting storage permission: $e');
      return false;
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('$_tag: Location services are disabled');
        return false;
      }

      var locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
        if (locationPermission == LocationPermission.denied) {
          debugPrint('$_tag: Location permission denied');
          return false;
        }
      }

      if (locationPermission == LocationPermission.deniedForever) {
        debugPrint('$_tag: Location permission denied forever');
        return false;
      }

      debugPrint('$_tag: Location permission granted');
      return true;
    } catch (e) {
      debugPrint('$_tag: Error requesting location permission: $e');
      return false;
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await permission_handler.Permission.microphone.request();
      debugPrint('$_tag: Microphone permission status: ${status.toString()}');
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting microphone permission: $e');
      return false;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await permission_handler.Permission.notification.request();
      debugPrint('$_tag: Notification permission status: ${status.toString()}');
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting notification permission: $e');
      return false;
    }
  }

  static Future<bool> requestPhonePermission() async {
    try {
      final status = await permission_handler.Permission.phone.request();
      debugPrint('$_tag: Phone permission status: ${status.toString()}');
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting phone permission: $e');
      return false;
    }
  }

  static Future<bool> requestContactsPermission() async {
    try {
      final status = await permission_handler.Permission.contacts.request();
      debugPrint('$_tag: Contacts permission status: ${status.toString()}');
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting contacts permission: $e');
      return false;
    }
  }

  static Future<bool> checkPermission(permission_handler.Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('$_tag: Error checking permission ${permission.toString()}: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      debugPrint('$_tag: Opening app settings');
      await permission_handler.openAppSettings();
    } catch (e) {
      debugPrint('$_tag: Error opening app settings: $e');
    }
  }

  static Future<bool> isPermissionPermanentlyDenied(permission_handler.Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      debugPrint('$_tag: Error checking if permission is permanently denied: $e');
      return false;
    }
  }

  static Future<Map<String, bool>> getAllPermissionsStatus() async {
    final permissions = <String, bool>{};

    try {
      permissions['camera'] = await permission_handler.Permission.camera.isGranted;
      permissions['photos'] = await permission_handler.Permission.photos.isGranted;
      permissions['microphone'] = await permission_handler.Permission.microphone.isGranted;
      permissions['notification'] = await permission_handler.Permission.notification.isGranted;
      permissions['phone'] = await permission_handler.Permission.phone.isGranted;
      permissions['contacts'] = await permission_handler.Permission.contacts.isGranted;
      permissions['location'] = await requestLocationPermission();

      if (Platform.isAndroid) {
        permissions['storage'] = await permission_handler.Permission.storage.isGranted;
      }

      debugPrint('$_tag: All permissions status: $permissions');
      return permissions;
    } catch (e) {
      debugPrint('$_tag: Error getting all permissions status: $e');
      return permissions;
    }
  }

  static Future<bool> requestAllPermissions() async {
    try {
      final results = <String, bool>{};

      results['camera'] = await requestCameraPermission();
      results['photos'] = await requestPhotoLibraryPermission();
      results['microphone'] = await requestMicrophonePermission();
      results['notification'] = await requestNotificationPermission();
      results['phone'] = await requestPhonePermission();
      results['location'] = await requestLocationPermission();

      if (Platform.isAndroid) {
        results['storage'] = await requestStoragePermission();
      }

      var allCriticalGranted = true;
      const criticalPermissions = ['notification', 'phone'];

      for (final permission in criticalPermissions) {
        if (results[permission] != true) {
          allCriticalGranted = false;
          debugPrint('$_tag: Critical permission $permission not granted');
        }
      }

      debugPrint('$_tag: All permissions request results: $results');
      debugPrint('$_tag: All critical permissions granted: $allCriticalGranted');

      return allCriticalGranted;
    } catch (e) {
      debugPrint('$_tag: Error requesting all permissions: $e');
      return false;
    }
  }
}
