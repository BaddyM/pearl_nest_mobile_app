import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../models/chat_message.dart';
import '../models/admin.dart';
import '../screens/chat/chat_conversation.dart';
import 'api_client.dart';
import 'app_config.dart';
import 'auth_service.dart';

class ChatService {
  static socket_io.Socket? _socket;
  static String? _currentUserId;
  static bool _isConnected = false;
  static List<Admin> _availableAdmins = [];

  // Stream controllers for real-time updates
  static final _messageStreamController = StreamController<ChatMessage>.broadcast();
  static final _connectionStreamController = StreamController<bool>.broadcast();
  static final _adminsStreamController = StreamController<List<Admin>>.broadcast();

  // Getters for streams
  static Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  static Stream<bool> get connectionStream => _connectionStreamController.stream;
  static Stream<List<Admin>> get adminsStream => _adminsStreamController.stream;

  // Get connection status
  static bool get isConnected => _isConnected;

  // Get available admins
  static List<Admin> get availableAdmins => _availableAdmins;

  // Initialize and connect to socket with comprehensive debugging
  static Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    try {
      //debugPrint('🔍 Pre-connection checks:');

      // Get preferences and token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {}

      // Get user ID using AuthService
      _currentUserId = await AuthService.getUserId();

      if (token == null) {
        return;
      }

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        //debugPrint('❌ CANNOT CONNECT: No user ID found');
        //debugPrint('� Attempting to diagnose and fix user ID issue...');
        await AuthService.debugStoredData();

        //debugPrint('� Attempting to fix missing user ID...');
        final fixed = await AuthService.fixMissingUserId();
        if (fixed) {
          _currentUserId = await AuthService.getUserId();

          //debugPrint('✅ User ID fixed and retrieved: $_currentUserId');
        } else {
          //debugPrint('❌ Failed to fix user ID - cannot connect to chat');
          //debugPrint('   - User may need to re-login');
          //debugPrint('   - Check AuthService.fixMissingUserId() implementation');
          return;
        }
      }

      // Socket configuration
      final socketUrl = AppConfig.getCurrentBaseUrl();
      //print("Socket URL = ${socketUrl}");

      // Create socket instance
      //debugPrint('🔧 Creating socket instance...');
      _socket = socket_io.io(
          socketUrl,
          socket_io.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionDelay(1000)
              .setReconnectionDelayMax(5000)
              .setAuth({
                'token': token,
                'userId': _currentUserId,
              })
              .build());

      _setupEventListeners();

      final connectionStartTime = DateTime.now();

      _socket!.connect();
    } catch (e, stackTrace) {
      _isConnected = false;
      _connectionStreamController.add(false);

      // Specific error analysis
      if (e.toString().contains('network')) {
      } else if (e.toString().contains('auth')) {}
    } finally {
      //print("Socket process ended");
    }
  }

  // Setup event listeners with comprehensive debugging
  static void _setupEventListeners() {
    if (_socket == null) {
      //debugPrint('❌ Cannot setup event listeners - socket is null');
      return;
    }

    //debugPrint('🔧 Setting up socket event listeners...');

    _socket!.onConnect((_) {
      final connectTime = DateTime.now();
      _isConnected = true;
      _connectionStreamController.add(true);

      //debugPrint('   - Connection stream updated: true');

      // Register user with their ID
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        _socket!.emit('register', _currentUserId);
      } else {}

      //debugPrint('🏁 Socket connection setup complete');
    });

    _socket!.onDisconnect((reason) {
      final disconnectTime = DateTime.now();

      _isConnected = false;
      _connectionStreamController.add(false);

      //debugPrint('   - Connection stream updated: false');

      // Analyze disconnect reason
      if (reason.toString().contains('transport close')) {
        //debugPrint('🔍 Transport closed - likely network issue');
      } else if (reason.toString().contains('ping timeout')) {
        //debugPrint('🔍 Ping timeout - connection lost');
      } else if (reason.toString().contains('client namespace disconnect')) {
        //debugPrint('🔍 Client initiated disconnect');
      } else {
        //debugPrint('🔍 Other disconnect reason: $reason');
      }
    });

    _socket!.onConnectError((error) {
      //debugPrint('');
      //debugPrint('❌ === SOCKET CONNECTION ERROR ===');
      //debugPrint('   - Error: $error');
      //debugPrint('   - Error type: ${error.runtimeType}');
      //debugPrint('   - Connection attempt failed');

      _isConnected = false;
      _connectionStreamController.add(false);

      //debugPrint('   - Connection stream updated: false');

      // Analyze connection error
      if (error.toString().contains('timeout')) {
        //debugPrint('🔍 Connection timeout - server may be unreachable');
      } else if (error.toString().contains('refused')) {
        //debugPrint('🔍 Connection refused - server may be down');
      } else if (error.toString().contains('unauthorized')) {
        //debugPrint('🔍 Unauthorized - check authentication');
      }
    });

    _socket!.onError((error) {
      //debugPrint('');
      //debugPrint('❌ === SOCKET GENERAL ERROR ===');
      //debugPrint('   - Error: $error');
      //debugPrint('   - Error type: ${error.runtimeType}');
      //debugPrint('   - Error timestamp: ${DateTime.now()}');
    });

    // Listen for incoming messages with detailed debugging
    _socket!.on('sendMessage', (data) {
      final receiveTime = DateTime.now();

      try {
        //debugPrint('🔍 Parsing message data...');
        final message = ChatMessage.fromJson(data);

        // Add to message stream
        _messageStreamController.add(message);
      } catch (e, stackTrace) {
        //print("Error = ${e}");
        //print("Error = ${stackTrace}");
      }
    });

    // Listen for register acknowledgment
    _socket!.on('registered', (data) {
      //debugPrint('');
      //debugPrint('📝 === REGISTRATION ACKNOWLEDGMENT ===');
      //debugPrint('   - Acknowledgment time: ${DateTime.now()}');
      //debugPrint('   - Response data: $data');
      //debugPrint('   - Data type: ${data.runtimeType}');
      //debugPrint('   - User successfully registered with server');
    });

    // Listen for reconnection events
    _socket!.onReconnect((attempt) {
      final reconnectTime = DateTime.now();

      _isConnected = true;
      _connectionStreamController.add(true);

      // Re-register user after reconnection
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        //debugPrint('📤 Re-registering user after reconnection...');
        //debugPrint('   - User ID to re-register: $_currentUserId');

        _socket!.emit('register', _currentUserId);

        //debugPrint('✅ User re-registration event emitted');
        //debugPrint('   - Event: "register"');
        //debugPrint('   - Data: $_currentUserId');
      } else {
        //debugPrint('❌ CANNOT RE-REGISTER USER:');
        //debugPrint('   - User ID is null: ${_currentUserId == null}');
        //debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty ?? true}');
        //debugPrint('   - Current user ID value: $_currentUserId');
      }
    });

    // Listen for any other events (catch-all for debugging)
    _socket!.onAny((event, data) {
      if (event != 'sendMessage' && event != 'registered') {
        // Don't duplicate already logged events
        //debugPrint('');
        //debugPrint('🔍 === UNKNOWN SOCKET EVENT ===');
        //debugPrint('   - Event name: $event');
        //debugPrint('   - Event data: $data');
        //debugPrint('   - Event timestamp: ${DateTime.now()}');
        //debugPrint('   - Data type: ${data.runtimeType}');
      }
    });

    //debugPrint('✅ All socket event listeners configured');
  }

  // Send a message to the first available admin (for backward compatibility)
  static Future<void> sendMessageToAdmin({
    required String text,
  }) async {
    final firstAdminId = getFirstAdminUserId();
    if (firstAdminId == null) {
      throw Exception('No admin available to send message to');
    }
    return sendMessage(toUserId: firstAdminId, text: text);
  }

  // Send a message with comprehensive debugging (now supports any admin)
  static Future<void> sendMessage({
    required String toUserId,
    required String text,
    bool? isMedia,
  }) async {
    // Validate that message is only sent to admin users
    if (!isAdminUser(toUserId)) {
      throw Exception('Only admin communication is allowed');
    }

    // Socket connectivity checks
    if (_socket == null || !_socket!.connected) {
      try {
        await connect();

        //print("Sockets connected");
      } catch (reconnectError) {
        //print("FAiled to connect to socket");
        throw Exception('Socket not connected and reconnection failed');
      }

      // Re-check after reconnection
      if (_socket == null || !_socket!.connected) {
        //debugPrint('❌ Socket still not connected after reconnection attempt');
        throw Exception('Socket not connected');
      }
    }

    // User ID validation
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      //debugPrint('❌ USER ID VALIDATION FAILED:');
      //debugPrint('   - Current user ID: $_currentUserId');
      //debugPrint('   - User ID is null: ${_currentUserId == null}');
      //debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty}');

      // Try to get user ID again
      //debugPrint('🔄 Attempting to retrieve user ID...');
      _currentUserId = await AuthService.getUserId();

      //debugPrint('🔍 Retrieved user ID: $_currentUserId');

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        //debugPrint('❌ Still no valid user ID after retrieval attempt');
        await AuthService.debugStoredData();
        throw Exception('No current user ID available');
      }
    }

    //debugPrint('✅ All validations passed - proceeding with message send');

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageData = {
        'fromUserId': _currentUserId,
        'toUserId': toUserId,
        'text': text,
        'timestamp': timestamp,
        "type": isMedia != null ? "media" : "text",
      };

      //debugPrint('� Message Data Package:');
      //debugPrint('   - fromUserId: $_currentUserId');
      //debugPrint('   - toUserId: $toUserId');
      //debugPrint('   - text: "$text"');
      //debugPrint('   - timestamp: $timestamp');
      //debugPrint('   - timestamp as DateTime: ${DateTime.fromMillisecondsSinceEpoch(timestamp)}');
      //debugPrint('   - full messageData: $messageData');

      //debugPrint('📡 Emitting "sendMessage" event to socket...');
      final emitStartTime = DateTime.now();

      _socket!.emit('sendMessage', messageData);

      final emitEndTime = DateTime.now();
      final emitDuration = emitEndTime.difference(emitStartTime);

      //debugPrint('✅ Message event emitted successfully');
      //debugPrint('   - Emit duration: ${emitDuration.inMilliseconds}ms');
      //debugPrint('   - Event: "sendMessage"');
      //debugPrint('   - Socket ID used: ${_socket!.id}');

      // Create a local message for immediate UI update
      final localMessage = ChatMessage(
        id: timestamp.toString(),
        fromUserId: _currentUserId!,
        toUserId: toUserId,
        text: text,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        isRead: false,
      );

      //debugPrint('📝 Creating local message for immediate UI update:');
      //debugPrint('   - Local message ID: ${localMessage.id}');
      //debugPrint('   - Local message from: ${localMessage.fromUserId}');
      //debugPrint('   - Local message to: ${localMessage.toUserId}');
      //debugPrint('   - Local message text: "${localMessage.text}"');
      //debugPrint('   - Local message timestamp: ${localMessage.timestamp}');
      //debugPrint('   - Local message read status: ${localMessage.isRead}');

      _messageStreamController.add(localMessage);

      //debugPrint('✅ Local message added to stream for immediate UI update');
      //debugPrint('   - Stream controller has listeners: ${_messageStreamController.hasListener}');
      //debugPrint('   - Stream controller is closed: ${_messageStreamController.isClosed}');
    } catch (e, stackTrace) {
      //debugPrint('');
      //debugPrint('❌ === MESSAGE SEND ERROR ===');
      //debugPrint('   - Error: $e');
      //debugPrint('   - Error type: ${e.runtimeType}');
      //debugPrint('   - Stack trace: $stackTrace');

      // Analyze specific error types
      if (e.toString().contains('socket')) {
        //debugPrint('🔍 Socket-related error detected');
        //debugPrint('   - Socket state: ${_socket?.connected}');
        //debugPrint('   - Socket ID: ${_socket?.id}');
      } else if (e.toString().contains('emit')) {
        //debugPrint('🔍 Event emission error detected');
        //debugPrint('   - Check socket event handlers on server');
      }

      throw Exception('Failed to send message: $e');
    } finally {
      //debugPrint('🏁 === SEND MESSAGE END ===');
      //debugPrint('');
    }
  }

  // Disconnect from socket
  static void disconnect() {
    if (_socket != null) {
      //print('🔌 Disconnecting socket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _connectionStreamController.add(false);
  }

  // Get current user ID
  static String? getCurrentUserId() => _currentUserId;

  // Fetch available admins from the API
  static Future<List<dynamic>> fetchAvailableAdmins() async {
    final stopwatch = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role");
    final userId = prefs.getString("user_id");

    try {
      //debugPrint('📤 Making GET request to /chat/adminList...with role $role');
      final response = (role == "ADMIN") ? await ApiClient.get('/chat/userList/$userId') : await ApiClient.get('/chat/adminList');

      stopwatch.stop();

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final adminData = responseData['data'] as List;
          final unreadData = responseData['unread'] != null ? responseData['unread'] as List : [];

          final admins = <Admin>[];
          final unread = <UnreadChat>[];

          for (int i = 0; i < unreadData.length; i++) {
            unread.add(UnreadChat.fromJson(unreadData[i]));
          }

          for (int i = 0; i < adminData.length; i++) {
            final adminJson = adminData[i];
            try {
              final admin = Admin.fromJson(adminJson);
              admins.add(admin);
            } catch (adminError) {
              //debugPrint('   ❌ Error parsing admin #${i + 1}: $adminError');
            }
          }
          // Update cached admins
          _availableAdmins = admins;
          _adminsStreamController.add(admins);

          return [admins, unread];
        } else {
          //debugPrint('❌ API response validation failed');
          return [];
        }
      } else {
        //debugPrint('❌ HTTP Error - API request failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      //print("Error = ${e}");
      //print("Location = ${stackTrace}");
      stopwatch.stop();
      return [];
    } finally {
      //debugPrint('🏁 === FETCH ADMIN LIST API CALL END ===');
    }
  }

  // Get admin conversations for chat - returns all available admins
  static Future<List<ChatConversation>> getAdminConversations({String? propertyTitle}) async {
    final admins = await fetchAvailableAdmins();

    if (admins.isEmpty) {
      //debugPrint('⚠️ No admins available, returning empty list');
      return [];
    }

    return admins
        .map((admin) => ChatConversation(
              id: 'chat_admin_${admin.id}',
              landlordId: admin.id,
              landlordName: admin.name.isNotEmpty ? admin.name : 'Pearl Nest Support',
              landlordProfilePic: admin.profilePicture ?? '',
              lastMessage: 'Start your conversation with ${admin.name}',
              lastMessageTime: DateTime.now(),
              unreadCount: 0,
              isOnline: admin.isOnline,
              propertyTitle: propertyTitle != null ? 'Support Chat - $propertyTitle' : 'Support Chat',
            ))
        .toList();
  }

  // Check if a user ID is an admin user ID
  static bool isAdminUser(String userId) {
    return _availableAdmins.any((admin) => admin.id == userId);
  }

  // Get the first available admin user ID (for backward compatibility)
  static String? getFirstAdminUserId() {
    if (_availableAdmins.isNotEmpty) {
      return _availableAdmins.first.id;
    }
    return null;
  }

  // Get admin conversation for chat (backward compatibility - returns first available admin)
  static Future<ChatConversation?> getAdminConversation({String? propertyTitle}) async {
    final admins = await fetchAvailableAdmins();
    if (admins.isEmpty) {
      //debugPrint('⚠️ No admins available for conversation');
      return null;
    }

    final firstAdmin = admins.first;
    return ChatConversation(
      id: 'chat_admin_${firstAdmin.id}',
      landlordId: firstAdmin.id,
      landlordName: firstAdmin.name.isNotEmpty ? firstAdmin.name : 'PearlNest Support',
      landlordProfilePic: firstAdmin.profilePicture ?? '',
      lastMessage: 'Start your conversation with our support team',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
      isOnline: firstAdmin.isOnline,
      propertyTitle: propertyTitle != null ? 'Support Chat - $propertyTitle' : 'Support Chat',
    );
  }

  // Get or create a conversation with a specific admin
  static Future<ChatConversation?> getOrCreateConversation({
    required String adminId,
    required String adminName,
    String? propertyTitle,
  }) async {
    try {
      // Create a conversation object with the admin
      final conversation = ChatConversation(
        id: 'admin_$adminId',
        landlordId: adminId,
        landlordName: adminName,
        landlordProfilePic: '', // Will use default avatar
        lastMessage: propertyTitle != null ? 'Chat about: $propertyTitle' : 'Chat with $adminName',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isOnline: true, // Assume admin is online
        propertyTitle: propertyTitle ?? 'General Support',
      );

      //debugPrint('✅ Created conversation with admin: ${conversation.landlordName}');
      return conversation;
    } catch (e) {
      //debugPrint('❌ Error creating conversation with admin: $e');
      return null;
    }
  }

  // Get the admin user ID (deprecated - use getFirstAdminUserId instead)
  static String? getAdminUserId() {
    return getFirstAdminUserId();
  }

  // Dispose resources
  static void dispose() {
    disconnect();
    _messageStreamController.close();
    _connectionStreamController.close();
    _adminsStreamController.close();
  }

  // Reconnect if needed
  static Future<void> ensureConnected() async {
    if (_socket == null || !_socket!.connected) {
      await connect();
    }
  }

  // Fetch chat conversations from API with comprehensive debugging
  static Future<List<ChatConversation>> fetchChatList() async {
    final stopwatch = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.get("role");
    //print("ChatList running");

    try {
      //debugPrint('📤 Making GET request to /chat/chatList... with role $role');
      final response = (role == "ADMIN") ? await ApiClient.get('/chat/userList') : await ApiClient.get('/chat/adminList');

      if (response.statusCode == 200) {
        //debugPrint('✅ HTTP 200 - Success response received');

        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final chatData = responseData['data'] as List;

          // Process each chat entry with detailed debugging
          final conversations = <ChatConversation>[];
          for (int i = 0; i < chatData.length; i++) {
            final chat = chatData[i];

            try {
              final fromUser = chat['fromUser'] ?? {};
              final toUser = chat['toUser'] ?? {};
              final currentUserId = _currentUserId;

              //debugPrint('   - fromUser: $fromUser');
              //debugPrint('   - toUser: $toUser');
              //debugPrint('   - fromUserId: ${chat['fromUserId']}');
              //debugPrint('   - toUserId: ${chat['toUserId']}');
              //debugPrint('   - message: ${chat['message']}');
              //debugPrint('   - currentUserId: $currentUserId');

              // Determine if current user is sender or receiver
              final isCurrentUserSender = chat['fromUserId'] == currentUserId;
              final otherUser = isCurrentUserSender ? toUser : fromUser;
              final otherUserId = isCurrentUserSender ? chat['toUserId'] : chat['fromUserId'];

              //debugPrint('   - isCurrentUserSender: $isCurrentUserSender');
              //debugPrint('   - otherUser: $otherUser');
              //debugPrint('   - otherUserId: $otherUserId');
              //debugPrint('   - otherUser name: ${otherUser['name']}');
              //debugPrint('   - otherUser role: ${otherUser['role']}');
              //debugPrint('   - otherUser profilePicture: ${otherUser['profilePicture']}');

              final conversation = ChatConversation(
                id: 'chat_$otherUserId',
                landlordId: otherUserId?.toString() ?? '',
                landlordName: otherUser['name']?.toString() ?? 'Unknown User',
                landlordProfilePic: otherUser['profilePicture']?.toString() ?? '',
                lastMessage: chat['message']?.toString() ?? '',
                lastMessageTime: DateTime.now(), // TODO: Parse actual timestamp if available
                unreadCount: 0, // TODO: Get from API when available
                isOnline: otherUser['role'] == 'ADMIN', // Assume admin is always online
                propertyTitle: otherUser['role'] == 'ADMIN' ? 'Support Chat' : 'Property Discussion',
              );

              conversations.add(conversation);

              //debugPrint('   ✅ Successfully created conversation for ${conversation.landlordName}');
            } catch (chatError) {
              //debugPrint('   ❌ Error processing chat entry #${i + 1}: $chatError');
              //debugPrint('   🔍 Chat processing error type: ${chatError.runtimeType}');
              //debugPrint('   🔍 Stack trace: ${StackTrace.current}');
            }
          }

          //debugPrint('');
          //debugPrint('✅ === CHAT LIST PROCESSING COMPLETE ===');
          //debugPrint('   - Total conversations created: ${conversations.length}');
          //debugPrint('   - Conversation details:');
          for (int i = 0; i < conversations.length; i++) {
            final conv = conversations[i];

            //debugPrint('     ${i + 1}. ${conv.landlordName} (ID: ${conv.landlordId})');
            //debugPrint('        Last message: "${conv.lastMessage}"');
            //debugPrint('        Property: ${conv.propertyTitle}');
            //debugPrint('        Online: ${conv.isOnline}');
          }

          return conversations;
        } else {
          //debugPrint('❌ API response validation failed:');
          //debugPrint('   - Success value: ${responseData['success']} (expected: true)');
          //debugPrint('   - Data value: ${responseData['data']} (expected: non-null)');
          //debugPrint('   - Full response: $responseData');
        }
      } else {
        //debugPrint('❌ HTTP Error - API request failed:');
        //debugPrint('   - Status Code: ${response.statusCode}');
        //debugPrint('   - Status Message: ${response.statusMessage}');
        //debugPrint('   - Response Data: ${response.data}');
        //debugPrint('   - Response Headers: ${response.headers}');
      }

      //debugPrint('❌ Failed to fetch chat list: Invalid or unsuccessful response');
      return [];
    } catch (e, stackTrace) {
      stopwatch.stop();

      //debugPrint('');
      //debugPrint('❌ === FETCH CHAT LIST API ERROR ===');
      //debugPrint('   - Error occurred after: ${stopwatch.elapsedMilliseconds}ms');
      //debugPrint('   - Error: $e');
      //debugPrint('   - Error type: ${e.runtimeType}');
      //debugPrint('   - Stack trace: $stackTrace');

      // Additional error analysis
      if (e.toString().contains('connection')) {
        //debugPrint('🔍 Network connectivity issue detected');
        //debugPrint('   - Check internet connection');
        //debugPrint('   - Verify server is running');
        //debugPrint('   - Check if base URL is correct: ${AppConfig.getCurrentBaseUrl()}');
      } else if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        //debugPrint('🔍 Authentication issue detected');
        //debugPrint('   - Auth token may be invalid or expired');
        //debugPrint('   - Current token: ${ApiClient.currentAuthToken}');
      } else if (e.toString().contains('404')) {
        //debugPrint('🔍 Endpoint not found');
        //debugPrint('   - Verify /chat/chatList endpoint exists on server');
      }

      return [];
    } finally {
      //debugPrint('🏁 === FETCH CHAT LIST API CALL END ===');
      //debugPrint('');
    }
  }
}
