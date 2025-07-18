import 'package:flutter/material.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/widgets/app_theme.dart';

enum NotificationType {
  propertyUpdate,
  booking,
  message,
  favorite,
  system,
  payment,
  review,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyImage;
  final String? actionData;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.propertyId,
    this.propertyTitle,
    this.propertyImage,
    this.actionData,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    String? actionData,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      actionData: actionData ?? this.actionData,
    );
  }
}

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
  String _selectedFilter = 'All';

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

  void _loadNotifications() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _notifications = _getDummyNotifications();
        _isLoading = false;
      });
    });
  }

  List<NotificationItem> _getDummyNotifications() {
    return [
      NotificationItem(
        id: '1',
        title: 'New Property Match!',
        message: 'We found a perfect apartment that matches your preferences in Downtown.',
        type: NotificationType.propertyUpdate,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        isRead: false,
        propertyId: '1',
        propertyTitle: 'Modern Apartment in City Center',
        propertyImage: 'assets/images/img3.jpg',
      ),
      NotificationItem(
        id: '2',
        title: 'Booking Confirmed',
        message: 'Your booking for Cozy Airbnb Studio has been confirmed for next week.',
        type: NotificationType.booking,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        isRead: false,
        propertyId: '2',
        propertyTitle: 'Cozy Airbnb Studio',
        propertyImage: 'assets/images/img2.jpg',
      ),
      NotificationItem(
        id: '3',
        title: 'New Message',
        message: 'PearlNest sent you a message about the Airbnb Studio.',
        type: NotificationType.message,
        timestamp: DateTime.now().subtract(Duration(hours: 4)),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Price Drop Alert!',
        message: 'The price for Spacious Family House has dropped by 15%.',
        type: NotificationType.favorite,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        isRead: false,
        propertyId: '3',
        propertyTitle: 'Spacious Family House',
        propertyImage: 'assets/images/img1.jpg',
      ),
      NotificationItem(
        id: '5',
        title: 'Payment Successful',
        message: 'Your payment of UGX 500,000 has been processed successfully.',
        type: NotificationType.payment,
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: '6',
        title: 'New Review Received',
        message: 'You received a 5-star review for your Modern Apartment.',
        type: NotificationType.review,
        timestamp: DateTime.now().subtract(Duration(days: 3)),
        isRead: true,
      ),
      NotificationItem(
        id: '7',
        title: 'App Update Available',
        message: 'A new version of PearlNest is available with exciting features.',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(Duration(days: 5)),
        isRead: false,
      ),
    ];
  }

  List<NotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Unread':
        return _notifications.where((n) => !n.isRead).toList();
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
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

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

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildNotificationContent(),
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
              setState(() {
                _selectedFilter = filter;
              });
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

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildNotificationCard(notification);
      },
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
            _markAsRead(notification.id);
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
                      _markAsRead(notification.id);
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