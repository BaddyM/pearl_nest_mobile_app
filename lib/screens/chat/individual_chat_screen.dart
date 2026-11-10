// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/chat_message.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_event.dart';
import 'package:pearlnest/blocs/chat/chat_state.dart';
import 'package:pearlnest/screens/chat/chat_conversation.dart';
import 'package:pearlnest/screens/chat/chat_input.dart';
import 'package:pearlnest/screens/chat/chat_reply.dart';
import 'package:pearlnest/screens/chat/message.dart';
import 'package:pearlnest/screens/chat/message_bubble.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/utils/image_helper.dart';

class IndividualChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final User currentUser;
  final bool isOnline;
  final String adminContact;
  final String? propertyId;
  final String? propertyAddress;

  const IndividualChatScreen({
    super.key,
    required this.conversation,
    required this.currentUser,
    required this.isOnline,
    required this.adminContact,
    this.propertyId,
    this.propertyAddress,
  });

  @override
  _IndividualChatScreenState createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatReply? _replyingTo;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Initialize chat and load messages for this conversation
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(const ChatInitialize());
    chatBloc.add(ChatLoadMessages(
      chatWithUserId: widget.conversation.landlordId,
      propertyId: widget.propertyId,
    ));
    chatBloc.add(ChatMarkAsRead(
      fromUserId: widget.conversation.landlordId,
      toUserId: widget.currentUser.id,
      propertyId: widget.propertyId,
    ));
  }

  Future<void> _refreshMessages() async {
    final bloc = context.read<ChatBloc>();
    bloc.add(
      ChatLoadMessages(
        chatWithUserId: widget.conversation.landlordId,
        propertyId: widget.propertyId,
      ),
    );
    await bloc.stream.firstWhere(
      (state) => state is ChatConnected || state is ChatError,
    );
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
      text: _replyingTo == null
          ? messageText
          : ChatReply.format(
              sender: _replyingTo!.sender,
              quotedText: _replyingTo!.quotedText,
              message: messageText,
            ),
      propertyId: widget.propertyId,
    ));

    _messageController.clear();
    setState(() => _replyingTo = null);
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    ChatReplyPreview(
                      reply: _replyingTo!,
                      onCancel: () => setState(() => _replyingTo = null),
                    ),
                  _buildMessageInput(state),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryblue,
      foregroundColor: AppTheme.whiteColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
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
                      ? CachedNetworkImage(
                          imageUrl: ImageHelper.getFullImageUrl(
                            widget.conversation.landlordProfilePic,
                          ),
                          fit: BoxFit.cover,
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                            radius: 20,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) => _buildDefaultAvatar(),
                          errorWidget: (context, url, error) =>
                              _buildDefaultAvatar(),
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
                  style: const TextStyle(
                    color: AppTheme.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: AppTheme.whiteColor.withValues(alpha: 0.82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (widget.adminContact.trim().isNotEmpty)
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.call_outlined, color: AppTheme.whiteColor),
            onPressed: _showCallDialog,
          ),
        IconButton(
          tooltip: 'More options',
          icon: const Icon(Icons.more_vert, color: AppTheme.whiteColor),
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
          widget.conversation.landlordName.isNotEmpty
              ? widget.conversation.landlordName[0].toUpperCase()
              : '?',
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
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryblue.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: AppTheme.primaryblue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROPERTY CHAT',
                  style: TextStyle(
                    color: AppTheme.primaryblue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  widget.conversation.propertyTitle.isEmpty
                      ? 'General conversation'
                      : widget.conversation.propertyTitle,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.propertyAddress?.trim().isNotEmpty == true)
                  Text(
                    widget.propertyAddress!,
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryblue),
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
      return RefreshIndicator(
        onRefresh: _refreshMessages,
        color: AppTheme.primaryblue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: AppTheme.primaryblue.withValues(alpha: 0.5),
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
              ),
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _refreshMessages,
        color: AppTheme.primaryblue,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isFromCurrentUser =
                message.fromUserId == widget.currentUser.id.toString();
            final showTimestamp = _shouldShowTimestamp(index, messages);

            return Column(
              children: [
                if (showTimestamp) _buildTimestamp(message.timestamp),
                MessageBubble(
                  message: _convertToMessage(message, message.messageType!),
                  isFromCurrentUser: isFromCurrentUser,
                  senderAvatar: isFromCurrentUser
                      ? null
                      : widget.conversation.landlordProfilePic,
                  senderName: widget.conversation.landlordName,
                  onReply: () {
                    final content =
                        (ChatReply.parse(message.text)?.message ?? message.text)
                            .trim();
                    if (content.isEmpty) return;
                    setState(() {
                      _replyingTo = ChatReply(
                        sender: isFromCurrentUser
                            ? 'You'
                            : widget.conversation.landlordName,
                        quotedText: content,
                        message: '',
                      );
                    });
                  },
                ),
              ],
            );
          },
        ),
      );
    }
  }

  bool _shouldShowTimestamp(int index, List<ChatMessage> messages) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    return currentMessage.timestamp.year != previousMessage.timestamp.year ||
        currentMessage.timestamp.month != previousMessage.timestamp.month ||
        currentMessage.timestamp.day != previousMessage.timestamp.day;
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            _formatTimestamp(timestamp),
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatState state) {
    final isConnected =
        state.runtimeType.toString() == "ChatConnected" ? true : false;
    final isLoading = state.runtimeType.toString() == "ChatLoading" ||
        state.runtimeType.toString() == "ChatMessageSending";

    return ChatInput(
      controller: _messageController,
      onSend: _sendMessage,
      isEnabled: isConnected && !isLoading,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);
    final dayDifference = today.difference(messageDate).inDays;

    if (dayDifference == 0) {
      return 'Today';
    } else if (dayDifference == 1) {
      return 'Yesterday';
    } else if (dayDifference > 1 && dayDifference < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('d MMMM y').format(timestamp);
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
                style:
                    TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                String phoneNumber = widget.adminContact;

                String cleanedNumber =
                    phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

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
                  color:
                      AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              if (widget.propertyId?.trim().isNotEmpty == true)
                _buildOptionTile(
                  icon: Icons.home_outlined,
                  title: 'View Property',
                  onTap: () {
                    Navigator.pop(context);
                    _openProperty();
                  },
                ),
              if (!widget.conversation.isAdmin)
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

  Future<void> _openProperty() async {
    final propertyId = widget.propertyId?.trim();
    if (propertyId == null || propertyId.isEmpty) return;

    try {
      final result = await PropertyService.getPropertyById(propertyId);
      if (!mounted) return;
      final property = result['property'];
      if (result['success'] != true || property is! Property) {
        CustomSnackBar.showError(
          context,
          result['message']?.toString() ?? 'Could not load this property.',
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(
            property: property,
            user: widget.currentUser,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Could not load this property: $error');
      }
    }
  }

  Future<void> _showBlockDialog() async {
    if (widget.conversation.isAdmin) return;
    final shouldBlock = await showDialog<bool>(
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
              onPressed: () => Navigator.pop(context, true),
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
    if (shouldBlock != true || !mounted) return;

    try {
      await ChatService.blockUser(peerId: widget.conversation.landlordId);
      if (!mounted) return;
      CustomSnackBar.showSuccess(
        context,
        '${widget.conversation.landlordName} has been blocked.',
      );
      Navigator.pop(context, 'blocked');
    } catch (error) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Could not block this user: $error');
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reasonController = TextEditingController();
    String? validationError;
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help us understand what\'s happening. We\'ll review this conversation.',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      errorText: validationError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reportReason = reasonController.text.trim();
                    if (reportReason.isEmpty) {
                      setDialogState(() => validationError = 'Enter a reason.');
                      return;
                    }
                    Navigator.pop(dialogContext, reportReason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit report',
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
                ),
              ],
            ),
          );
        },
      );
      if (reason == null || !mounted) return;

      await ChatService.reportUser(
        peerId: widget.conversation.landlordId,
        reason: reason,
        propertyId: widget.propertyId,
      );
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'Report submitted. Thank you for your feedback.',
        );
      }
    } catch (error) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Could not submit the report: $error');
      }
    } finally {
      reasonController.dispose();
    }
  }

  Widget _buildConnectionStatus(ChatState state) {
    final bool isConnected =
        state.runtimeType.toString() == "ChatConnected" ? true : false;

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
