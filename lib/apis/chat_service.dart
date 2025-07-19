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
    debugPrint('');
    debugPrint('🚀 === SOCKET CONNECTION START ===');
    
    if (_socket != null && _socket!.connected) {
      debugPrint('✅ Socket already connected - skipping connection');
      debugPrint('   - Socket ID: ${_socket!.id}');
      debugPrint('   - Connection state: CONNECTED');
      return;
    }
    
    debugPrint('🔌 Initiating new socket connection...');
    
    try {
      debugPrint('🔍 Pre-connection checks:');
      
      // Get preferences and token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      debugPrint('   - SharedPreferences loaded successfully');
      debugPrint('   - Auth token exists: ${token != null}');
      debugPrint('   - Auth token length: ${token?.length ?? 0}');
      if (token != null) {
        debugPrint('   - Auth token preview: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      }
      
      // Get user ID using AuthService
      _currentUserId = await AuthService.getUserId();
      
      debugPrint('   - User ID retrieved: $_currentUserId');
      debugPrint('   - User ID is null: ${_currentUserId == null}');
      debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty ?? true}');
      
      if (token == null) {
        debugPrint('❌ CANNOT CONNECT: No auth token available');
        debugPrint('   - User needs to login first');
        debugPrint('   - Check authentication flow');
        return;
      }
      
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        debugPrint('❌ CANNOT CONNECT: No user ID found');
        debugPrint('� Attempting to diagnose and fix user ID issue...');
        await AuthService.debugStoredData();
        
        debugPrint('� Attempting to fix missing user ID...');
        final fixed = await AuthService.fixMissingUserId();
        if (fixed) {
          _currentUserId = await AuthService.getUserId();
          debugPrint('✅ User ID fixed and retrieved: $_currentUserId');
        } else {
          debugPrint('❌ Failed to fix user ID - cannot connect to chat');
          debugPrint('   - User may need to re-login');
          debugPrint('   - Check AuthService.fixMissingUserId() implementation');
          return;
        }
      }
      
      // Socket configuration
      final socketUrl = AppConfig.getCurrentBaseUrl();
      debugPrint('� Socket configuration:');
      debugPrint('   - Socket URL: $socketUrl');
      debugPrint('   - Transport: websocket');
      debugPrint('   - Auto connect: enabled');
      debugPrint('   - Reconnection: enabled');
      debugPrint('   - Reconnection delay: 1000ms');
      debugPrint('   - Reconnection delay max: 5000ms');
      debugPrint('   - Auth data: {token: [HIDDEN], userId: $_currentUserId}');
      
      // Create socket instance
      debugPrint('🔧 Creating socket instance...');
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
      
      debugPrint('✅ Socket instance created successfully');
      debugPrint('   - Socket object: ${_socket != null ? 'Created' : 'NULL'}');
      
      // Setup event listeners before connecting
      debugPrint('🔧 Setting up event listeners...');
      _setupEventListeners();
      debugPrint('✅ Event listeners configured');
      
      // Connect to socket
      debugPrint('📡 Initiating socket connection...');
      final connectionStartTime = DateTime.now();
      
      _socket!.connect();
      
      debugPrint('✅ Socket.connect() called');
      debugPrint('   - Connection start time: $connectionStartTime');
      debugPrint('   - Waiting for connection events...');
      
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ === SOCKET CONNECTION ERROR ===');
      debugPrint('   - Error: $e');
      debugPrint('   - Error type: ${e.runtimeType}');
      debugPrint('   - Stack trace: $stackTrace');
      
      _isConnected = false;
      _connectionStreamController.add(false);
      
      // Specific error analysis
      if (e.toString().contains('network')) {
        debugPrint('🔍 Network-related error detected');
        debugPrint('   - Check internet connectivity');
        debugPrint('   - Verify server is accessible');
      } else if (e.toString().contains('auth')) {
        debugPrint('🔍 Authentication-related error detected');
        debugPrint('   - Check token validity');
        debugPrint('   - Verify user credentials');
      }
      
    } finally {
      debugPrint('🏁 === SOCKET CONNECTION PROCESS END ===');
      debugPrint('');
    }
  }
  
  // Setup event listeners with comprehensive debugging
  static void _setupEventListeners() {
    if (_socket == null) {
      debugPrint('❌ Cannot setup event listeners - socket is null');
      return;
    }
    
    debugPrint('🔧 Setting up socket event listeners...');
    
    _socket!.onConnect((_) {
      final connectTime = DateTime.now();
      debugPrint('');
      debugPrint('✅ === SOCKET CONNECTED SUCCESSFULLY ===');
      debugPrint('   - Connection time: $connectTime');
      debugPrint('   - Socket ID: ${_socket!.id}');
      debugPrint('   - Socket transport: ${_socket!.io.engine?.transport?.name ?? 'unknown'}');
      debugPrint('   - Connection state updated to: CONNECTED');
      
      _isConnected = true;
      _connectionStreamController.add(true);
      debugPrint('   - Connection stream updated: true');
      
      // Register user with their ID
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        debugPrint('📤 Registering user with socket...');
        debugPrint('   - User ID to register: $_currentUserId');
        debugPrint('   - Emitting "register" event...');
        
        _socket!.emit('register', _currentUserId);
        
        debugPrint('✅ User registration event emitted');
        debugPrint('   - Event: "register"');
        debugPrint('   - Data: $_currentUserId');
        debugPrint('   - Socket ID used: ${_socket!.id}');
      } else {
        debugPrint('❌ CANNOT REGISTER USER:');
        debugPrint('   - User ID is null: ${_currentUserId == null}');
        debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty ?? true}');
        debugPrint('   - Current user ID value: $_currentUserId');
      }
      
      debugPrint('🏁 Socket connection setup complete');
    });
    
    _socket!.onDisconnect((reason) {
      final disconnectTime = DateTime.now();
      debugPrint('');
      debugPrint('❌ === SOCKET DISCONNECTED ===');
      debugPrint('   - Disconnect time: $disconnectTime');
      debugPrint('   - Disconnect reason: $reason');
      debugPrint('   - Previous socket ID: ${_socket?.id}');
      debugPrint('   - Connection state updated to: DISCONNECTED');
      
      _isConnected = false;
      _connectionStreamController.add(false);
      debugPrint('   - Connection stream updated: false');
      
      // Analyze disconnect reason
      if (reason.toString().contains('transport close')) {
        debugPrint('🔍 Transport closed - likely network issue');
      } else if (reason.toString().contains('ping timeout')) {
        debugPrint('🔍 Ping timeout - connection lost');
      } else if (reason.toString().contains('client namespace disconnect')) {
        debugPrint('🔍 Client initiated disconnect');
      } else {
        debugPrint('🔍 Other disconnect reason: $reason');
      }
    });
    
    _socket!.onConnectError((error) {
      debugPrint('');
      debugPrint('❌ === SOCKET CONNECTION ERROR ===');
      debugPrint('   - Error: $error');
      debugPrint('   - Error type: ${error.runtimeType}');
      debugPrint('   - Connection attempt failed');
      
      _isConnected = false;
      _connectionStreamController.add(false);
      debugPrint('   - Connection stream updated: false');
      
      // Analyze connection error
      if (error.toString().contains('timeout')) {
        debugPrint('🔍 Connection timeout - server may be unreachable');
      } else if (error.toString().contains('refused')) {
        debugPrint('🔍 Connection refused - server may be down');
      } else if (error.toString().contains('unauthorized')) {
        debugPrint('🔍 Unauthorized - check authentication');
      }
    });
    
    _socket!.onError((error) {
      debugPrint('');
      debugPrint('❌ === SOCKET GENERAL ERROR ===');
      debugPrint('   - Error: $error');
      debugPrint('   - Error type: ${error.runtimeType}');
      debugPrint('   - Error timestamp: ${DateTime.now()}');
    });
    
    // Listen for incoming messages with detailed debugging
    _socket!.on('sendMessage', (data) {
      final receiveTime = DateTime.now();
      debugPrint('');
      debugPrint('📨 === INCOMING MESSAGE EVENT ===');
      debugPrint('   - Receive time: $receiveTime');
      debugPrint('   - Raw data: $data');
      debugPrint('   - Data type: ${data.runtimeType}');
      debugPrint('   - Data is Map: ${data is Map}');
      debugPrint('   - Data is null: ${data == null}');
      
      try {
        debugPrint('🔍 Parsing message data...');
        final message = ChatMessage.fromJson(data);
        
        debugPrint('✅ Message parsed successfully:');
        debugPrint('   - Message ID: ${message.id}');
        debugPrint('   - From User ID: ${message.fromUserId}');
        debugPrint('   - To User ID: ${message.toUserId}');
        debugPrint('   - Message Text: "${message.text}"');
        debugPrint('   - Timestamp: ${message.timestamp}');
        debugPrint('   - Is Read: ${message.isRead}');
        debugPrint('   - Is from current user: ${message.fromUserId == _currentUserId}');
        debugPrint('   - Is to current user: ${message.toUserId == _currentUserId}');
        
        // Add to message stream
        debugPrint('📡 Adding message to stream...');
        _messageStreamController.add(message);
        
        debugPrint('✅ Message added to stream successfully');
        debugPrint('   - Stream has listeners: ${_messageStreamController.hasListener}');
        debugPrint('   - Stream is closed: ${_messageStreamController.isClosed}');
        
      } catch (e, stackTrace) {
        debugPrint('❌ === MESSAGE PARSING ERROR ===');
        debugPrint('   - Error: $e');
        debugPrint('   - Error type: ${e.runtimeType}');
        debugPrint('   - Stack trace: $stackTrace');
        debugPrint('   - Raw data that failed: $data');
      }
    });
    
    // Listen for register acknowledgment
    _socket!.on('registered', (data) {
      debugPrint('');
      debugPrint('📝 === REGISTRATION ACKNOWLEDGMENT ===');
      debugPrint('   - Acknowledgment time: ${DateTime.now()}');
      debugPrint('   - Response data: $data');
      debugPrint('   - Data type: ${data.runtimeType}');
      debugPrint('   - User successfully registered with server');
    });
    
    // Listen for reconnection events
    _socket!.onReconnect((attempt) {
      final reconnectTime = DateTime.now();
      debugPrint('');
      debugPrint('🔄 === SOCKET RECONNECTED ===');
      debugPrint('   - Reconnect time: $reconnectTime');
      debugPrint('   - Reconnection attempt #: $attempt');
      debugPrint('   - New Socket ID: ${_socket!.id}');
      debugPrint('   - Connection state updated to: CONNECTED');
      
      _isConnected = true;
      _connectionStreamController.add(true);
      debugPrint('   - Connection stream updated: true');
      
      // Re-register user after reconnection
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        debugPrint('📤 Re-registering user after reconnection...');
        debugPrint('   - User ID to re-register: $_currentUserId');
        
        _socket!.emit('register', _currentUserId);
        
        debugPrint('✅ User re-registration event emitted');
        debugPrint('   - Event: "register"');
        debugPrint('   - Data: $_currentUserId');
      } else {
        debugPrint('❌ CANNOT RE-REGISTER USER:');
        debugPrint('   - User ID is null: ${_currentUserId == null}');
        debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty ?? true}');
        debugPrint('   - Current user ID value: $_currentUserId');
      }
    });
    
    // Listen for any other events (catch-all for debugging)
    _socket!.onAny((event, data) {
      if (event != 'sendMessage' && event != 'registered') { // Don't duplicate already logged events
        debugPrint('');
        debugPrint('🔍 === UNKNOWN SOCKET EVENT ===');
        debugPrint('   - Event name: $event');
        debugPrint('   - Event data: $data');
        debugPrint('   - Event timestamp: ${DateTime.now()}');
        debugPrint('   - Data type: ${data.runtimeType}');
      }
    });
    
    debugPrint('✅ All socket event listeners configured');
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
  }) async {
    debugPrint('');
    debugPrint('🚀 === SEND MESSAGE START ===');
    
    // Validate that message is only sent to admin users
    if (!isAdminUser(toUserId)) {
      debugPrint('❌ MESSAGE VALIDATION FAILED:');
      debugPrint('   - Attempted recipient: $toUserId');
      debugPrint('   - Available admin IDs: ${_availableAdmins.map((a) => a.id).join(', ')}');
      debugPrint('   - Only admin communication is allowed');
      throw Exception('Only admin communication is allowed');
    }
    
    debugPrint('✅ Message validation passed - sending to admin');
    debugPrint('📤 Message Send Debug Info:');
    debugPrint('   - From User ID: $_currentUserId');
    debugPrint('   - To User ID: $toUserId');
    debugPrint('   - Message Text: "$text"');
    debugPrint('   - Message Length: ${text.length} characters');
    debugPrint('   - Socket exists: ${_socket != null}');
    debugPrint('   - Socket connected: ${_socket?.connected}');
    debugPrint('   - Socket ID: ${_socket?.id}');
    debugPrint('   - Connection status flag: $_isConnected');
    
    // Socket connectivity checks
    if (_socket == null || !_socket!.connected) {
      debugPrint('❌ SOCKET CONNECTION FAILED:');
      debugPrint('   - Socket is null: ${_socket == null}');
      debugPrint('   - Socket connected: ${_socket?.connected}');
      debugPrint('   - Connection status flag: $_isConnected');
      debugPrint('   - Socket state: ${_socket?.connected == true ? 'CONNECTED' : 'DISCONNECTED'}');
      
      // Try to reconnect
      debugPrint('� Attempting to reconnect socket...');
      try {
        await connect();
        debugPrint('✅ Socket reconnection successful');
      } catch (reconnectError) {
        debugPrint('❌ Socket reconnection failed: $reconnectError');
        throw Exception('Socket not connected and reconnection failed');
      }
      
      // Re-check after reconnection
      if (_socket == null || !_socket!.connected) {
        debugPrint('❌ Socket still not connected after reconnection attempt');
        throw Exception('Socket not connected');
      }
    }
    
    // User ID validation
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      debugPrint('❌ USER ID VALIDATION FAILED:');
      debugPrint('   - Current user ID: $_currentUserId');
      debugPrint('   - User ID is null: ${_currentUserId == null}');
      debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty}');
      
      // Try to get user ID again
      debugPrint('🔄 Attempting to retrieve user ID...');
      _currentUserId = await AuthService.getUserId();
      debugPrint('🔍 Retrieved user ID: $_currentUserId');
      
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        debugPrint('❌ Still no valid user ID after retrieval attempt');
        await AuthService.debugStoredData();
        throw Exception('No current user ID available');
      }
    }
    
    debugPrint('✅ All validations passed - proceeding with message send');
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageData = {
        'fromUserId': _currentUserId,
        'toUserId': toUserId,
        'text': text,
        'timestamp': timestamp,
      };
      
      debugPrint('� Message Data Package:');
      debugPrint('   - fromUserId: $_currentUserId');
      debugPrint('   - toUserId: $toUserId');
      debugPrint('   - text: "$text"');
      debugPrint('   - timestamp: $timestamp');
      debugPrint('   - timestamp as DateTime: ${DateTime.fromMillisecondsSinceEpoch(timestamp)}');
      debugPrint('   - full messageData: $messageData');
      
      debugPrint('📡 Emitting "sendMessage" event to socket...');
      final emitStartTime = DateTime.now();
      
      _socket!.emit('sendMessage', messageData);
      
      final emitEndTime = DateTime.now();
      final emitDuration = emitEndTime.difference(emitStartTime);
      
      debugPrint('✅ Message event emitted successfully');
      debugPrint('   - Emit duration: ${emitDuration.inMilliseconds}ms');
      debugPrint('   - Event: "sendMessage"');
      debugPrint('   - Socket ID used: ${_socket!.id}');
      
      // Create a local message for immediate UI update
      final localMessage = ChatMessage(
        id: timestamp.toString(),
        fromUserId: _currentUserId!,
        toUserId: toUserId,
        text: text,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        isRead: false,
      );
      
      debugPrint('📝 Creating local message for immediate UI update:');
      debugPrint('   - Local message ID: ${localMessage.id}');
      debugPrint('   - Local message from: ${localMessage.fromUserId}');
      debugPrint('   - Local message to: ${localMessage.toUserId}');
      debugPrint('   - Local message text: "${localMessage.text}"');
      debugPrint('   - Local message timestamp: ${localMessage.timestamp}');
      debugPrint('   - Local message read status: ${localMessage.isRead}');
      
      _messageStreamController.add(localMessage);
      debugPrint('✅ Local message added to stream for immediate UI update');
      debugPrint('   - Stream controller has listeners: ${_messageStreamController.hasListener}');
      debugPrint('   - Stream controller is closed: ${_messageStreamController.isClosed}');
      
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ === MESSAGE SEND ERROR ===');
      debugPrint('   - Error: $e');
      debugPrint('   - Error type: ${e.runtimeType}');
      debugPrint('   - Stack trace: $stackTrace');
      
      // Analyze specific error types
      if (e.toString().contains('socket')) {
        debugPrint('🔍 Socket-related error detected');
        debugPrint('   - Socket state: ${_socket?.connected}');
        debugPrint('   - Socket ID: ${_socket?.id}');
      } else if (e.toString().contains('emit')) {
        debugPrint('🔍 Event emission error detected');
        debugPrint('   - Check socket event handlers on server');
      }
      
      throw Exception('Failed to send message: $e');
    } finally {
      debugPrint('🏁 === SEND MESSAGE END ===');
      debugPrint('');
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
  
  // Fetch available admins from the API
  static Future<List<Admin>> fetchAvailableAdmins() async {
    debugPrint('');
    debugPrint('🚀 === FETCH ADMIN LIST API CALL START ===');
    debugPrint('📡 Attempting to fetch admin list from /user/admin/list endpoint...');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('📤 Making GET request to /user/admin/list...');
      final response = await ApiClient.get('/user/admin/list');
      
      stopwatch.stop();
      debugPrint('📥 === API RESPONSE RECEIVED ===');
      debugPrint('   - Status Code: ${response.statusCode}');
      debugPrint('   - Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('   - Response Data Type: ${response.data.runtimeType}');
      debugPrint('   - Raw Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ HTTP 200 - Success response received');
        
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          debugPrint('✅ Response validation passed - processing admin data...');
          
          final adminData = responseData['data'] as List;
          debugPrint('📊 Admin Data Analysis:');
          debugPrint('   - Admin entries count: ${adminData.length}');
          debugPrint('   - Raw admin data: $adminData');
          
          final admins = <Admin>[];
          for (int i = 0; i < adminData.length; i++) {
            final adminJson = adminData[i];
            try {
              final admin = Admin.fromJson(adminJson);
              admins.add(admin);
              debugPrint('   ✅ Successfully parsed admin: ${admin.name} (${admin.id})');
            } catch (adminError) {
              debugPrint('   ❌ Error parsing admin #${i + 1}: $adminError');
            }
          }
          
          debugPrint('');
          debugPrint('✅ === ADMIN LIST PROCESSING COMPLETE ===');
          debugPrint('   - Total admins fetched: ${admins.length}');
          
          // Update cached admins
          _availableAdmins = admins;
          _adminsStreamController.add(admins);
          
          return admins;
        } else {
          debugPrint('❌ API response validation failed');
          return [];
        }
      } else {
        debugPrint('❌ HTTP Error - API request failed: ${response.statusCode}');
        return [];
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ === FETCH ADMIN LIST API ERROR ===');
      debugPrint('   - Error: $e');
      debugPrint('   - Stack trace: $stackTrace');
      return [];
    } finally {
      debugPrint('🏁 === FETCH ADMIN LIST API CALL END ===');
    }
  }
  
  // Get admin conversations for chat - returns all available admins
  static Future<List<ChatConversation>> getAdminConversations({String? propertyTitle}) async {
    final admins = await fetchAvailableAdmins();
    
    if (admins.isEmpty) {
      debugPrint('⚠️ No admins available, returning empty list');
      return [];
    }
    
    return admins.map((admin) => ChatConversation(
      id: 'chat_admin_${admin.id}',
      landlordId: admin.id,
      landlordName: admin.name.isNotEmpty ? admin.name : 'PearlNest Support',
      landlordProfilePic: admin.profilePicture ?? '',
      lastMessage: 'Start your conversation with ${admin.name}',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
      isOnline: admin.isOnline,
      propertyTitle: propertyTitle != null 
          ? 'Support Chat - $propertyTitle' 
          : 'Support Chat',
    )).toList();
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
      debugPrint('⚠️ No admins available for conversation');
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
      propertyTitle: propertyTitle != null 
          ? 'Support Chat - $propertyTitle' 
          : 'Support Chat',
    );
  }
  
  // Get or create a conversation with a specific admin
  static Future<ChatConversation?> getOrCreateConversation({
    required String adminId,
    required String adminName,
    String? propertyTitle,
  }) async {
    try {
      debugPrint('💬 Getting/creating conversation with admin: $adminName ($adminId)');
      
      // Create a conversation object with the admin
      final conversation = ChatConversation(
        id: 'admin_$adminId', // Prefix with 'admin_' to distinguish from property-based conversations
        landlordId: adminId,
        landlordName: adminName,
        landlordProfilePic: '', // Will use default avatar
        lastMessage: propertyTitle != null 
            ? 'Chat about: $propertyTitle' 
            : 'Chat with $adminName',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isOnline: true, // Assume admin is online
        propertyTitle: propertyTitle ?? 'General Support',
      );
      
      debugPrint('✅ Created conversation with admin: ${conversation.landlordName}');
      return conversation;
    } catch (e) {
      debugPrint('❌ Error creating conversation with admin: $e');
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
  
  // Fetch chat conversations from API with comprehensive debugging
  static Future<List<ChatConversation>> fetchChatList() async {
    debugPrint('');
    debugPrint('🚀 === FETCH CHAT LIST API CALL START ===');
    debugPrint('📡 Attempting to fetch chat list from /chat/chatList endpoint...');
    
    // Pre-flight checks
    debugPrint('🔍 Pre-flight API Debug Info:');
    debugPrint('   - Current User ID: $_currentUserId');
    debugPrint('   - Auth Token Available: ${ApiClient.currentAuthToken != null}');
    debugPrint('   - Base URL: ${AppConfig.getCurrentBaseUrl()}');
    debugPrint('   - Full API URL: ${AppConfig.getCurrentBaseUrl()}/chat/chatList');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('📤 Making GET request to /chat/chatList...');
      final response = await ApiClient.get('/chat/chatList');
      
      stopwatch.stop();
      debugPrint('📥 === API RESPONSE RECEIVED ===');
      debugPrint('   - Status Code: ${response.statusCode}');
      debugPrint('   - Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('   - Response Headers: ${response.headers}');
      debugPrint('   - Response Data Type: ${response.data.runtimeType}');
      debugPrint('   - Raw Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ HTTP 200 - Success response received');
        
        final responseData = response.data;
        debugPrint('🔍 Response Data Analysis:');
        debugPrint('   - Data is Map: ${responseData is Map}');
        debugPrint('   - Contains "success": ${responseData.containsKey('success')}');
        debugPrint('   - Success value: ${responseData['success']}');
        debugPrint('   - Contains "data": ${responseData.containsKey('data')}');
        debugPrint('   - Data field type: ${responseData['data'].runtimeType}');
        debugPrint('   - Data field value: ${responseData['data']}');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          debugPrint('✅ Response validation passed - processing chat data...');
          
          final chatData = responseData['data'] as List;
          debugPrint('📊 Chat Data Analysis:');
          debugPrint('   - Chat entries count: ${chatData.length}');
          debugPrint('   - Raw chat data: $chatData');
          
          // Process each chat entry with detailed debugging
          final conversations = <ChatConversation>[];
          for (int i = 0; i < chatData.length; i++) {
            final chat = chatData[i];
            debugPrint('');
            debugPrint('🔍 Processing chat entry #${i + 1}:');
            debugPrint('   - Raw chat entry: $chat');
            debugPrint('   - Chat entry type: ${chat.runtimeType}');
            
            try {
              final fromUser = chat['fromUser'] ?? {};
              final toUser = chat['toUser'] ?? {};
              final currentUserId = _currentUserId;
              
              debugPrint('   - fromUser: $fromUser');
              debugPrint('   - toUser: $toUser');
              debugPrint('   - fromUserId: ${chat['fromUserId']}');
              debugPrint('   - toUserId: ${chat['toUserId']}');
              debugPrint('   - message: ${chat['message']}');
              debugPrint('   - currentUserId: $currentUserId');
              
              // Determine if current user is sender or receiver
              final isCurrentUserSender = chat['fromUserId'] == currentUserId;
              final otherUser = isCurrentUserSender ? toUser : fromUser;
              final otherUserId = isCurrentUserSender ? chat['toUserId'] : chat['fromUserId'];
              
              debugPrint('   - isCurrentUserSender: $isCurrentUserSender');
              debugPrint('   - otherUser: $otherUser');
              debugPrint('   - otherUserId: $otherUserId');
              debugPrint('   - otherUser name: ${otherUser['name']}');
              debugPrint('   - otherUser role: ${otherUser['role']}');
              debugPrint('   - otherUser profilePicture: ${otherUser['profilePicture']}');
              
              final conversation = ChatConversation(
                id: 'chat_$otherUserId',
                landlordId: otherUserId?.toString() ?? '',
                landlordName: otherUser['name']?.toString() ?? 'Unknown User',
                landlordProfilePic: otherUser['profilePicture']?.toString() ?? '',
                lastMessage: chat['message']?.toString() ?? '',
                lastMessageTime: DateTime.now(), // TODO: Parse actual timestamp if available
                unreadCount: 0, // TODO: Get from API when available
                isOnline: otherUser['role'] == 'ADMIN', // Assume admin is always online
                propertyTitle: otherUser['role'] == 'ADMIN' 
                    ? 'Support Chat'
                    : 'Property Discussion',
              );
              
              conversations.add(conversation);
              debugPrint('   ✅ Successfully created conversation for ${conversation.landlordName}');
              
            } catch (chatError) {
              debugPrint('   ❌ Error processing chat entry #${i + 1}: $chatError');
              debugPrint('   🔍 Chat processing error type: ${chatError.runtimeType}');
              debugPrint('   🔍 Stack trace: ${StackTrace.current}');
            }
          }
          
          debugPrint('');
          debugPrint('✅ === CHAT LIST PROCESSING COMPLETE ===');
          debugPrint('   - Total conversations created: ${conversations.length}');
          debugPrint('   - Conversation details:');
          for (int i = 0; i < conversations.length; i++) {
            final conv = conversations[i];
            debugPrint('     ${i + 1}. ${conv.landlordName} (ID: ${conv.landlordId})');
            debugPrint('        Last message: "${conv.lastMessage}"');
            debugPrint('        Property: ${conv.propertyTitle}');
            debugPrint('        Online: ${conv.isOnline}');
          }
          
          return conversations;
        } else {
          debugPrint('❌ API response validation failed:');
          debugPrint('   - Success value: ${responseData['success']} (expected: true)');
          debugPrint('   - Data value: ${responseData['data']} (expected: non-null)');
          debugPrint('   - Full response: $responseData');
        }
      } else {
        debugPrint('❌ HTTP Error - API request failed:');
        debugPrint('   - Status Code: ${response.statusCode}');
        debugPrint('   - Status Message: ${response.statusMessage}');
        debugPrint('   - Response Data: ${response.data}');
        debugPrint('   - Response Headers: ${response.headers}');
      }
      
      debugPrint('❌ Failed to fetch chat list: Invalid or unsuccessful response');
      return [];
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('');
      debugPrint('❌ === FETCH CHAT LIST API ERROR ===');
      debugPrint('   - Error occurred after: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('   - Error: $e');
      debugPrint('   - Error type: ${e.runtimeType}');
      debugPrint('   - Stack trace: $stackTrace');
      
      // Additional error analysis
      if (e.toString().contains('connection')) {
        debugPrint('🔍 Network connectivity issue detected');
        debugPrint('   - Check internet connection');
        debugPrint('   - Verify server is running');
        debugPrint('   - Check if base URL is correct: ${AppConfig.getCurrentBaseUrl()}');
      } else if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        debugPrint('🔍 Authentication issue detected');
        debugPrint('   - Auth token may be invalid or expired');
        debugPrint('   - Current token: ${ApiClient.currentAuthToken}');
      } else if (e.toString().contains('404')) {
        debugPrint('🔍 Endpoint not found');
        debugPrint('   - Verify /chat/chatList endpoint exists on server');
      }
      
      return [];
    } finally {
      debugPrint('🏁 === FETCH CHAT LIST API CALL END ===');
      debugPrint('');
    }
  }

  // Comprehensive debug method to diagnose all chat service states
  static Future<void> debugChatServiceState() async {
    debugPrint('');
    debugPrint('🔍 ================================');
    debugPrint('🔍 === CHAT SERVICE DEBUG INFO ===');
    debugPrint('🔍 ================================');
    debugPrint('🔍 Debug timestamp: ${DateTime.now()}');
    debugPrint('');
    
    // Socket state
    debugPrint('📡 SOCKET STATE:');
    debugPrint('   - Socket instance exists: ${_socket != null}');
    debugPrint('   - Socket connected: ${_socket?.connected ?? false}');
    debugPrint('   - Socket ID: ${_socket?.id ?? 'N/A'}');
    debugPrint('   - Internal connection flag: $_isConnected');
    debugPrint('   - Socket namespace: ${_socket?.nsp ?? 'N/A'}');
    debugPrint('');
    
    // User state
    debugPrint('👤 USER STATE:');
    debugPrint('   - Current user ID: $_currentUserId');
    debugPrint('   - User ID is null: ${_currentUserId == null}');
    debugPrint('   - User ID is empty: ${_currentUserId?.isEmpty ?? true}');
    debugPrint('   - Available admins count: ${_availableAdmins.length}');
    debugPrint('   - Available admin IDs: ${_availableAdmins.map((a) => a.id).join(', ')}');
    debugPrint('   - Is current user admin: ${_currentUserId != null ? isAdminUser(_currentUserId!) : false}');
    debugPrint('');
    
    // Auth state
    debugPrint('🔐 AUTHENTICATION STATE:');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final storedUserId = prefs.getString('user_id');
      
      debugPrint('   - Auth token exists: ${token != null}');
      debugPrint('   - Auth token length: ${token?.length ?? 0}');
      debugPrint('   - Stored user ID: $storedUserId');
      debugPrint('   - ApiClient current token: ${ApiClient.currentAuthToken != null}');
      
      if (token != null && token.length > 20) {
        debugPrint('   - Token preview: ${token.substring(0, 10)}...${token.substring(token.length - 10)}');
      }
    } catch (e) {
      debugPrint('   - Error checking auth state: $e');
    }
    debugPrint('');
    
    // Stream state
    debugPrint('📺 STREAM STATE:');
    debugPrint('   - Message stream has listeners: ${_messageStreamController.hasListener}');
    debugPrint('   - Message stream is closed: ${_messageStreamController.isClosed}');
    debugPrint('   - Connection stream has listeners: ${_connectionStreamController.hasListener}');
    debugPrint('   - Connection stream is closed: ${_connectionStreamController.isClosed}');
    debugPrint('');
    
    // Network state
    debugPrint('🌐 NETWORK STATE:');
    debugPrint('   - Base URL: ${AppConfig.getCurrentBaseUrl()}');
    debugPrint('   - Socket URL: ${AppConfig.getCurrentBaseUrl()}');
    debugPrint('   - Chat API endpoint: ${AppConfig.getCurrentBaseUrl()}/chat/chatList');
    debugPrint('');
    
    // Test API connectivity
    debugPrint('🧪 TESTING API CONNECTIVITY:');
    try {
      debugPrint('   - Testing /chat/chatList endpoint...');
      final startTime = DateTime.now();
      final response = await ApiClient.get('/chat/chatList');
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      debugPrint('   ✅ API test successful:');
      debugPrint('      - Response time: ${duration.inMilliseconds}ms');
      debugPrint('      - Status code: ${response.statusCode}');
      debugPrint('      - Response type: ${response.data.runtimeType}');
      debugPrint('      - Has success field: ${response.data.containsKey('success')}');
      debugPrint('      - Success value: ${response.data['success']}');
      
      if (response.data['data'] != null) {
        final chatData = response.data['data'];
        debugPrint('      - Chat data type: ${chatData.runtimeType}');
        debugPrint('      - Chat entries count: ${chatData is List ? chatData.length : 'N/A'}');
      }
      
    } catch (e) {
      debugPrint('   ❌ API test failed: $e');
      debugPrint('   🔍 Error type: ${e.runtimeType}');
    }
    debugPrint('');
    
    // Socket connectivity test
    if (_socket != null) {
      debugPrint('🔌 SOCKET CONNECTIVITY:');
      debugPrint('   - Socket connected: ${_socket!.connected}');
      debugPrint('   - Socket disconnected: ${_socket!.disconnected}');
      debugPrint('   - Can emit events: ${_socket!.connected}');
      
      if (_socket!.connected) {
        debugPrint('   - Testing socket emission...');
        try {
          _socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          debugPrint('   ✅ Socket emit test successful');
        } catch (e) {
          debugPrint('   ❌ Socket emit test failed: $e');
        }
      }
    } else {
      debugPrint('🔌 SOCKET CONNECTIVITY: Socket is null');
    }
    debugPrint('');
    
    // Recommendations
    debugPrint('💡 RECOMMENDATIONS:');
    
    if (_socket == null || !_socket!.connected) {
      debugPrint('   - Socket not connected - call ChatService.connect()');
    }
    
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      debugPrint('   - User ID missing - check authentication flow');
      debugPrint('   - Try calling AuthService.fixMissingUserId()');
    }
    
    if (!_messageStreamController.hasListener) {
      debugPrint('   - No message stream listeners - UI may not receive messages');
    }
    
    if (!_connectionStreamController.hasListener) {
      debugPrint('   - No connection stream listeners - UI may not show connection status');
    }
    
    debugPrint('');
    debugPrint('🔍 ===== END DEBUG INFO =====');
    debugPrint('🔍 ========================');
    debugPrint('');
  }

  // Quick API health check method
  static Future<bool> isApiHealthy() async {
    try {
      debugPrint('🏥 Performing API health check...');
      final response = await ApiClient.get('/chat/chatList');
      final isHealthy = response.statusCode == 200 && response.data['success'] == true;
      debugPrint('🏥 API health check result: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');
      return isHealthy;
    } catch (e) {
      debugPrint('🏥 API health check failed: $e');
      return false;
    }
  }

  // Quick socket health check method
  static bool isSocketHealthy() {
    final isHealthy = _socket != null && _socket!.connected && _currentUserId != null;
    debugPrint('🔌 Socket health check result: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');
    if (!isHealthy) {
      debugPrint('   - Socket exists: ${_socket != null}');
      debugPrint('   - Socket connected: ${_socket?.connected ?? false}');
      debugPrint('   - User ID available: ${_currentUserId != null}');
    }
    return isHealthy;
  }
}
