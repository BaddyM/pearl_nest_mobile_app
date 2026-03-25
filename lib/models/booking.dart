import 'package:pearlnest/models/property.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  expired,
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
  final Property? property;

  // Add fields for API parsing
  final String tenantName;
  final String tenantEmail;
  final String tenantPhone;
  final String propertyTitle;
  final List<Map<String, dynamic>> payments; // Add payments field

  Booking({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.landlordId,
    required this.type,
    required this.requestedDate,
    this.property,
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
    this.payments = const [], // Default empty list
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

    // Determine status - map from API response
    BookingStatus determineStatus() {
      final status = json['bookingStatus']?.toString().toUpperCase();
      switch (status) {
        case 'PENDING':
          return BookingStatus.pending;
        case 'CONFIRMED':
        case 'APPROVED': // Map APPROVED to confirmed status
          return BookingStatus.confirmed;
        case 'CANCELLED':
        case 'REJECTED': // Map both CANCELLED and REJECTED to cancelled status
          return BookingStatus.cancelled;
        case 'COMPLETED':
          return BookingStatus.completed;
        case 'EXPIRED':
          return BookingStatus.expired;
        default:
          return BookingStatus.pending; // default to pending
      }
    }

    return Booking(
      id: json['id']?.toString() ?? '',
      propertyId: property['id']?.toString() ?? '',
      property: json['property'] != null ? Property.fromJson(json['property']) : null,
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
      payments: (json['Payments'] as List<dynamic>?)?.map((p) => p as Map<String, dynamic>).toList() ?? [],
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
      payments: [],
    );
  }

  String? get userName => null;
  double? get totalAmount => amount;
  DateTime? get checkInDate => startDate;
  DateTime? get checkOutDate => endDate;

  // Calculate total payments received
  double get totalPayments {
    return payments.fold(0.0, (sum, payment) {
      final amount = payment['amount'];
      if (amount is num) {
        return sum + amount.toDouble();
      }
      return sum;
    });
  }

  // Get payment count
  int get paymentCount => payments.length;
}
