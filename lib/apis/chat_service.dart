import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../models/chat_message.dart';
import 'app_config.dart';

class ChatService {
  static socket_io.Socket? _socket;
  static String? _currentUserId;
  static bool _isConnected = false;
  
  // Stream controllers for real-time updates
  static final _messageStreamController = StreamController<ChatMessage>.broadcast();
  static final _connectionStreamController = StreamController<bool>.broadcast();
  
  // Getters for streams
  static Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  static Stream<bool> get connectionStream => _connectionStreamController.stream;
  
  // Get connection status
  static bool get isConnected => _isConnected;
  
  // Initialize and connect to socket
  static Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('🔌 Socket already connected');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      debugPrint('🔍 Socket Debug - Token exists: ${token != null}');
      debugPrint('🔍 Socket Debug - User data exists: ${userData != null}');
      
      if (token == null || userData == null) {
        debugPrint('❌ Cannot connect to socket: No auth token or user data');
        debugPrint('🔍 Token: ${token?.substring(0, 10)}...');
        debugPrint('🔍 User Data: $userData');
        return;
      }
      
      final user = jsonDecode(userData);
      _currentUserId = user['id']?.toString();
      
      debugPrint('🔍 Socket Debug - Parsed user data: $user');
      debugPrint('🔍 Socket Debug - Current user ID: $_currentUserId');
      
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        debugPrint('❌ Cannot connect to socket: No user ID found in user data');
        debugPrint('🔍 Available user keys: ${user.keys.toList()}');
        return;
      }
      
      final socketUrl = AppConfig.getCurrentBaseUrl();
      debugPrint('🔌 Connecting to socket at: $socketUrl');
      debugPrint('🔍 Socket Debug - User ID to register: $_currentUserId');
      
      _socket = socket_io.io(socketUrl, 
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
          .build()
      );
      
      _setupEventListeners();
      
      // Connect to socket
      _socket!.connect();
      
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      _isConnected = false;
      _connectionStreamController.add(false);
    }
  }
  
  // Setup event listeners
  static void _setupEventListeners() {
    if (_socket == null) return;
    
    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected successfully');
      debugPrint('🔍 Socket ID: ${_socket!.id}');
      _isConnected = true;
      _connectionStreamController.add(true);
      
      // Register user with their ID
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        debugPrint('📤 Emitting register event with User ID: $_currentUserId');
        _socket!.emit('register', _currentUserId);
        debugPrint('📝 Successfully registered user with ID: $_currentUserId');
      } else {
        debugPrint('❌ Cannot register - User ID is null or empty: $_currentUserId');
      }
    });
    
    _socket!.onDisconnect((reason) {
      debugPrint('❌ Socket disconnected - Reason: $reason');
      _isConnected = false;
      _connectionStreamController.add(false);
    });
    
    _socket!.onConnectError((error) {
      debugPrint('❌ Socket connection error: $error');
      debugPrint('🔍 Error type: ${error.runtimeType}');
      _isConnected = false;
      _connectionStreamController.add(false);
    });
    
    _socket!.onError((error) {
      debugPrint('❌ Socket general error: $error');
      debugPrint('🔍 Error type: ${error.runtimeType}');
    });
    
    // Listen for incoming messages
    _socket!.on('sendMessage', (data) {
      debugPrint('📨 Received sendMessage event');
      debugPrint('🔍 Raw message data: $data');
      debugPrint('🔍 Data type: ${data.runtimeType}');
      
      try {
        final message = ChatMessage.fromJson(data);
        debugPrint('📩 Parsed message:');
        debugPrint('  - From: ${message.fromUserId}');
        debugPrint('  - To: ${message.toUserId}');
        debugPrint('  - Text: ${message.text}');
        debugPrint('  - Timestamp: ${message.timestamp}');
        
        _messageStreamController.add(message);
        debugPrint('✅ Message added to stream');
      } catch (e) {
        debugPrint('❌ Error parsing received message: $e');
        debugPrint('🔍 Stack trace: ${StackTrace.current}');
      }
    });
    
    // Listen for register acknowledgment
    _socket!.on('registered', (data) {
      debugPrint('📝 Received registration acknowledgment: $data');
    });
    
    // Listen for any other events
    _socket!.onAny((event, data) {
      debugPrint('🔍 Socket event received: $event');
      debugPrint('🔍 Event data: $data');
    });
    
    _socket!.onReconnect((attempt) {
      debugPrint('🔄 Socket reconnected after $attempt attempts');
      debugPrint('🔍 New Socket ID: ${_socket!.id}');
      _isConnected = true;
      _connectionStreamController.add(true);
      
      // Re-register user
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        debugPrint('📤 Re-emitting register event with User ID: $_currentUserId');
        _socket!.emit('register', _currentUserId);
        debugPrint('📝 Successfully re-registered user with ID: $_currentUserId');
      } else {
        debugPrint('❌ Cannot re-register - User ID is null or empty: $_currentUserId');
      }
    });
  }
  
  // Send a message
  static Future<void> sendMessage({
    required String toUserId,
    required String text,
  }) async {
    debugPrint('📤 Attempting to send message');
    debugPrint('🔍 From User ID: $_currentUserId');
    debugPrint('🔍 To User ID: $toUserId');
    debugPrint('🔍 Message Text: $text');
    debugPrint('🔍 Socket connected: ${_socket?.connected}');
    
    if (_socket == null || !_socket!.connected) {
      debugPrint('❌ Cannot send message: Socket not connected');
      debugPrint('🔍 Socket is null: ${_socket == null}');
      debugPrint('🔍 Socket connected: ${_socket?.connected}');
      throw Exception('Socket not connected');
    }
    
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      debugPrint('❌ Cannot send message: No current user ID');
      debugPrint('🔍 Current user ID: $_currentUserId');
      throw Exception('No current user ID');
    }
    
    try {
      final messageData = {
        'fromUserId': _currentUserId,
        'toUserId': toUserId,
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      debugPrint('📤 Emitting sendMessage event with data:');
      debugPrint('  - fromUserId: $_currentUserId');
      debugPrint('  - toUserId: $toUserId');
      debugPrint('  - text: $text');
      debugPrint('  - timestamp: ${messageData['timestamp']}');
      
      _socket!.emit('sendMessage', messageData);
      debugPrint('✅ Message event emitted successfully');
      
      // Create a local message for immediate UI update
      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromUserId: _currentUserId!,
        toUserId: toUserId,
        text: text,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      debugPrint('📝 Adding local message to stream for immediate UI update');
      _messageStreamController.add(localMessage);
      debugPrint('✅ Local message added to stream');
      
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      debugPrint('🔍 Stack trace: ${StackTrace.current}');
      throw Exception('Failed to send message: $e');
    }
  }
  
  // Disconnect from socket
  static void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 Disconnecting socket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _isConnected = false;
    _connectionStreamController.add(false);
  }
  
  // Get current user ID
  static String? getCurrentUserId() => _currentUserId;
  
  // Dispose resources
  static void dispose() {
    disconnect();
    _messageStreamController.close();
    _connectionStreamController.close();
  }
  
  // Reconnect if needed
  static Future<void> ensureConnected() async {
    if (_socket == null || !_socket!.connected) {
      await connect();
    }
  }
  
  // Debug method to check connection status
  static void debugConnectionStatus() {
    debugPrint('🔍 === CHAT SERVICE DEBUG INFO ===');
    debugPrint('🔍 Socket exists: ${_socket != null}');
    debugPrint('🔍 Socket connected: ${_socket?.connected}');
    debugPrint('🔍 Socket ID: ${_socket?.id}');
    debugPrint('🔍 Is connected flag: $_isConnected');
    debugPrint('🔍 Current user ID: $_currentUserId');
    debugPrint('🔍 Current user ID empty: ${_currentUserId?.isEmpty}');
    debugPrint('🔍 Message stream has listeners: ${_messageStreamController.hasListener}');
    debugPrint('🔍 Connection stream has listeners: ${_connectionStreamController.hasListener}');
    debugPrint('🔍 === END DEBUG INFO ===');
  }
}
