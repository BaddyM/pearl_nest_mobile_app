// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/screens/chat/message.dart';
import 'package:pearlnest/screens/chat/message_status.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;
  final String? senderAvatar;
  final String senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.senderAvatar,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isFromCurrentUser ? 50 : 0,
        right: isFromCurrentUser ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            Container(
              width: 24,
              height: 24,
              margin: EdgeInsets.only(right: 8, bottom: 4),
              child: ClipOval(
                child: senderAvatar != null && senderAvatar!.isNotEmpty
                    ? Image.asset(
                        senderAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildSmallAvatar();
                        },
                      )
                    : _buildSmallAvatar(),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromCurrentUser 
                    ? AppTheme.primaryblue 
                    : AppTheme.lightGreyColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(isFromCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(isFromCurrentUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blackColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isFromCurrentUser 
                          ? AppTheme.whiteColor 
                          : AppTheme.blackColor,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: isFromCurrentUser 
                              ? AppTheme.whiteColor.withOpacity(0.7)
                              : AppTheme.greyColor,
                          fontSize: 12,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        SizedBox(width: 4),
                        MessageStatusWidget(
                          status: message.status,
                          isFromCurrentUser: isFromCurrentUser,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryblue,
            AppTheme.accentGreen,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty 
              ? senderName[0].toUpperCase() 
              : '?',
          style: TextStyle(
            color: AppTheme.whiteColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}
