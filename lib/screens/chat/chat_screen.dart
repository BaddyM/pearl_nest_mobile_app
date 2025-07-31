// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/apis/chat_service.dart';
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
  bool _isLoading = false;

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

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch conversations from API first
      final apiConversations = await ChatService.fetchChatList();

      // Also fetch available admin conversations
      final adminConversations = await ChatService.getAdminConversations();

      final allConversations = <ChatConversation>[];

      // Add API conversations if available
      if (apiConversations.isNotEmpty) {
        allConversations.addAll(apiConversations);
      }

      // Always include admin conversations for support
      if (adminConversations.isNotEmpty) {
        // Avoid duplicates by checking if admin conversations are already in API conversations
        for (final adminConv in adminConversations) {
          final isDuplicate = allConversations.any((conv) => conv.landlordId == adminConv.landlordId);
          if (!isDuplicate) {
            allConversations.add(adminConv);
          }
        }
      }

      // If no conversations at all, show a fallback
      if (allConversations.isEmpty) {
        // Try to get a single admin conversation for fallback
        final fallbackConv = await ChatService.getAdminConversation();
        if (fallbackConv != null) {
          allConversations.add(fallbackConv);
        }
      }

      setState(() {
        _allConversations = allConversations;
        _filteredConversations = List.from(_allConversations);
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to admin conversation on error
      try {
        final fallbackConv = await ChatService.getAdminConversation();
        final fallbackConversations = fallbackConv != null ? [fallbackConv] : <ChatConversation>[];

        setState(() {
          _allConversations = fallbackConversations;
          _filteredConversations = List.from(_allConversations);
          _isLoading = false;
        });
      } catch (fallbackError) {
        setState(() {
          _allConversations = [];
          _filteredConversations = [];
          _isLoading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations. ${_allConversations.isEmpty ? 'No admin available.' : 'Showing available chats.'}'),
            backgroundColor: _allConversations.isEmpty ? Colors.red : Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredConversations = List.from(_allConversations);
      } else {
        _filteredConversations = _allConversations.where((conversation) {
          return conversation.landlordName.toLowerCase().contains(query) || conversation.propertyTitle.toLowerCase().contains(query) || conversation.lastMessage.toLowerCase().contains(query);
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
        automaticallyImplyLeading: true,
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
        actions: [
          // Debug button for development (only show in debug mode)
          if (kDebugMode)
            PopupMenuButton<String>(
              icon: Icon(Icons.bug_report, color: AppTheme.blackColor),
              onSelected: (value) {
                if (value == 'debug_chat') {
                  _showDebugInfo();
                } else if (value == 'test_api') {
                  _testApiConnectivity();
                } else if (value == 'test_socket') {
                  _testSocketConnectivity();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'debug_chat',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Debug Chat Service'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'test_api',
                  child: Row(
                    children: [
                      Icon(Icons.api, size: 18),
                      SizedBox(width: 8),
                      Text('Test API'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'test_socket',
                  child: Row(
                    children: [
                      Icon(Icons.wifi, size: 18),
                      SizedBox(width: 8),
                      Text('Test Socket'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadConversations();
              },
              color: AppTheme.primaryblue,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryblue,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading conversations...',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredConversations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            return _buildConversationTile(conversation);
                          },
                        ),
            ),
          ),
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
            _isSearching ? 'Try searching with different keywords' : 'Start browsing properties to connect\nwith landlords',
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
                      color: conversation.unreadCount > 0 ? AppTheme.blackColor : AppTheme.greyColor,
                      fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
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
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => IndividualChatScreen(
    //       conversation: conversation,
    //       currentUser: widget.user,
    //     ),
    //   ),
    // ).then((_) {
    //   _loadConversations();
    // });
  }

  // Debug methods for development - output to terminal only
  void _showDebugInfo() async {
    //debugPrint('🔧 === USER REQUESTED COMPREHENSIVE DEBUG ===');
    //debugPrint('🔧 Running comprehensive chat service debug...');

    //debugPrint('🔧 === COMPREHENSIVE DEBUG COMPLETE ===');
    //debugPrint('🔧 Check the debug output above for detailed information.');
  }

  void _testApiConnectivity() async {
    //debugPrint('🧪 === USER REQUESTED API CONNECTIVITY TEST ===');
    //debugPrint('🧪 Testing API connectivity...');
  }

  void _testSocketConnectivity() async {
    //debugPrint('🔌 === USER REQUESTED SOCKET CONNECTIVITY TEST ===');
    //debugPrint('🔌 Testing socket connectivity...');
  }
}
