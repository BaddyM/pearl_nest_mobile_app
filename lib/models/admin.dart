class Admin {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final bool isOnline;
  final bool isAvailable;
  final String? department;
  final String? role;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.isOnline = false,
    this.isAvailable = true,
    this.department,
    this.role,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? json['profileImage'],
      isOnline: json['isOnline'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
      department: json['department'],
      role: json['role'],
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
