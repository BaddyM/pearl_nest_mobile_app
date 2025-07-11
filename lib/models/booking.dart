enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

enum BookingType {
  viewing,
  rental,
  monthly,
  daily,
}

class Booking {
  final String id;
  final String propertyId;
  final String tenantId;
  final String landlordId;
  final BookingType type;
  final DateTime requestedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final BookingStatus status;
  final String? message;
  final double? amount;
  final DateTime createdAt;

  // Add fields for API parsing
  final String tenantName;
  final String tenantEmail;
  final String tenantPhone;
  final String propertyTitle;

  Booking({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.landlordId,
    required this.type,
    required this.requestedDate,
    this.startDate,
    this.endDate,
    required this.status,
    this.message,
    this.amount,
    required this.createdAt,
    required this.tenantName,
    required this.tenantEmail,
    required this.tenantPhone,
    required this.propertyTitle,
  });

  factory Booking.fromApiJson(Map<String, dynamic> json) {
    final property = json['property'] ?? {};
    final user = json['user'] ?? {};
    return Booking(
      id: json['id'] ?? '',
      propertyId: property['id'] ?? '',
      tenantId: user['id'] ?? '',
      landlordId: property['userId'] ?? '',
      type: BookingType.rental, // You may want to parse this if available
      requestedDate: DateTime.parse(json['bookingDate']),
      startDate: json['checkInDate'] != null ? DateTime.parse(json['checkInDate']) : null,
      endDate: json['checkOutDate'] != null ? DateTime.parse(json['checkOutDate']) : null,
      status: BookingStatus.pending, // You may want to parse this if available
      message: json['message'],
      amount: property['price'] != null ? (property['price'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['bookingDate']),
      tenantName: user['name'] ?? '',
      tenantEmail: user['email'] ?? '',
      tenantPhone: user['contact'] ?? '',
      propertyTitle: property['propertyName'] ?? '',
    );
  }

  static Booking empty() {
    return Booking(
      id: '',
      propertyId: '',
      tenantId: '',
      landlordId: '',
      type: BookingType.viewing,
      requestedDate: DateTime.now(),
      startDate: null,
      endDate: null,
      status: BookingStatus.pending,
      message: '',
      amount: 0.0,
      createdAt: DateTime.now(),
      tenantName: '',
      tenantEmail: '',
      tenantPhone: '',
      propertyTitle: '',
    );
  }

  String? get userName => null;
  double? get totalAmount => amount;
  DateTime? get checkInDate => startDate;
  DateTime? get checkOutDate => endDate;
}