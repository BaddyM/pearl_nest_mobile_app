import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pearlnest/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class TokenRefreshService {
  static Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1); // Check every hour
  static const Duration _tokenLifetime = Duration(days: 7); // Token expires after 7 days

  static void startTokenRefreshTimer(BuildContext context) {
    stopTokenRefreshTimer(); // Stop any existing timer

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      _checkAndRefreshToken(context);
    });
  }

  static void stopTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  static Future<void> _checkAndRefreshToken(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        await authProvider.checkTokenExpiry();
      }
    } catch (e, stackTrace) {
      //debugPrint('Token refresh check error: $e');
      //debugPrint('Stack trace: $stackTrace');
    }
  }

  // Call this when the app becomes active
  static Future<void> onAppResumed(BuildContext context) async {
    await _checkAndRefreshToken(context);
  }

  // Call this when user performs an authenticated action
  static Future<bool> ensureValidToken(BuildContext context) async {
    if (!context.mounted) return false;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        return false;
      }

      await authProvider.checkTokenExpiry();
      return authProvider.isAuthenticated;
    } catch (e, stackTrace) {
      //debugPrint('Token validation error: $e');
      //debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}

// Mixin to add token refresh functionality to stateful widgets
mixin TokenRefreshMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    TokenRefreshService.startTokenRefreshTimer(context);
  }

  @override
  void dispose() {
    TokenRefreshService.stopTokenRefreshTimer();
    super.dispose();
  }

  Future<bool> ensureAuthenticated() async {
    return await TokenRefreshService.ensureValidToken(context);
  }
}
