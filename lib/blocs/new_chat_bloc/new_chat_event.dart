part of 'new_chat_bloc.dart';

@immutable
sealed class NewChatEvent {}

class FetchNewChatList extends NewChatEvent {
  final bool loadAdminsIfEmpty;
  FetchNewChatList({this.loadAdminsIfEmpty = true});
}

class FetchNewChat extends NewChatEvent {
  final String currentUserId;
  final String toUserId;
  final String? propertyId;
  final bool isSendMessage;
  final Map<String, dynamic>? sendMessage;
  FetchNewChat({
    required this.currentUserId,
    required this.toUserId,
    this.propertyId,
    this.isSendMessage = false,
    this.sendMessage,
  });
}

class ReadMessageEvent extends NewChatEvent {
  final String fromUserId;
  final String toUserId;
  final String? propertyId;
  ReadMessageEvent({
    required this.fromUserId,
    required this.toUserId,
    this.propertyId,
  });
}

class SendMessageEvent extends NewChatEvent {
  final String fromUserId;
  final String toUserId;
  final String message;
  SendMessageEvent({required this.fromUserId, required this.toUserId, required this.message});
}

class NewIncomingMessageEvent extends NewChatEvent {
  final Map<String, dynamic> data;
  NewIncomingMessageEvent(this.data);
}

class ChatSocketErrorEvent extends NewChatEvent {
  final String message;
  ChatSocketErrorEvent(this.message);
}
