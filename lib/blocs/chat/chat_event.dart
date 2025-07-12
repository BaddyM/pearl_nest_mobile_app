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

  const ChatSendMessage({
    required this.toUserId,
    required this.text,
  });

  @override
  List<Object?> get props => [toUserId, text];
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
  final String messageId;

  const ChatMarkAsRead({required this.messageId});

  @override
  List<Object?> get props => [messageId];
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

class ChatStartTyping extends ChatEvent {
  final String toUserId;

  const ChatStartTyping({required this.toUserId});

  @override
  List<Object?> get props => [toUserId];
}

class ChatStopTyping extends ChatEvent {
  final String toUserId;

  const ChatStopTyping({required this.toUserId});

  @override
  List<Object?> get props => [toUserId];
}
