import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatInitialize extends ChatEvent {
  const ChatInitialize();
}

class ChatConnect extends ChatEvent {
  const ChatConnect();
}

class ChatDisconnect extends ChatEvent {
  const ChatDisconnect();
}

class ChatSendMessage extends ChatEvent {
  final String toUserId;
  final String text;
  final bool fromProperty;

  const ChatSendMessage({
    required this.toUserId,
    required this.text,
    this.fromProperty = false,
  });

  @override
  List<Object?> get props => [toUserId, text, fromProperty];
}

class ChatReceiveMessage extends ChatEvent {
  final ChatMessage message;

  const ChatReceiveMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatLoadMessages extends ChatEvent {
  final String chatWithUserId;

  const ChatLoadMessages({required this.chatWithUserId});

  @override
  List<Object?> get props => [chatWithUserId];
}

class ChatMarkAsRead extends ChatEvent {
  final String fromUserId;
  final String toUserId;

  const ChatMarkAsRead({required this.fromUserId, required this.toUserId});

  @override
  List<Object?> get props => [fromUserId, toUserId];
}

class ChatConnectionChanged extends ChatEvent {
  final bool isConnected;

  const ChatConnectionChanged({required this.isConnected});

  @override
  List<Object?> get props => [isConnected];
}

class ChatClearMessages extends ChatEvent {
  const ChatClearMessages();
}
