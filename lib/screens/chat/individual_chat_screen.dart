// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/chat_message.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_event.dart';
import 'package:pearlnest/blocs/chat/chat_state.dart';
import 'package:pearlnest/screens/chat/chat_conversation.dart';
import 'package:pearlnest/screens/chat/chat_input.dart';
import 'package:pearlnest/screens/chat/message.dart';
import 'package:pearlnest/screens/chat/message_bubble.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';

class IndividualChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final User currentUser;
  final bool isOnline;
  final String adminContact;

  const IndividualChatScreen({
    super.key,
    required this.conversation,
    required this.currentUser,
    required this.isOnline,
    required this.adminContact,
  });

  @override
  _IndividualChatScreenState createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Initialize chat and load messages for this conversation
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(const ChatInitialize());
    chatBloc.add(ChatLoadMessages(chatWithUserId: widget.conversation.landlordId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Send message via ChatBloc
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(ChatSendMessage(
      toUserId: widget.conversation.landlordId,
      text: messageText,
    ));

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            CustomSnackBar.showError(
              context,
              state.error,
              onRetry: () {},
            );
          }
          // Auto-scroll when new messages arrive
          if (state is ChatConnected || state is ChatMessageSent) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildConnectionStatus(state),
              _buildPropertyInfo(),
              Expanded(child: _buildMessagesList(state)),
              _buildMessageInput(state),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.getBackgroundColor(context),
      elevation: 1,
      shadowColor: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(context)),
        onPressed: () => Navigator.pop(context, "popped"),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightGreyColor,
                ),
                child: ClipOval(
                  child: widget.conversation.landlordProfilePic.isNotEmpty
                      ? Image.asset(
                          widget.conversation.landlordProfilePic,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              if (widget.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.whiteColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.landlordName,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.phone, color: AppTheme.primaryblue),
          onPressed: () {
            _showCallDialog();
          },
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: AppTheme.getTextColor(context)),
          onPressed: () {
            _showMoreOptions();
          },
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
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
          widget.conversation.landlordName.isNotEmpty ? widget.conversation.landlordName[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppTheme.whiteColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryblue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home,
            color: AppTheme.primaryblue,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Discussion',
                  style: TextStyle(
                    color: AppTheme.primaryblue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  widget.conversation.propertyTitle,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.primaryblue,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState state) {
    List<ChatMessage> messages = [];

    if (state is ChatConnected) {
      messages = state.messages;
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to ${widget.conversation.landlordName}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isFromCurrentUser = message.fromUserId == widget.currentUser.id.toString();
          final showTimestamp = _shouldShowTimestamp(index, messages);

          return Column(
            children: [
              if (showTimestamp) _buildTimestamp(message.timestamp),
              MessageBubble(
                message: _convertToMessage(message, message.messageType!),
                isFromCurrentUser: isFromCurrentUser,
                senderAvatar: isFromCurrentUser ? null : widget.conversation.landlordProfilePic,
                senderName: widget.conversation.landlordName,
              ),
            ],
          );
        },
      );
    }
  }

  bool _shouldShowTimestamp(int index, List<ChatMessage> messages) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    final timeDifference = currentMessage.timestamp.difference(previousMessage.timestamp);
    return timeDifference.inMinutes > 30;
  }

  // Helper method to convert ChatMessage to Message for MessageBubble
  Message _convertToMessage(ChatMessage chatMessage, MessageType type) {
    return Message(
      id: chatMessage.id,
      senderId: chatMessage.fromUserId,
      receiverId: chatMessage.toUserId,
      content: chatMessage.text,
      timestamp: chatMessage.timestamp,
      type: type,
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _formatTimestamp(timestamp),
        style: TextStyle(
          color: AppTheme.getSecondaryTextColor(context),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageInput(ChatState state) {
    final isConnected = state.runtimeType.toString() == "ChatConnected" ? true : false;
    final isLoading = state.runtimeType.toString() == "ChatLoading" || state.runtimeType.toString() == "ChatMessageSending";

    return ChatInput(
      controller: _messageController,
      onSend: _sendMessage,
      isEnabled: isConnected && !isLoading,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Call ${widget.conversation.landlordName}',
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Would you like to call ${widget.conversation.landlordName}?',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                String phoneNumber = widget.adminContact;

                String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

                // Create the tel URL
                final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

                try {
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    CustomSnackBar.showError(
                      context,
                      'Phone calls are not supported on this device',
                    );
                  }
                } catch (e) {
                  CustomSnackBar.showError(
                    context,
                    'Failed to make call. Please try again.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Call',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          color: AppTheme.getCardColor(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.home_outlined,
                title: 'View Property',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildOptionTile(
                icon: Icons.block,
                title: 'Block User',
                onTap: () {
                  Navigator.pop(context);
                  _showBlockDialog();
                },
                isDestructive: true,
              ),
              _buildOptionTile(
                icon: Icons.report_outlined,
                title: 'Report',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
                isDestructive: true,
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.getTextColor(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppTheme.getTextColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Block ${widget.conversation.landlordName}?',
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You won\'t receive messages from this person anymore.',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                CustomSnackBar.showWarning(
                  context,
                  '${widget.conversation.landlordName} has been blocked',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Block',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Report ${widget.conversation.landlordName}?',
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Help us understand what\'s happening. We\'ll review this conversation.',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                CustomSnackBar.showSuccess(
                  context,
                  'Report submitted. Thank you for your feedback.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Report',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatus(ChatState state) {
    final bool isConnected = state.runtimeType.toString() == "ChatConnected" ? true : false;

    if (isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.orange,
      child: Text(
        'Connecting...',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.whiteColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
