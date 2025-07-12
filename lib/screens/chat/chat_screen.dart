// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_event.dart';
import 'package:pearlnest/screens/chat/individual_chat_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/screens/chat/chat_conversation.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({
    super.key,
    required this.user,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatConversation> _allConversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize chat service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const ChatInitialize());
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadConversations() {
    _allConversations = ChatConversation.getSampleConversations();
    _filteredConversations = List.from(_allConversations);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredConversations = List.from(_allConversations);
      } else {
        _filteredConversations = _allConversations.where((conversation) {
          return conversation.landlordName.toLowerCase().contains(query) ||
                 conversation.propertyTitle.toLowerCase().contains(query) ||
                 conversation.lastMessage.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredConversations = List.from(_allConversations);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Chat',
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildConversationsList(),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: AppTheme.whiteColor,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightGreyColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.greyColor.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search landlords or properties...',
                hintStyle: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.greyColor,
                  size: 20,
                ),
                suffixIcon: _isSearching
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: Icon(
                          Icons.clear,
                          color: AppTheme.greyColor,
                          size: 20,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.blackColor,
              ),
            ),
          ),
          if (_isSearching) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: AppTheme.greyColor,
                ),
                SizedBox(width: 8),
                Text(
                  '${_filteredConversations.length} result${_filteredConversations.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return Expanded(
      child: _filteredConversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredConversations.length,
              itemBuilder: (context, index) {
                final conversation = _filteredConversations[index];
                return _buildConversationTile(conversation);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.greyColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            _isSearching ? 'No conversations found' : 'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try searching with different keywords'
                : 'Start browsing properties to connect\nwith landlords',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blackColor.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightGreyColor,
              ),
              child: ClipOval(
                child: conversation.landlordProfilePic.isNotEmpty
                    ? Image.asset(
                        conversation.landlordProfilePic,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(conversation.landlordName);
                        },
                      )
                    : _buildDefaultAvatar(conversation.landlordName),
              ),
            ),
            if (conversation.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.landlordName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              conversation.propertyTitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryblue,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: conversation.unreadCount > 0
                          ? AppTheme.blackColor
                          : AppTheme.greyColor,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          _openChatDetail(conversation);
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
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
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppTheme.whiteColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

    void _openChatDetail(ChatConversation conversation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualChatScreen(
            conversation: conversation,
            currentUser: widget.user,
          ),
        ),
      ).then((_) {
        _loadConversations();
      });
    }
}
