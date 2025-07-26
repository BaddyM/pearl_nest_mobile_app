import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/models/admin.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_event.dart';
import 'package:pearlnest/screens/chat/individual_chat_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class AdminListScreen extends StatefulWidget {
  final User user;
  final String? propertyTitle; // Optional, for context-specific chats

  const AdminListScreen({
    super.key,
    required this.user,
    this.propertyTitle,
  });

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<Admin> _admins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdmins();

    // Initialize chat service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const ChatInitialize());
    });
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      //debugPrint('🔄 AdminListScreen: Loading admin list...');
      final admins = await ChatService.fetchAvailableAdmins();

      if (mounted) {
        setState(() {
          _admins = admins;
          _isLoading = false;
        });
        //debugPrint('✅ AdminListScreen: Loaded ${admins.length} admins');
      }
    } catch (e) {
      //debugPrint('❌ AdminListScreen: Error loading admins - $e');
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

  void _startChatWithAdmin(Admin admin) async {
    try {
      //debugPrint('💬 Starting chat with admin: ${admin.name}');

      // Create or get conversation with this admin
      final conversation = await ChatService.getOrCreateConversation(
        adminId: admin.id,
        adminName: admin.name,
        propertyTitle: widget.propertyTitle,
      );

      if (conversation != null && mounted) {
        // Navigate to individual chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualChatScreen(
              conversation: conversation,
              currentUser: widget.user,
            ),
          ),
        );
      } else {
        _showErrorSnackBar('Unable to start chat. Please try again.');
      }
    } catch (e) {
      //debugPrint('❌ Error starting chat with admin: $e');
      _showErrorSnackBar('Failed to start chat. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
      itemCount: _admins.length, // +1 for header
      itemBuilder: (context, index) {
        // if (index == 0) {
        //   return _buildHeader();
        // }

        final admin = _admins[index];
        return _buildAdminCard(admin);
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

  Widget _buildAdminCard(Admin admin) {
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
          onTap: () => _startChatWithAdmin(admin),
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
                            admin.profilePicture!,
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
                        children: [
                          Expanded(
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
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: admin.isOnline ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
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
                            admin.isAvailable ? 'Available' : 'Busy',
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
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.primaryblue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.getSecondaryTextColor(context),
                  size: 16,
                ),
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
