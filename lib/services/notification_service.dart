import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static String? _fcmToken;

  // Notification channels
  static const String _defaultChannelId = 'pearlnest_default';
  static const String _chatChannelId = 'pearlnest_chat';
  static const String _bookingChannelId = 'pearlnest_booking';
  static const String _generalChannelId = 'pearlnest_general';

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      //debugPrint('🚀 Initializing NotificationService...');

      // Initialize Flutter Local Notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Cloud Messaging
      await _initializeFirebaseMessaging();

      // Request permissions
      await _requestNotificationPermissions();

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
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

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
      _handleNotificationNavigation(notificationResponse.payload!);
    }
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        _defaultChannelId,
        'Default Notifications',
        description: 'Default notification channel for PearlNest',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        _chatChannelId,
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        _bookingChannelId,
        'Booking Updates',
        description: 'Notifications for booking updates and confirmations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        _generalChannelId,
        'General Notifications',
        description: 'General app notifications and updates',
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

  /// Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    //debugPrint('FCM Permission status: ${settings.authorizationStatus}');

    // Request local notifications permissions
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    // Request additional permissions
    await _requestAdditionalPermissions();
  }

  /// Request additional permissions
  static Future<void> _requestAdditionalPermissions() async {
    // Request notification permission for Android 13+
    await Permission.notification.request();

    // Request exact alarm permission if needed
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
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
    //debugPrint('📱 Received foreground message: ${message.messageId}');
    //debugPrint('Title: ${message.notification?.title}');
    //debugPrint('Body: ${message.notification?.body}');
    //debugPrint('Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    //debugPrint('📱 Received background message: ${message.messageId}');
    //debugPrint('Title: ${message.notification?.title}');
    //debugPrint('Body: ${message.notification?.body}');
    //debugPrint('Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    //debugPrint('📱 Notification tapped: ${message.messageId}');
    //debugPrint('Data: ${message.data}');

    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data.toString());
  }

  /// Handle initial message when app is launched from terminated state
  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      //debugPrint('📱 App launched from notification: ${initialMessage.messageId}');
      _handleNotificationNavigation(initialMessage.data.toString());
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
        message.notification?.title ?? 'PearlNest',
        message.notification?.body ?? 'You have a new notification',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      //debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Get channel ID based on message type
  static String _getChannelIdFromMessage(RemoteMessage message) {
    String type = message.data['type'] ?? 'default';

    switch (type.toLowerCase()) {
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
        return 'Chat Messages';
      case _bookingChannelId:
        return 'Booking Updates';
      case _generalChannelId:
        return 'General Notifications';
      default:
        return 'Default Notifications';
    }
  }

  /// Get channel description from ID
  static String _getChannelDescriptionFromId(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return 'Notifications for new chat messages';
      case _bookingChannelId:
        return 'Notifications for booking updates and confirmations';
      case _generalChannelId:
        return 'General app notifications and updates';
      default:
        return 'Default notification channel for PearlNest';
    }
  }

  /// Handle notification navigation
  static void _handleNotificationNavigation(String payload) {
    // This would typically navigate to specific screens based on payload
    // For now, we'll just log the payload
    //debugPrint('🔄 Handling notification navigation: $payload');

    // Example navigation logic:
    // Map<String, dynamic> data = jsonDecode(payload);
    // String? type = data['type'];
    // String? id = data['id'];
    //
    // switch (type) {
    //   case 'chat':
    //     // Navigate to chat screen
    //     break;
    //   case 'booking':
    //     // Navigate to booking details
    //     break;
    //   default:
    //     // Navigate to home screen
    //     break;
    // }
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
        title,
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
