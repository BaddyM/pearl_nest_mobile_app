part of 'new_chat_bloc.dart';

@immutable
sealed class NewChatEvent {}

class FetchNewChatList extends NewChatEvent {}

class FetchNewChat extends NewChatEvent {
  final String currentUserId;
  final String toUserId;
  final bool isSendMessage;
  final Map<String, dynamic>? sendMessage;
  FetchNewChat({required this.currentUserId, required this.toUserId, this.isSendMessage = false, this.sendMessage});
}

class ReadMessageEvent extends NewChatEvent {
  final String fromUserId;
  final String toUserId;
  ReadMessageEvent({required this.fromUserId, required this.toUserId});
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
