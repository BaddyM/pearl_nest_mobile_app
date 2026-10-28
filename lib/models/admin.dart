class Admin {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final bool isOnline;
  final bool isAvailable;
  final String? department;
  final String? role;
  final String contact;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.isOnline = false,
    this.isAvailable = true,
    this.department,
    this.role,
    required this.contact,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePicture: (json['profilePicture'] ?? json['profileImage'])?.toString(),
      isOnline: _parseBool(json['isOnline']),
      isAvailable: _parseBool(json['isAvailable'] ?? json['isOnline']),
      department: json['department']?.toString(),
      role: json['role']?.toString(),
      contact: json['contact']?.toString() ?? '',
    );
  }

  static bool _parseBool(dynamic value) =>
      value == true || value?.toString().toLowerCase() == 'true';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'department': department,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'Admin(id: $id, name: $name, isOnline: $isOnline, isAvailable: $isAvailable)';
  }
}

class UnreadChat {
  final String id;
  final bool isRead;
  UnreadChat({required this.id, required this.isRead});

  factory UnreadChat.fromJson(Map<String, dynamic> json) {
    return UnreadChat(
      id: json['fromUserId']?.toString() ?? '',
      isRead: json["isRead"] == true,
    );
  }
}
