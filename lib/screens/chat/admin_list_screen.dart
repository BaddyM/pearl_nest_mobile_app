import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/models/admin.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_event.dart';
import 'package:pearlnest/screens/chat/individual_chat_screen.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/utils/image_helper.dart';

class AdminListScreen extends StatefulWidget {
  final User user;
  final String? propertyTitle; // Optional, for context-specific chats
  final bool randomAdminOnly;

  const AdminListScreen({
    super.key,
    required this.user,
    this.propertyTitle,
    this.randomAdminOnly = false,
  });

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<Admin> _admins = [];
  List<UnreadChat> _unread = [];
  bool _isLoading = true;
  bool _isStartingRandomChat = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdmins();

    // Initialize chat service
    context.read<ChatBloc>().add(const ChatInitialize());
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final admins = await ChatService.fetchAvailableAdmins();

      if (mounted) {
        final availableAdmins = admins.isNotEmpty && admins.first is List
            ? List<Admin>.from(admins.first as List)
            : <Admin>[];
        setState(() {
          _admins = availableAdmins;
          _unread = admins.length > 1 && admins[1] is List
              ? List<UnreadChat>.from(admins[1] as List)
              : <UnreadChat>[];
          _isLoading = false;
          if (widget.randomAdminOnly && availableAdmins.isNotEmpty) {
            _isStartingRandomChat = true;
          } else if (widget.randomAdminOnly) {
            _errorMessage = 'No support agents are available right now. Please try again later.';
          }
        });
        if (widget.randomAdminOnly && availableAdmins.isNotEmpty) {
          final admin = availableAdmins[Random().nextInt(availableAdmins.length)];
          await _startChatWithAdmin(admin);
        }
      }
    } catch (e) {
      debugPrint('❌ AdminListScreen: Error loading admins - $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load admin list. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadAdmins();
  }

  Future<void> _startChatWithAdmin(Admin admin) async {
    try {
      // Create or get conversation with this admin
      final conversation = await ChatService.getOrCreateConversation(
        adminId: admin.id,
        adminName: admin.name,
        adminProfilePic: admin.profilePicture,
        isOnline: admin.isOnline,
        propertyTitle: widget.propertyTitle,
      );

      if (conversation != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualChatScreen(
              adminContact: admin.contact,
              conversation: conversation,
              currentUser: widget.user,
              isOnline: admin.isOnline,
            ),
          ),
        );
        if (result == "popped") {
          _onRefresh();
        }
        if (widget.randomAdminOnly && mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (widget.randomAdminOnly && mounted) {
          setState(() {
            _isStartingRandomChat = false;
            _errorMessage = 'Unable to start a support chat. Please try again.';
          });
        }
        _showErrorSnackBar('Unable to start chat. Please try again.');
      }
    } catch (e) {
      //debugPrint('❌ Error starting chat with admin: $e');
      if (widget.randomAdminOnly && mounted) {
        setState(() {
          _isStartingRandomChat = false;
          _errorMessage = 'Unable to connect to support right now. Please try again.';
        });
      }
      _showErrorSnackBar('Failed to start chat. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      CustomSnackBar.showError(
        context,
        message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Chat',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppTheme.getTextColor(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryblue,
        backgroundColor: AppTheme.getBackgroundColor(context),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.randomAdminOnly && (_isLoading || _isStartingRandomChat)) {
      return _buildLoadingState();
    }
    if (widget.randomAdminOnly && _errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, size: 48, color: AppTheme.primaryblue),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _onRefresh,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_admins.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAdminList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading support team...',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load support team',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent_outlined,
              size: 64,
              color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.6),
            ),
            SizedBox(height: 16),
            Text(
              'No Support Available',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Our support team is currently unavailable. Please try again later.',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _admins.length,
      itemBuilder: (context, index) {
        final admin = _admins[index];
        bool unread = _unread.any((msg) => msg.id == admin.id);
        return _buildAdminCard(admin, unread);
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryblue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat with Support Team',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a support agent to start chatting',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(Admin admin, bool unread) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            unread = true;
            final userId = ChatService.getCurrentUserId();
            context.read<ChatBloc>().add(ChatMarkAsRead(fromUserId: admin.id, toUserId: userId.toString()));
            _startChatWithAdmin(admin);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryblue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: admin.profilePicture != null && admin.profilePicture!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            ImageHelper.getFullImageUrl(
                              admin.profilePicture!,
                            ),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(admin),
                          ),
                        )
                      : _buildDefaultAvatar(admin),
                ),
                SizedBox(width: 16),

                // Admin Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              admin.name,
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Online status indicator
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        admin.role ?? 'Support Agent',
                        style: TextStyle(
                          color: AppTheme.primaryblue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (admin.department != null && admin.department!.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          admin.department!,
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            admin.isAvailable ? Icons.check_circle : Icons.schedule,
                            size: 14,
                            color: admin.isAvailable ? Colors.green : Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            admin.isAvailable ? 'Available' : 'Offline',
                            style: TextStyle(
                              color: admin.isAvailable ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chat arrow
                unread == true
                    ? Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(Admin admin) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryblue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
