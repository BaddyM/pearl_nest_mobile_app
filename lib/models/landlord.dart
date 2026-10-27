class Landlord {
  final String id;
  final String userId;
  final String businessName;
  final String businessDescription;
  final String businessPhone;
  final String businessEmail;
  final String licenseNumber;
  final String taxId;
  final String bankAccountNumber;
  final String bankName;
  final String businessRegistrationNumber;
  final String businessAddress;
  final List<String> verificationDocuments;
  final bool isVerified;
  final DateTime applicationDate;
  final DateTime? verificationDate;
  final String? rejectionReason;
  final double rating;
  final int totalProperties;
  final int totalBookings;
  final String? description;
  final List<String> specializations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Landlord({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessDescription,
    required this.businessPhone,
    required this.businessEmail,
    required this.licenseNumber,
    required this.taxId,
    required this.bankAccountNumber,
    required this.bankName,
    required this.businessRegistrationNumber,
    required this.businessAddress,
    required this.verificationDocuments,
    this.isVerified = false,
    required this.applicationDate,
    this.verificationDate,
    this.rejectionReason,
    this.rating = 0.0,
    this.totalProperties = 0,
    this.totalBookings = 0,
    this.description,
    this.specializations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Landlord.fromJson(Map<String, dynamic> json) {
    return Landlord(
      id: json['id'],
      userId: json['userId'],
      businessName: json['businessName'],
      businessDescription: json['businessDescription'],
      businessPhone: json['businessPhone'],
      businessEmail: json['businessEmail'],
      licenseNumber: json['licenseNumber'],
      taxId: json['taxId'],
      bankAccountNumber: json['bankAccountNumber'],
      bankName: json['bankName'],
      businessRegistrationNumber: json['businessRegistrationNumber'],
      businessAddress: json['businessAddress'],
      verificationDocuments: List<String>.from(json['verificationDocuments'] ?? []),
      isVerified: json['isVerified'] ?? false,
      applicationDate: DateTime.parse(json['applicationDate']),
      verificationDate: json['verificationDate'] != null 
          ? DateTime.parse(json['verificationDate']) 
          : null,
      rejectionReason: json['rejectionReason'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalProperties: json['totalProperties'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      description: json['description'],
      specializations: List<String>.from(json['specializations'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'licenseNumber': licenseNumber,
      'taxId': taxId,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'businessRegistrationNumber': businessRegistrationNumber,
      'businessAddress': businessAddress,
      'verificationDocuments': verificationDocuments,
      'isVerified': isVerified,
      'applicationDate': applicationDate.toIso8601String(),
      'verificationDate': verificationDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'rating': rating,
      'totalProperties': totalProperties,
      'totalBookings': totalBookings,
      'description': description,
      'specializations': specializations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
