import 'package:pearlnest/screens/chat/message.dart';

class ChatMessage {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType? messageType; // text, image, etc.

  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.messageType = MessageType.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? json['from_user_id']?.toString() ?? '',
      toUserId: json['toUserId']?.toString() ?? json['to_user_id']?.toString() ?? '',
      text: json['text']?.toString() ?? json['message']?.toString() ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      messageType: json['messageType'] ?? json['message_type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'messageType': messageType,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? messageType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, text: $text, timestamp: $timestamp, isRead: $isRead)';
  }
}
