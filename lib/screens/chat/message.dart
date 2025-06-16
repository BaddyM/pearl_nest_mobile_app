import 'package:pearlnest/screens/chat/message_status.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final MessageStatus status;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead = false,
    this.status = MessageStatus.sent,
  });

  bool get isFromCurrentUser => senderId == 'current_user_id';

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}

enum MessageType {
  text,
  image,
  document,
  location,
}