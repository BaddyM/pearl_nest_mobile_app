import 'package:pearlnest/models/user_type.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final UserType userType;
  final bool isVerified;
  final DateTime createdAt;
  final List<String> favoriteProperties;
  final String? bio;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool emailNotifications;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.userType,
    this.isVerified = false,
    required this.createdAt,
    this.favoriteProperties = const [],
    required DateTime updatedAt,
    this.bio,
    this.pushNotifications = true,
    this.smsNotifications = true,
    this.emailNotifications = true,
  });

  // Add this factory constructor
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['contact'] ?? '',
      profileImage: json['profileImage'],
      userType: _parseUserType(json['userType'] ?? json['role'] ?? 'TENANT'),
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      favoriteProperties: json['favoriteProperties'] != null
          ? List<String>.from(json['favoriteProperties'])
          : [],
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      bio: json['bio'],
      pushNotifications: json['pushNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
    );
  }

  // Add this helper method
  static UserType _parseUserType(String userTypeString) {
    switch (userTypeString.toUpperCase()) {
      case 'LANDLORD':
        return UserType.landlord;
      case 'ADMIN':
        return UserType.admin;
      case 'TENANT':
      default:
        return UserType.tenant;
    }
  }

  // Optional: Add toJson method for sending data to backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact': phone,
      'profileImage': profileImage,
      'role': userType.toString().split('.').last.toUpperCase(),
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'favoriteProperties': favoriteProperties,
      'bio': bio,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'emailNotifications': emailNotifications,
    };
  }
}
