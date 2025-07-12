import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatConnected extends ChatState {
  final List<ChatMessage> messages;
  final bool isConnected;
  final String? currentChatUserId;

  const ChatConnected({
    required this.messages,
    required this.isConnected,
    this.currentChatUserId,
  });

  @override
  List<Object?> get props => [messages, isConnected, currentChatUserId];

  ChatConnected copyWith({
    List<ChatMessage>? messages,
    bool? isConnected,
    String? currentChatUserId,
  }) {
    return ChatConnected(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      currentChatUserId: currentChatUserId ?? this.currentChatUserId,
    );
  }
}

class ChatDisconnected extends ChatState {
  final List<ChatMessage> messages;
  final String? error;

  const ChatDisconnected({
    required this.messages,
    this.error,
  });

  @override
  List<Object?> get props => [messages, error];
}

class ChatError extends ChatState {
  final String error;
  final List<ChatMessage> messages;

  const ChatError({
    required this.error,
    required this.messages,
  });

  @override
  List<Object?> get props => [error, messages];
}

class ChatMessageSending extends ChatState {
  final List<ChatMessage> messages;
  final bool isConnected;
  final String? currentChatUserId;

  const ChatMessageSending({
    required this.messages,
    required this.isConnected,
    this.currentChatUserId,
  });

  @override
  List<Object?> get props => [messages, isConnected, currentChatUserId];
}

class ChatMessageSent extends ChatState {
  final List<ChatMessage> messages;
  final bool isConnected;
  final String? currentChatUserId;

  const ChatMessageSent({
    required this.messages,
    required this.isConnected,
    this.currentChatUserId,
  });

  @override
  List<Object?> get props => [messages, isConnected, currentChatUserId];
}

class ChatTypingState extends ChatState {
  final List<ChatMessage> messages;
  final bool isConnected;
  final String? currentChatUserId;
  final bool isTyping;
  final String? typingUserId;

  const ChatTypingState({
    required this.messages,
    required this.isConnected,
    this.currentChatUserId,
    required this.isTyping,
    this.typingUserId,
  });

  @override
  List<Object?> get props => [messages, isConnected, currentChatUserId, isTyping, typingUserId];
}
