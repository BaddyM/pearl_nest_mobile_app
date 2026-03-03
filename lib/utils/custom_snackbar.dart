import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';

enum SnackBarType {
  error,
  success,
  warning,
  info,
}

class CustomSnackBar {
  /// Show a user-friendly error message
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onRetry,
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      actionLabel: onRetry != null ? 'Retry' : null,
      onActionPressed: onRetry,
    );
  }

  /// Show a success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
    );
  }

  /// Show a warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
    );
  }

  /// Show an info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
    );
  }

  /// Internal method to show custom styled snack bar
  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Clear any existing snack bars
    ScaffoldMessenger.of(context).clearSnackBars();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get colors and icons based on type
    final config = _getSnackBarConfig(type, isDark);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.icon,
                color: config.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      color: config.textColor.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: config.borderColor,
            width: 1,
          ),
        ),
        elevation: 8,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: config.actionColor,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  /// Get configuration for different snack bar types
  static _SnackBarConfig _getSnackBarConfig(SnackBarType type, bool isDark) {
    switch (type) {
      case SnackBarType.error:
        return _SnackBarConfig(
          title: 'Oops! Something went wrong',
          icon: Icons.error_outline_rounded,
          backgroundColor: isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFFF4F4),
          iconBackgroundColor: isDark ? const Color(0xFF5F2D2D) : const Color(0xFFFFE8E8),
          iconColor: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626),
          textColor: isDark ? const Color(0xFFFFB3B3) : const Color(0xFF7F1D1D),
          borderColor: isDark ? const Color(0xFF5F2D2D) : const Color(0xFFFFD1D1),
          actionColor: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626),
        );

      case SnackBarType.success:
        return _SnackBarConfig(
          title: 'Success!',
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: isDark ? const Color(0xFF1B2D1B) : const Color(0xFFF4FFF4),
          iconBackgroundColor: isDark ? const Color(0xFF2D5F2D) : const Color(0xFFE8FFE8),
          iconColor: isDark ? const Color(0xFF6BFF6B) : const Color(0xFF16A34A),
          textColor: isDark ? const Color(0xFFB3FFB3) : const Color(0xFF14532D),
          borderColor: isDark ? const Color(0xFF2D5F2D) : const Color(0xFFD1FFD1),
          actionColor: isDark ? const Color(0xFF6BFF6B) : const Color(0xFF16A34A),
        );

      case SnackBarType.warning:
        return _SnackBarConfig(
          title: 'Heads up!',
          icon: Icons.warning_amber_rounded,
          backgroundColor: isDark ? const Color(0xFF2D2A1B) : const Color(0xFFFFFBF4),
          iconBackgroundColor: isDark ? const Color(0xFF5F5A2D) : const Color(0xFFFFF3E8),
          iconColor: isDark ? const Color(0xFFFFD56B) : const Color(0xFFEA580C),
          textColor: isDark ? const Color(0xFFFFE4B3) : const Color(0xFF7C2D12),
          borderColor: isDark ? const Color(0xFF5F5A2D) : const Color(0xFFFFE4D1),
          actionColor: isDark ? const Color(0xFFFFD56B) : const Color(0xFFEA580C),
        );

      case SnackBarType.info:
        return _SnackBarConfig(
          title: 'Info',
          icon: Icons.info_outline_rounded,
          backgroundColor: isDark ? const Color(0xFF1B2A2D) : const Color(0xFFF4FBFF),
          iconBackgroundColor: isDark ? const Color(0xFF2D5A5F) : const Color(0xFFE8F3FF),
          iconColor: isDark ? const Color(0xFF6BD5FF) : const Color(0xFF0284C7),
          textColor: isDark ? const Color(0xFFB3E4FF) : const Color(0xFF0C4A6E),
          borderColor: isDark ? const Color(0xFF2D5A5F) : const Color(0xFFD1E4FF),
          actionColor: isDark ? const Color(0xFF6BD5FF) : const Color(0xFF0284C7),
        );
    }
  }
}

/// Configuration class for snack bar styling
class _SnackBarConfig {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;
  final Color actionColor;

  const _SnackBarConfig({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.borderColor,
    required this.actionColor,
  });
}
