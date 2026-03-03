part of 'new_chat_bloc.dart';

@immutable
sealed class NewChatState {}

final class NewChatInitial extends NewChatState {}

class NewChatLoadingState extends NewChatState {}

class NewChatLoadedState extends NewChatState {
  final List<Message> messages;
  final bool isSendMessage;
  final DateTime dateTime;
  NewChatLoadedState({required this.messages, this.isSendMessage = false, required this.dateTime});

  @override
  List<Object?> get props => [messages, dateTime];
}

class NewChatErrorState extends NewChatState {
  final String error;
  NewChatErrorState({required this.error});
}

class NewChatListLoadingState extends NewChatState {}

class NewChatListInitState extends NewChatState {
  final List<Map<String, dynamic>> data;
  NewChatListInitState({required this.data});
}

class NewChatListLoadedState extends NewChatState {
  final List<Map<String, dynamic>> data;
  NewChatListLoadedState({required this.data});
}

class NewChatListErrorState extends NewChatState {
  final String error;
  NewChatListErrorState({required this.error});
}
