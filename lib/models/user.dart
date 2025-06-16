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
    this.favoriteProperties = const [], required DateTime updatedAt,
  });
}
