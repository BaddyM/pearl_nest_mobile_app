import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/screens/chat/message.dart';
import 'package:pearlnest/screens/chat/message_status.dart';
import 'package:pearlnest/screens/chat/chat_reply.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/utils/image_helper.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;
  final String? senderAvatar;
  final String senderName;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.senderAvatar,
    required this.senderName,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final reply = ChatReply.parse(message.content);
    final bubble = InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        CustomSnackBar.showSuccess(context, 'Message copied');
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isFromCurrentUser ? 52 : 0,
          right: isFromCurrentUser ? 0 : 52,
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
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                child: ClipOval(
                  child: senderAvatar != null && senderAvatar!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ImageHelper.getFullImageUrl(senderAvatar!),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildSmallAvatar(),
                          errorWidget: (context, url, error) =>
                              _buildSmallAvatar(),
                        )
                      : _buildSmallAvatar(),
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: isFromCurrentUser
                      ? AppTheme.primaryblue
                      : AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isFromCurrentUser ? 20 : 6),
                    bottomRight: Radius.circular(isFromCurrentUser ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getTextColor(context)
                          .withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reply != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 7),
                        padding:
                            const EdgeInsets.only(left: 9, top: 2, bottom: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isFromCurrentUser
                                  ? Colors.white70
                                  : AppTheme.primaryblue,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reply.sender,
                              style: TextStyle(
                                color: isFromCurrentUser
                                    ? AppTheme.whiteColor
                                    : AppTheme.primaryblue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              reply.quotedText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isFromCurrentUser
                                    ? AppTheme.whiteColor.withValues(alpha: 0.8)
                                    : AppTheme.getSecondaryTextColor(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      reply?.message ?? message.content,
                      style: TextStyle(
                        color: isFromCurrentUser
                            ? AppTheme.whiteColor
                            : AppTheme.getTextColor(context),
                        fontSize: 15,
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
                                ? AppTheme.whiteColor.withValues(alpha: 0.76)
                                : AppTheme.getSecondaryTextColor(context),
                            fontSize: 10,
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
      ),
    );
    return onReply == null
        ? bubble
        : SwipeToReply(onReply: onReply!, child: bubble);
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
          senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
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
    return DateFormat.jm().format(timestamp);
  }
}
