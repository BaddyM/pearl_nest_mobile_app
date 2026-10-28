import 'dart:convert';

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
    final property = _mapFrom(json['property']);
    final action = json['actionData'] ?? json['action'];
    final metadata = _mapFrom(json['metadata'] ?? json['data']);
    final metadataProperty = _mapFrom(metadata?['property']);
    return NotificationItem(
      id: _stringValue(json['_id'] ?? json['id']) ?? '',
      title: _stringValue(json['title']) ?? 'PearlNest Notification',
      message: _stringValue(json['message'] ?? json['body']) ?? '',
      type: _parseNotificationType(
        _stringValue(json['type'] ?? metadata?['type']) ?? 'system',
      ),
      timestamp: _parseTimestamp(json['createdAt'] ?? json['timestamp']),
      isRead: json['isRead'] == true || json['read'] == true,
      propertyId: _stringValue(
        json['propertyId'] ??
            metadata?['propertyId'] ??
            property?['id'] ??
            metadataProperty?['id'],
      ),
      propertyTitle: _stringValue(
        json['propertyTitle'] ??
            metadata?['propertyTitle'] ??
            property?['title'] ??
            metadataProperty?['title'],
      ),
      propertyImage: _stringValue(
        json['propertyImage'] ??
            metadata?['propertyImage'] ??
            property?['image'] ??
            metadataProperty?['image'],
      ),
      actionData: action is String
          ? action
          : action is Map
              ? jsonEncode(action)
              : null,
      metadata: metadata,
    );
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  static Map<String, dynamic>? _mapFrom(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'property_update':
      case 'property':
      case 'properties':
      case 'propertyupdate':
        return NotificationType.propertyUpdate;
      case 'booking':
      case 'bookings':
      case 'reservation':
        return NotificationType.booking;
      case 'message':
      case 'messages':
      case 'chat':
        return NotificationType.message;
      case 'favorite':
      case 'favourite':
      case 'like':
        return NotificationType.favorite;
      case 'payment':
      case 'payments':
      case 'transaction':
        return NotificationType.payment;
      case 'review':
      case 'rating':
        return NotificationType.review;
      case 'system':
      case 'notifications':
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
