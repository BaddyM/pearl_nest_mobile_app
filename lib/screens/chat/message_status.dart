// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageStatusWidget extends StatelessWidget {
  final MessageStatus status;
  final bool isFromCurrentUser;

  const MessageStatusWidget({
    super.key,
    required this.status,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFromCurrentUser) return SizedBox.shrink();

    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.whiteColor.withOpacity(0.7),
            ),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.done,
          size: 16,
          color: AppTheme.whiteColor.withOpacity(0.7),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 16,
          color: AppTheme.whiteColor.withOpacity(0.7),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.blue[300],
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red[300],
        );
    }
  }
}