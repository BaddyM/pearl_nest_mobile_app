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
    
    // Parse dates safely
    DateTime parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Determine booking type based on property data
    BookingType determineType() {
      final period = property['period']?.toString().toLowerCase() ?? '';
      if (period.contains('month')) return BookingType.monthly;
      if (period.contains('day')) return BookingType.daily;
      return BookingType.rental; // default
    }
    
    // Determine status - for now defaulting to pending since API doesn't provide it
    BookingStatus determineStatus() {
      // You can enhance this logic based on additional API fields
      final status = json['status']?.toString().toLowerCase();
      switch (status) {
        case 'confirmed':
          return BookingStatus.confirmed;
        case 'cancelled':
          return BookingStatus.cancelled;
        case 'completed':
          return BookingStatus.completed;
        default:
          return BookingStatus.pending;
      }
    }
    
    return Booking(
      id: json['id']?.toString() ?? '',
      propertyId: property['id']?.toString() ?? '',
      tenantId: user['id']?.toString() ?? '',
      landlordId: property['userId']?.toString() ?? '',
      type: determineType(),
      requestedDate: parseDate(json['bookingDate']),
      startDate: json['checkInDate'] != null ? parseDate(json['checkInDate']) : null,
      endDate: json['checkOutDate'] != null ? parseDate(json['checkOutDate']) : null,
      status: determineStatus(),
      message: json['message']?.toString(),
      amount: property['price'] != null ? (property['price'] as num).toDouble() : null,
      createdAt: parseDate(json['bookingDate']),
      tenantName: user['name']?.toString() ?? 'Unknown User',
      tenantEmail: user['email']?.toString() ?? 'No email provided',
      tenantPhone: user['contact']?.toString() ?? 'No phone provided',
      propertyTitle: property['propertyName']?.toString() ?? 'Unknown Property',
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