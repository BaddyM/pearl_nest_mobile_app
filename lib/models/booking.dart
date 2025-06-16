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
  });

  String? get userName => null;
  double? get totalAmount => amount;
  DateTime? get checkInDate => startDate;
  DateTime? get checkOutDate => endDate;
}