import 'package:pearlnest/screens/chat/message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<bool> sendMessage(Message message) async {
    await Future.delayed(Duration(milliseconds: 500));

    return DateTime.now().millisecond % 20 != 0;
  }

  Future<void> markMessageAsDelivered(String messageId) async {
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> markMessageAsRead(String messageId) async {
    await Future.delayed(Duration(seconds: 2));
  }

  Future<List<Message>> getChatHistory(String conversationId) async {
    await Future.delayed(Duration(milliseconds: 800));
    return [];
  }

  Future<void> updateLastSeen(String userId) async {
    await Future.delayed(Duration(milliseconds: 200));
  }

  Stream<bool> getUserOnlineStatus(String userId) async* {
    while (true) {
      await Future.delayed(Duration(seconds: 30));
      yield DateTime.now().second % 3 == 0;
    }
  }
}
