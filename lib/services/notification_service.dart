import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/screens/chat/new_chat_conversation.dart';
import 'package:pearlnest/screens/chat/new_chat_list.dart';
import 'package:pearlnest/screens/landlord/landlord_booking_requests_screen.dart';
import 'package:pearlnest/screens/tenant/help_and_support_screen.dart';
import 'package:pearlnest/screens/tenant/notification_screen.dart';
import 'package:pearlnest/screens/tenant/bookings_list_screen.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static String? _fcmToken;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static Map<String, dynamic>? _pendingNavigation;

  // Notification channels
  static const String _defaultChannelId = 'pearlnest_default';
  static const String _chatChannelId = 'pearlnest_chat';
  static const String _bookingChannelId = 'pearlnest_booking';
  static const String _generalChannelId = 'pearlnest_general';

  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _schedulePendingNavigation();
  }

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      //debugPrint('🚀 Initializing NotificationService...');

      // Initialize Flutter Local Notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Cloud Messaging
      await _initializeFirebaseMessaging();

      // Setup FCM listeners
      _setupFCMListeners();

      // Get FCM token
      await _getFCMToken();

      _isInitialized = true;
      //debugPrint('✅ NotificationService initialized successfully');
    } catch (e, stackTrace) {
      //debugPrint('❌ Error initializing NotificationService: $e');
      //debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Initialize Flutter Local Notifications
  static Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    // Combined initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    //debugPrint('🔔 Notification tapped: ${notificationResponse.id}');
    //debugPrint('Payload: ${notificationResponse.payload}');

    // Handle navigation based on notification payload
    if (notificationResponse.payload != null) {
      final payload = _asMap(notificationResponse.payload);
      navigateFromNotification(payload ?? {'type': notificationResponse.payload});
    }
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        _defaultChannelId,
        'PearlNest Updates',
        description: 'Important updates from PearlNest',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        _chatChannelId,
        'PearlNest Messages',
        description: 'New messages from PearlNest conversations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        _bookingChannelId,
        'PearlNest Bookings',
        description: 'Booking updates and confirmations from PearlNest',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        _generalChannelId,
        'PearlNest News',
        description: 'General news and updates from PearlNest',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
        showBadge: true,
      ),
    ];

    for (AndroidNotificationChannel channel in channels) {
      await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }
  }

  /// Initialize Firebase Cloud Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Configure FCM settings
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set auto initialization
    await _firebaseMessaging.setAutoInitEnabled(true);
  }

  static Future<bool> requestPushPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return false;
    }

    final androidPermission = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return androidPermission ?? true;
  }

  /// Setup FCM listeners
  static void _setupFCMListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    _handleInitialMessage();
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // //debugPrint('📱 Received foreground message: ${message.messageId}');
    // //debugPrint('Title: ${message.notification?.title}');
    // //debugPrint('Body: ${message.notification?.body}');
    // //debugPrint('Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // //debugPrint('📱 Received background message: ${message.messageId}');
    // //debugPrint('Title: ${message.notification?.title}');
    // //debugPrint('Body: ${message.notification?.body}');

    // //debugPrint('Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    //debugPrint('📱 Notification tapped: ${message.messageId}');
    //debugPrint('Data: ${message.data}');

    // Handle navigation based on notification data
    navigateFromNotification(Map<String, dynamic>.from(message.data));
  }

  /// Handle initial message when app is launched from terminated state
  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      //debugPrint('📱 App launched from notification: ${initialMessage.messageId}');
      navigateFromNotification(Map<String, dynamic>.from(initialMessage.data));
    }
  }

  /// Show local notification using Flutter Local Notifications
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      String channelId = _getChannelIdFromMessage(message);
      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Android notification details
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        channelId,
        _getChannelNameFromId(channelId),
        channelDescription: _getChannelDescriptionFromId(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification',
      );

      // iOS notification details
      const DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      // Show notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        _brandedTitle(message.notification?.title ?? 'PearlNest'),
        message.notification?.body ?? 'You have a new notification',
        notificationDetails,
        payload:         jsonEncode(message.data),
      );
    } catch (e) {
      //debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Get channel ID based on message type
  static String _getChannelIdFromMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? 'default').toString().toLowerCase();

    switch (type) {
      case 'chat':
      case 'message':
        return _chatChannelId;
      case 'booking':
      case 'reservation':
        return _bookingChannelId;
      case 'general':
      case 'update':
        return _generalChannelId;
      default:
        return _defaultChannelId;
    }
  }

  /// Get channel name from ID
  static String _getChannelNameFromId(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return 'PearlNest Messages';
      case _bookingChannelId:
        return 'PearlNest Bookings';
      case _generalChannelId:
        return 'PearlNest News';
      default:
        return 'PearlNest Updates';
    }
  }

  /// Get channel description from ID
  static String _getChannelDescriptionFromId(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return 'New messages from PearlNest conversations';
      case _bookingChannelId:
        return 'Booking updates and confirmations from PearlNest';
      case _generalChannelId:
        return 'General news and updates from PearlNest';
      default:
        return 'Important updates from PearlNest';
    }
  }

  /// Routes actionable notifications while preserving useful legacy destinations.
  static Future<bool> navigateFromNotification(
    Map<String, dynamic> notification, {
    User? user,
    bool fallbackToNotificationScreen = true,
  }) async {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pendingNavigation = notification;
      _schedulePendingNavigation();
      return false;
    }

    User? loadedUser = user;
    if (loadedUser == null) {
      try {
        loadedUser = await AuthService.getCurrentUser();
      } catch (_) {
        return false;
      }
    }
    final currentUser = loadedUser;
    if (currentUser == null || currentUser.id.isEmpty) return false;

    final data = <String, dynamic>{...notification};
    final metadata = _asMap(
      notification['metadata'] ??
          notification['data'] ??
          notification['notificationData'],
    );
    if (metadata != null) data.addAll(metadata);
    final actionPayload = _asMap(
      notification['actionData'] ??
          notification['action_data'] ??
          notification['action'],
    );
    if (actionPayload != null) data.addAll(actionPayload);

    final rawAction = notification['action'] ??
        notification['actionData'] ??
        notification['action_data'] ??
        data['destination'] ??
        data['screen'] ??
        data['route'] ??
        data['actionType'];
    final action = _normalizedAction(rawAction);
    final type = _normalizedAction(data['type'] ?? data['notificationType']);
    final propertyData = _asMap(data['property']);
    final propertyId = _stringValue(
      data['propertyId'] ?? data['property_id'] ?? propertyData?['id'],
    );
    final bookingId =
        _stringValue(data['bookingId'] ?? data['booking_id']);
    final destination = _isRecognizedDestination(action)
        ? action
        : type.isNotEmpty && type != 'system' && type != 'general'
            ? type
            : bookingId != null
                ? 'booking'
                : propertyId != null
                    ? 'property'
                    : '';

    if (_containsAny(destination, ['chat', 'message'])) {
      String? resolvedPeerId;
      for (final candidate in [
        data['otherUserId'],
        data['recipientId'],
        data['senderId'],
        data['fromUserId'],
        data['toUserId'],
        data['userId'],
      ]) {
        final candidateId = _stringValue(candidate);
        if (candidateId != null && candidateId != currentUser.id) {
          resolvedPeerId = candidateId;
          break;
        }
      }
      final peerId = resolvedPeerId;
      final peerName = _stringValue(
            data['otherUserName'] ??
                data['recipientName'] ??
                data['senderName'] ??
                data['userName'],
          ) ??
          'Chat';
      final navContext = _navigatorKey?.currentContext;
      if (peerId != null && peerId != currentUser.id && navContext != null) {
        try {
          navContext.read<NewChatBloc>().socket.connect(currentUser.id);
        } catch (_) {
          // A legacy notification may arrive before chat providers are ready.
        }
        navigator.push(
          MaterialPageRoute(
            builder: (_) => NewChatConversation(
              fromUserId: currentUser.id,
              toUserId: peerId,
              userName: peerName,
              userImageUrl: _stringValue(
                data['profilePicture'] ?? data['profileImage'] ?? data['avatar'],
              ),
              propertyId: propertyId,
            ),
          ),
        );
      } else {
        navigator.push(
          MaterialPageRoute(builder: (_) => NewChatList(user: currentUser)),
        );
      }
      return true;
    }

    if (_containsAny(destination, ['booking', 'reservation', 'payment'])) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => currentUser.userType == UserType.landlord
              ? LandlordBookingRequestsScreen(user: currentUser)
              : BookingsListScreen(user: currentUser),
        ),
      );
      return true;
    }

    if (_containsAny(destination, ['property', 'favorite', 'favourite']) &&
        propertyId != null) {
      final result = await PropertyService.getPropertyById(propertyId);
      final loadedProperty = result['property'];
      if (result['success'] == true && loadedProperty is Property) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                PropertyDetailsScreen(
                  property: loadedProperty,
                  user: currentUser,
                ),
          ),
        );
        return true;
      }
    }

    if (_containsAny(destination, ['help', 'support'])) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => HelpSupportScreen(user: currentUser),
        ),
      );
      return true;
    }

    if (_containsAny(destination, ['notification'])) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => NotificationScreen(user: currentUser),
        ),
      );
      return true;
    }

    // Keep legacy notifications useful even when they contain only a type.
    if (type.isNotEmpty && type != 'system' && type != 'general') {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => NotificationScreen(user: currentUser),
        ),
      );
      return true;
    }
    if (fallbackToNotificationScreen) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => NotificationScreen(user: currentUser),
        ),
      );
      return true;
    }
    return false;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static String _normalizedAction(dynamic value) {
    if (value is Map) {
      final nested = _asMap(value);
      return _normalizedAction(
        nested?['destination'] ??
            nested?['screen'] ??
            nested?['route'] ??
            nested?['action'] ??
            nested?['actionType'] ??
            nested?['type'],
      );
    }
    return value?.toString().trim().toLowerCase().replaceAll('_', '').replaceAll('-', '') ?? '';
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty || stringValue == 'null' ? null : stringValue;
  }

  static bool _containsAny(String value, List<String> options) =>
      options.any((option) => value.contains(option));

  static String _brandedTitle(String title) =>
      title.toLowerCase().startsWith('pearlnest') ? title : 'PearlNest • $title';

  static bool _isRecognizedDestination(String value) => _containsAny(
        value,
        [
          'chat',
          'message',
          'booking',
          'reservation',
          'payment',
          'property',
          'favorite',
          'favourite',
          'support',
          'help',
          'notification',
        ],
      );

  static void _schedulePendingNavigation() {
    if (_pendingNavigation == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey?.currentState == null || _pendingNavigation == null) {
        return;
      }
      final pending = _pendingNavigation!;
      _pendingNavigation = null;
      navigateFromNotification(pending);
    });
  }

  /// Get FCM token
  static Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      //debugPrint('📱 FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      //debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Refresh FCM token
  static Future<String?> refreshFCMToken() async {
    return await _getFCMToken();
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      //debugPrint('📱 Subscribed to topic: $topic');
    } catch (e) {
      //debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      //debugPrint('📱 Unsubscribed from topic: $topic');
    } catch (e) {
      //debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Show local notification manually
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    try {
      String selectedChannelId = channelId ?? _defaultChannelId;
      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Android notification details
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        selectedChannelId,
        _getChannelNameFromId(selectedChannelId),
        channelDescription: _getChannelDescriptionFromId(selectedChannelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification',
      );

      // iOS notification details
      const DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      // Show notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        _brandedTitle(title),
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      //debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Check if notifications are allowed
  static Future<bool> areNotificationsAllowed() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }

    return false;
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission() ?? false;
    }

    return false;
  }
}
