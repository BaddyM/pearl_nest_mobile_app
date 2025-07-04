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
  });

  // Add this factory constructor
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      userType: _parseUserType(json['userType'] ?? 'TENANT'),
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
    );
  }

  // Add this helper method
  static UserType _parseUserType(String userTypeString) {
    switch (userTypeString.toUpperCase()) {
      case 'LANDLORD':
        return UserType.landlord;
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
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType.toString().split('.').last.toUpperCase(),
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'favoriteProperties': favoriteProperties,
    };
  }
}
