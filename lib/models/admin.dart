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
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? json['profileImage'],
      isOnline: json['isOnline'] ?? false,
      isAvailable: json['isOnline'] ?? true,
      department: json['department'],
      role: json['role'],
      contact: json['contact'] ?? '',
    );
  }

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
      id: json['fromUserId'],
      isRead: json["isRead"],
    );
  }
}
