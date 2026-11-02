part of 'new_chat_bloc.dart';

@immutable
sealed class NewChatState {}

final class NewChatInitial extends NewChatState {}

class NewChatLoadingState extends NewChatState {}

class NewChatLoadedState extends NewChatState {
  final List<Message> messages;
  final bool isSendMessage;
  final DateTime dateTime;
  final String conversationStatus;
  final String? refreshError;
  final Map<String, dynamic>? pendingMessage;
  NewChatLoadedState({
    required this.messages,
    this.isSendMessage = false,
    required this.dateTime,
    this.conversationStatus = 'OPEN',
    this.refreshError,
    this.pendingMessage,
  });

  @override
  List<Object?> get props => [
        messages,
        dateTime,
        conversationStatus,
        refreshError,
        pendingMessage,
      ];
}

class NewChatErrorState extends NewChatState {
  final String error;
  NewChatErrorState({required this.error});
}

class NewChatListLoadingState extends NewChatState {}

class NewChatListInitState extends NewChatState {
  final List<Map<String, dynamic>> data;
  final String? refreshError;
  NewChatListInitState({required this.data, this.refreshError});
}

class NewChatListLoadedState extends NewChatState {
  final List<Map<String, dynamic>> data;
  final String? refreshError;
  NewChatListLoadedState({required this.data, this.refreshError});
}

class NewChatListErrorState extends NewChatState {
  final String error;
  NewChatListErrorState({required this.error});
}
