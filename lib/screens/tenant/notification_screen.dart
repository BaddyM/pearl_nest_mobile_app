import 'package:flutter/material.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/notification.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/notification_api_service.dart';

class NotificationScreen extends StatefulWidget {
  final User user;

  const NotificationScreen({super.key, required this.user});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'All';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalCount = 0;
  int _unreadCount = 0;

  final List<String> _filterOptions = [
    'All',
    'Unread',
    'Properties',
    'Messages',
    'Bookings',
    'System'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _notifications.clear();
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      // Map filter to API parameter
      String? filterParam;
      switch (_selectedFilter) {
        case 'Unread':
          filterParam = 'unread';
          break;
        case 'All':
        default:
          filterParam = null;
          break;
      }

      final result = await NotificationApiService.fetchNotifications(
        page: _currentPage,
        limit: 20,
        filter: filterParam,
      );

      if (result['success'] == true) {
        final notificationsData = result['notifications'] as List<dynamic>;
        final notifications = notificationsData
            .map((data) => NotificationItem.fromJson(data as Map<String, dynamic>))
            .toList();

        setState(() {
          if (isRefresh) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }
          _totalCount = result['total'] ?? 0;
          _hasMore = result['hasMore'] ?? false;
          _isLoading = false;
          _hasError = false;
          _errorMessage = '';
        });

        // Also get unread count
        _getUnreadCount();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to load notifications';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  void _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    
    try {
      String? filterParam;
      switch (_selectedFilter) {
        case 'Unread':
          filterParam = 'unread';
          break;
        case 'All':
        default:
          filterParam = null;
          break;
      }

      final result = await NotificationApiService.fetchNotifications(
        page: _currentPage,
        limit: 20,
        filter: filterParam,
      );

      if (result['success'] == true) {
        final notificationsData = result['notifications'] as List<dynamic>;
        final notifications = notificationsData
            .map((data) => NotificationItem.fromJson(data as Map<String, dynamic>))
            .toList();

        setState(() {
          _notifications.addAll(notifications);
          _hasMore = result['hasMore'] ?? false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to load more notifications');
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('An unexpected error occurred while loading more notifications');
    }
  }

  void _getUnreadCount() async {
    try {
      final result = await NotificationApiService.getNotificationCount();
      if (result['success'] == true) {
        setState(() {
          _unreadCount = result['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      // Silently fail for count - not critical
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryblue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<NotificationItem> get _filteredNotifications {
    if (_notifications.isEmpty) return [];
    
    // For API-based filtering, we already get filtered results from the server
    // Only need to apply client-side filtering for types that aren't handled by the API
    switch (_selectedFilter) {
      case 'Properties':
        return _notifications
            .where((n) => n.type == NotificationType.propertyUpdate ||
                n.type == NotificationType.favorite)
            .toList();
      case 'Messages':
        return _notifications
            .where((n) => n.type == NotificationType.message)
            .toList();
      case 'Bookings':
        return _notifications
            .where((n) => n.type == NotificationType.booking ||
                n.type == NotificationType.payment)
            .toList();
      case 'System':
        return _notifications
            .where((n) => n.type == NotificationType.system)
            .toList();
      case 'All':
      case 'Unread':
      default:
        // For 'All' and 'Unread', the API already handles the filtering
        return _notifications;
    }
  }

  void _onFilterChanged(String newFilter) {
    if (newFilter != _selectedFilter) {
      setState(() {
        _selectedFilter = newFilter;
        _notifications.clear();
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
      _loadNotifications();
    }
  }

  void _markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;

    try {
      final result = await NotificationApiService.markAsRead(notification.id);
      if (result['success'] == true) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
          if (_unreadCount > 0) {
            _unreadCount--;
          }
        });
        _showSuccessSnackBar('Notification marked as read');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to mark as read');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while marking as read');
    }
  }

  void _markAllAsRead() async {
    try {
      final result = await NotificationApiService.markAllAsRead();
      if (result['success'] == true) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          _unreadCount = 0;
        });
        _showSuccessSnackBar('All notifications marked as read');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to mark all as read');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while marking all as read');
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.propertyUpdate:
        return Icons.home_outlined;
      case NotificationType.booking:
        return Icons.calendar_today_outlined;
      case NotificationType.message:
        return Icons.message_outlined;
      case NotificationType.favorite:
        return Icons.favorite_outline;
      case NotificationType.system:
        return Icons.system_update_outlined;
      case NotificationType.payment:
        return Icons.payment_outlined;
      case NotificationType.review:
        return Icons.star_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.propertyUpdate:
        return AppTheme.primaryblue;
      case NotificationType.booking:
        return Colors.blue;
      case NotificationType.message:
        return Colors.purple;
      case NotificationType.favorite:
        return Colors.red;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.review:
        return Colors.amber;
    }
  }

  void _deleteNotification(String notificationId) async {
    try {
      final result = await NotificationApiService.deleteNotification(notificationId);
      if (result['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
          _totalCount = _totalCount > 0 ? _totalCount - 1 : 0;
        });
        _showSuccessSnackBar('Notification deleted');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while deleting notification');
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadNotifications(isRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryblue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _isLoading 
          ? _buildLoadingState() 
          : _hasError 
              ? _buildErrorState() 
              : _buildNotificationContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.getBackgroundColor(context),
      elevation: 0,
      automaticallyImplyLeading: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          if (_unreadCount > 0)
            Text(
              '$_unreadCount unread notifications',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: AppTheme.primaryblue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: _buildFilterTabs(),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 45,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return GestureDetector(
            onTap: () {
              _onFilterChanged(filter);
            },
            child: Container(
              margin: EdgeInsets.only(right: 12, bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryblue
                    : AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryblue
                      : AppTheme.greyColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.whiteColor
                      : AppTheme.getSecondaryTextColor(context),
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryblue),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent() {
    final filteredNotifications = _filteredNotifications;

    if (filteredNotifications.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications(isRefresh: true);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: filteredNotifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredNotifications.length) {
            // Load more indicator at the bottom
            if (_isLoadingMore) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryblue,
                  ),
                ),
              );
            } else if (_hasMore) {
              // Trigger load more when reaching the end
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMoreNotifications();
              });
              return SizedBox(height: 16);
            }
            return SizedBox.shrink();
          }
          
          final notification = filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.lightGreyColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 60,
              color: AppTheme.getSecondaryTextColor(context)
            ),
          ),
          SizedBox(height: 24),
          Text(
            _selectedFilter == 'All' 
                ? 'No notifications yet'
                : 'No ${_selectedFilter.toLowerCase()} notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'When you have notifications, they\'ll appear here'
                : 'Try selecting a different filter',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: AppTheme.getCardColor(context),
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted', style: TextStyle(color: AppTheme.lightGreyColor),),
            duration: Duration(milliseconds: 500),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? AppTheme.getCardColor(context) 
                : AppTheme.primaryblue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.2)
                  : AppTheme.primaryblue.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead 
                                  ? FontWeight.w600 
                                  : FontWeight.bold,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryblue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    if (notification.propertyTitle != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.getCardColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 14,
                              color: AppTheme.primaryblue,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                notification.propertyTitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getTextColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    Text(
                      _getTimeAgo(notification.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.getSecondaryTextColor(context),
                  size: 20,
                ),
                color: AppTheme.getCardColor(context),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      _markAsRead(notification);
                      break;
                    case 'delete':
                      _deleteNotification(notification.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18, color: AppTheme.getTextColor(context),),
                          SizedBox(width: 8),
                          Text('Mark as read',
                          style: TextStyle(color: AppTheme.getTextColor(context)),),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    switch (notification.type) {
      case NotificationType.propertyUpdate:
      case NotificationType.favorite:
        if (notification.propertyId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening property: ${notification.propertyTitle}', style: TextStyle(color: AppTheme.lightGreyColor),),
              duration: Duration(milliseconds: 500),
              backgroundColor: AppTheme.primaryblue,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
        break;
      case NotificationType.message:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening chat...', style: TextStyle(color: AppTheme.lightGreyColor),),
            duration: Duration(milliseconds: 500),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        break;
      case NotificationType.booking:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening booking details...', style: TextStyle(color: AppTheme.lightGreyColor),),
            duration: Duration(milliseconds: 500),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        break;
      case NotificationType.payment:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening payment details...', style: TextStyle(color: AppTheme.lightGreyColor),),
            duration: Duration(milliseconds: 500),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        break;
      case NotificationType.review:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening reviews...', style: TextStyle(color: AppTheme.lightGreyColor),),
            duration: Duration(milliseconds: 500),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        break;
      case NotificationType.system:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('System notification opened', style: TextStyle(color: AppTheme.lightGreyColor),),
            duration: Duration(milliseconds: 500),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        break;
    }
  }
}