import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/apis/api_client.dart';
import '../../apis/chat_service.dart';
import '../../models/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  String? _currentChatUserId;
  bool _isConnected = false;

  ChatBloc() : super(const ChatInitial()) {
    // Register event handlers
    on<ChatInitialize>(_onInitialize);
    on<ChatConnect>(_onConnect);
    on<ChatDisconnect>(_onDisconnect);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatReceiveMessage>(_onReceiveMessage);
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatConnectionChanged>(_onConnectionChanged);
    on<ChatClearMessages>(_onClearMessages);
  }

  Future<void> _onInitialize(ChatInitialize event, Emitter<ChatState> emit) async {
    try {
      emit(const ChatLoading());

      // Initialize chat service
      await ChatService.connect();

      // Listen to incoming messages
      _messageSubscription?.cancel();
      _messageSubscription = ChatService.messageStream.listen((message) {
        debugPrint('🔍 ChatBloc: Received message from stream');
        add(ChatReceiveMessage(message: message));
      });

      // Listen to connection changes
      _connectionSubscription?.cancel();
      _connectionSubscription = ChatService.connectionStream.listen((isConnected) {
        debugPrint('🔍 ChatBloc: Connection status changed to: $isConnected');
        add(ChatConnectionChanged(isConnected: isConnected));
      });

      _isConnected = ChatService.isConnected;

      debugPrint('🔍 ChatBloc: Chat initialized successfully, connected: $_isConnected');

      emit(ChatConnected(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } catch (e) {
      debugPrint('❌ ChatBloc: Chat initialization error: $e');
      debugPrint('🔍 Stack trace: ${StackTrace.current}');
      emit(ChatError(
        error: 'Failed to initialize chat: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onConnect(ChatConnect event, Emitter<ChatState> emit) async {
    try {
      await ChatService.connect();
      _isConnected = ChatService.isConnected;

      print("ChatConnect running");

      emit(ChatConnected(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } catch (e) {
      debugPrint('❌ Chat connection error: $e');
      emit(ChatError(
        error: 'Failed to connect to chat: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onDisconnect(ChatDisconnect event, Emitter<ChatState> emit) async {
    try {
      ChatService.disconnect();
      _isConnected = false;

      emit(ChatDisconnected(
        messages: List.from(_messages),
      ));
    } catch (e) {
      debugPrint('❌ Chat disconnection error: $e');
      emit(ChatError(
        error: 'Failed to disconnect from chat: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onSendMessage(ChatSendMessage event, Emitter<ChatState> emit) async {
    try {
      print("ChatSendMessage running.....");

      // Emit sending state
      emit(ChatMessageSending(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));

      // Send message via socket
      await ChatService.sendMessage(
        toUserId: event.toUserId,
        text: event.text,
      );

      emit(ChatMessageSent(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } catch (e) {
      emit(ChatError(
        error: 'Failed to send message: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onReceiveMessage(ChatReceiveMessage event, Emitter<ChatState> emit) async {
    try {
      // Add message to the list
      _messages.add(event.message);

      // Sort messages by timestamp
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      emit(ChatConnected(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } catch (e) {
      debugPrint('❌ Error receiving message: $e');
      emit(ChatError(
        error: 'Failed to receive message: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onLoadMessages(ChatLoadMessages event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());
      _messages.clear();
      _currentChatUserId = event.chatWithUserId;
      final data = await ApiClient.get("/chat/messagesList/$_currentChatUserId");
      List messagesFromDB = data.data["data"];
      for (int i = 0; i < messagesFromDB.length; i++) {
        DateTime dateTime = DateTime.parse(messagesFromDB[i]["createdAt"]);
        _messages.add(ChatMessage(
          id: messagesFromDB[i]["id"],
          fromUserId: messagesFromDB[i]["fromUserId"],
          toUserId: messagesFromDB[i]["toUserId"],
          text: messagesFromDB[i]["message"],
          timestamp: dateTime,
        ));
      }

      emit(ChatConnected(
        messages: _messages,
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } catch (e, stackTrace) {
      print('❌ Error loading messages: $e');
      print('❌ Location: $stackTrace');
      emit(ChatError(
        error: 'Failed to load messages: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onMarkAsRead(ChatMarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await ApiClient.patchWithoutData("/chat/readMessage/${event.fromUserId}/${event.toUserId}");
      emit(ChatConnected(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } catch (e) {
      debugPrint('❌ Error marking message as read: $e');
      emit(ChatError(
        error: 'Failed to mark message as read: ${e.toString()}',
        messages: List.from(_messages),
      ));
    }
  }

  Future<void> _onConnectionChanged(ChatConnectionChanged event, Emitter<ChatState> emit) async {
    _isConnected = event.isConnected;

    if (_isConnected) {
      emit(ChatConnected(
        messages: List.from(_messages),
        isConnected: _isConnected,
        currentChatUserId: _currentChatUserId,
      ));
    } else {
      emit(ChatDisconnected(
        messages: List.from(_messages),
        error: 'Connection lost',
      ));
    }
  }

  Future<void> _onClearMessages(ChatClearMessages event, Emitter<ChatState> emit) async {
    _messages.clear();
    _currentChatUserId = null;

    emit(ChatConnected(
      messages: List.from(_messages),
      isConnected: _isConnected,
      currentChatUserId: _currentChatUserId,
    ));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    ChatService.dispose();
    return super.close();
  }
}
