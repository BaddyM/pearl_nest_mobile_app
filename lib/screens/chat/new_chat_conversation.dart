import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/widgets/loading_widget.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

class NewChatConversation extends StatefulWidget {
  const NewChatConversation({
    super.key,
    required this.fromUserId,
    required this.toUserId,
    required this.userName,
    this.userImageUrl,
    this.propertyId,
    this.propertyTitle,
    this.propertyAddress,
  });
  final String fromUserId;
  final String toUserId;
  final String userName;
  final String? userImageUrl;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyAddress;

  @override
  State<NewChatConversation> createState() => _NewChatConversationState();
}

class _NewChatConversationState extends State<NewChatConversation> {
  final _chatController = InMemoryChatController();
  var uuid = const Uuid();
  String? _propertyTitle;
  String? _propertyAddress;
  String _conversationStatus = 'OPEN';
  bool _isUpdatingConversation = false;

  @override
  void initState() {
    super.initState();
    _propertyTitle = widget.propertyTitle;
    _propertyAddress = widget.propertyAddress;
    if (widget.propertyId != null && _propertyTitle == null) {
      _loadPropertyContext();
    }

    //Read message
    context.read<NewChatBloc>().add(ReadMessageEvent(
          fromUserId: widget.fromUserId,
          toUserId: widget.toUserId,
          propertyId: widget.propertyId,
        ));

    //Fetch conversation
    context.read<NewChatBloc>().add(FetchNewChat(
          currentUserId: widget.fromUserId,
          toUserId: widget.toUserId,
          propertyId: widget.propertyId,
        ));
  }

  Future<void> _loadPropertyContext() async {
    final result = await PropertyService.getPropertyById(widget.propertyId!);
    if (!mounted || result['success'] != true || result['property'] is! Property) {
      return;
    }
    final property = result['property'] as Property;
    setState(() {
      _propertyTitle = property.title;
      _propertyAddress = property.address;
    });
  }

  void _fetchChat() {
    context.read<NewChatBloc>().add(
          FetchNewChat(
            currentUserId: widget.fromUserId,
            toUserId: widget.toUserId,
            propertyId: widget.propertyId,
          ),
        );
  }

  Future<void> _toggleConversationStatus() async {
    final propertyId = widget.propertyId;
    if (propertyId == null || _isUpdatingConversation) return;
    final isCompleted = _conversationStatus == 'COMPLETED';
    if (!isCompleted) {
      final shouldComplete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete conversation?'),
          content: const Text(
            'This closes the property conversation. Either participant can reopen it later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep open'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (shouldComplete != true || !mounted) return;
    }

    setState(() => _isUpdatingConversation = true);
    try {
      if (isCompleted) {
        await ChatService.startPropertyConversation(
          peerId: widget.toUserId,
          propertyId: propertyId,
        );
      } else {
        await ChatService.completePropertyConversation(
          peerId: widget.toUserId,
          propertyId: propertyId,
        );
      }
      if (!mounted) return;
      setState(() => _conversationStatus = isCompleted ? 'OPEN' : 'COMPLETED');
      _fetchChat();
    } catch (error) {
      if (mounted) {
        CustomSnackBar.showError(context, error.toString());
      }
    } finally {
      if (mounted) setState(() => _isUpdatingConversation = false);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        foregroundColor: AppTheme.getTextColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () {
            context.read<NewChatBloc>().add(FetchNewChatList());
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            if (widget.userImageUrl != null &&
                widget.userImageUrl!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CachedNetworkImage(
                  imageUrl: _fullProfileImageUrl(widget.userImageUrl!),
                  width: 34,
                  height: 34,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 17,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => _buildHeaderAvatar(),
                  errorWidget: (context, url, error) =>
                      _buildHeaderAvatar(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildHeaderAvatar(),
              ),
            Flexible(
              child: Text(
                widget.userName,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (widget.propertyId != null)
            IconButton(
              tooltip: _conversationStatus == 'COMPLETED'
                  ? 'Reopen conversation'
                  : 'Complete conversation',
              onPressed:
                  _isUpdatingConversation ? null : _toggleConversationStatus,
              icon: _isUpdatingConversation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _conversationStatus == 'COMPLETED'
                          ? Icons.restart_alt
                          : Icons.check_circle_outline,
                    ),
            ),
          IconButton(
            tooltip: 'Refresh messages',
            onPressed: _fetchChat,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<NewChatBloc, NewChatState>(builder: (context, state) {
        if (state is NewChatLoadingState) {
          return LoadingWidget();
        } else if (state is NewChatLoadedState) {
          return Column(
            children: [
              if (widget.propertyId != null) _buildPropertyContext(),
              Expanded(
                child: Chat(
            theme: ChatTheme(
              colors: ChatColors(
                primary: AppTheme.primaryblue,
                onPrimary: Colors.white,
                surface: AppTheme.getCardColor(context),
                onSurface: AppTheme.getTextColor(context),
                surfaceContainer: AppTheme.getBackgroundColor(context),
                surfaceContainerLow: isDarkMode
                    ? AppTheme.darkSurface
                    : AppTheme.whiteColor,
                surfaceContainerHigh: AppTheme.getCardColor(context),
              ),
              typography: ChatTypography.fromThemeData(Theme.of(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ).borderRadius,
            ),
            chatController: _chatController,
            currentUserId: widget.fromUserId,
            onMessageSend: _conversationStatus == 'COMPLETED'
                ? null
                : (text) {
                    context.read<NewChatBloc>().add(
                          FetchNewChat(
                            currentUserId: widget.fromUserId,
                            toUserId: widget.toUserId,
                            propertyId: widget.propertyId,
                            isSendMessage: true,
                            sendMessage: {
                              "fromUserId": widget.fromUserId,
                              "toUserId": widget.toUserId,
                              "text": text,
                              if (widget.propertyId != null)
                                "propertyId": widget.propertyId,
                            },
                          ),
                        );
                  },
            resolveUser: (UserID id) async {
              return User(id: widget.fromUserId, name: widget.userName);
            },
                ),
              ),
            ],
          );
        } else {
          return SizedBox();
        }
      }, listener: (context, state) {
        if (state is NewChatErrorState) {
          CustomSnackBar.showError(context, "Sorry, failed to fetch message.");
        } else if (state is NewChatLoadedState) {
          _chatController.setMessages(state.messages);
          if (_conversationStatus != state.conversationStatus) {
            setState(() => _conversationStatus = state.conversationStatus);
          }
        }
      }),
    );
  }

  Widget _buildPropertyContext() {
    final title = _propertyTitle ?? 'Property conversation';
    final address = _propertyAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryblue.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, color: AppTheme.primaryblue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (address != null && address.trim().isNotEmpty)
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  String _fullProfileImageUrl(String url) => ImageHelper.getFullImageUrl(url);

  Widget _buildHeaderAvatar() {
    return CircleAvatar(
      radius: 17,
      backgroundColor: AppTheme.primaryblue.withValues(alpha: 0.15),
      child: Text(
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primaryblue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
