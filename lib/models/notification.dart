enum NotificationType {
  propertyUpdate,
  booking,
  message,
  favorite,
  system,
  payment,
  review,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyImage;
  final String? actionData;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.propertyId,
    this.propertyTitle,
    this.propertyImage,
    this.actionData,
    this.metadata,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      type: _parseNotificationType(json['type'] ?? 'system'),
      timestamp: _parseTimestamp(json['createdAt'] ?? json['timestamp']),
      isRead: json['isRead'] ?? json['read'] ?? false,
      propertyId: json['propertyId'] ?? json['property']?['id'],
      propertyTitle: json['propertyTitle'] ?? json['property']?['title'],
      propertyImage: json['propertyImage'] ?? json['property']?['image'],
      actionData: json['actionData'] ?? json['action'],
      metadata: json['metadata'] ?? json['data'],
    );
  }

  static NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'property_update':
      case 'property':
      case 'propertyupdate':
        return NotificationType.propertyUpdate;
      case 'booking':
      case 'reservation':
        return NotificationType.booking;
      case 'message':
      case 'chat':
        return NotificationType.message;
      case 'favorite':
      case 'favourite':
      case 'like':
        return NotificationType.favorite;
      case 'payment':
      case 'transaction':
        return NotificationType.payment;
      case 'review':
      case 'rating':
        return NotificationType.review;
      case 'system':
      case 'app':
      case 'general':
      default:
        return NotificationType.system;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (timestamp is int) {
      // Assume milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    
    return DateTime.now();
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    String? actionData,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      actionData: actionData ?? this.actionData,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyImage': propertyImage,
      'actionData': actionData,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'NotificationItem(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}
