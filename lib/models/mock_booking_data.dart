// import 'package:pearlnest/models/booking.dart';

// class MockBookingData {
//   static List<Booking> generateMockBookings() {
//     final now = DateTime.now();
    
//     return [
//       Booking(
//         id: 'booking_1',
//         propertyId: '1',
//         tenantId: 'user1',
//         landlordId: 'landlord_1',
//         type: BookingType.rental,
//         requestedDate: now.add(Duration(days: 7)),
//         startDate: now.add(Duration(days: 7)),
//         endDate: now.add(Duration(days: 37)), // 30 days rental
//         status: BookingStatus.pending,
//         message: 'Hi! I\'m very interested in renting this beautiful apartment. I\'m a working professional with stable income and excellent references. Would love to schedule a viewing at your earliest convenience.',
//         amount: 25000000,
//         createdAt: now.subtract(Duration(hours: 2)),
//       ),
      
//       Booking(
//         id: 'booking_2',
//         propertyId: '2',
//         tenantId: 'user2',
//         landlordId: 'landlord_1',
//         type: BookingType.viewing,
//         requestedDate: now.add(Duration(days: 2)),
//         startDate: null,
//         endDate: null,
//         status: BookingStatus.pending,
//         message: 'Hello, I would like to schedule a viewing for this studio apartment. I\'m available this weekend. Please let me know what times work best for you.',
//         amount: 000,
//         createdAt: now.subtract(Duration(hours: 5)),
//       ),
      
//       Booking(
//         id: 'booking_3',
//         propertyId: '3',
//         tenantId: 'user3',
//         landlordId: 'landlord_1',
//         type: BookingType.monthly,
//         requestedDate: now.add(Duration(days: 14)),
//         startDate: now.add(Duration(days: 14)),
//         endDate: now.add(Duration(days: 44)), // 30 days
//         status: BookingStatus.pending,
//         message: 'Looking for a family home for a month-long stay. We have two kids and are very responsible tenants. Can provide references upon request.',
//         amount: 3200000,
//         createdAt: now.subtract(Duration(hours: 8)),
//       ),
      
//       Booking(
//         id: 'booking_4',
//         propertyId: '1',
//         tenantId: 'user2',
//         landlordId: 'landlord_1',
//         type: BookingType.daily,
//         requestedDate: now.add(Duration(days: 3)),
//         startDate: now.add(Duration(days: 3)),
//         endDate: now.add(Duration(days: 8)), // 5 days
//         status: BookingStatus.confirmed,
//         message: 'Perfect location for my business trip. Thank you for accepting my booking!',
//         amount: 7500000,
//         createdAt: now.subtract(Duration(days: 1)),
//       ),
      
//       Booking(
//         id: 'booking_5',
//         propertyId: '2',
//         tenantId: 'user1',
//         landlordId: 'landlord_1',
//         type: BookingType.rental,
//         requestedDate: now.add(Duration(days: 30)),
//         startDate: now.add(Duration(days: 30)),
//         endDate: now.add(Duration(days: 60)),
//         status: BookingStatus.confirmed,
//         message: 'Thank you for confirming! I\'ll take good care of the property.',
//         amount: 1800000,
//         createdAt: now.subtract(Duration(days: 2)),
//       ),
      
//       Booking(
//         id: 'booking_6',
//         propertyId: '3',
//         tenantId: 'user2',
//         landlordId: 'landlord_1',
//         type: BookingType.viewing,
//         requestedDate: now.subtract(Duration(days: 1)),
//         startDate: null,
//         endDate: null,
//         status: BookingStatus.cancelled,
//         message: 'Unfortunately, I found another place. Thank you for your time.',
//         amount: 000,
//         createdAt: now.subtract(Duration(days: 3)),
//       ),
      
//       Booking(
//         id: 'booking_7',
//         propertyId: '1',
//         tenantId: 'user3',
//         landlordId: 'landlord_1',
//         type: BookingType.monthly,
//         requestedDate: now.subtract(Duration(days: 5)),
//         startDate: now.subtract(Duration(days: 5)),
//         endDate: now.add(Duration(days: 25)),
//         status: BookingStatus.cancelled,
//         message: 'Had to cancel due to job relocation. Sorry for the inconvenience.',
//         amount: 2800000,
//         createdAt: now.subtract(Duration(days: 7)),
//       ),
      
//       Booking(
//         id: 'booking_8',
//         propertyId: '2',
//         tenantId: 'user1',
//         landlordId: 'landlord_1',
//         type: BookingType.daily,
//         requestedDate: now.subtract(Duration(days: 10)),
//         startDate: now.subtract(Duration(days: 10)),
//         endDate: now.subtract(Duration(days: 7)), // 3 days stay
//         status: BookingStatus.completed,
//         message: 'Great stay! The apartment was exactly as described. Highly recommend!',
//         amount: 450000,
//         createdAt: now.subtract(Duration(days: 12)),
//       ),
      
//       Booking(
//         id: 'booking_9',
//         propertyId: '3',
//         tenantId: 'user2',
//         landlordId: 'landlord_1',
//         type: BookingType.rental,
//         requestedDate: now.subtract(Duration(days: 45)),
//         startDate: now.subtract(Duration(days: 45)),
//         endDate: now.subtract(Duration(days: 15)), // 30 days completed
//         status: BookingStatus.completed,
//         message: 'Wonderful experience! The house was perfect for our family. Thank you!',
//         amount: 3500000,
//         createdAt: now.subtract(Duration(days: 50)),
//       ),
      
//       Booking(
//         id: 'booking_10',
//         propertyId: '1',
//         tenantId: 'user3',
//         landlordId: 'landlord_1',
//         type: BookingType.viewing,
//         requestedDate: now.subtract(Duration(days: 20)),
//         startDate: null,
//         endDate: null,
//         status: BookingStatus.completed,
//         message: 'Viewing completed. Decided to go with another property, but thank you for showing me around!',
//         amount: 000,
//         createdAt: now.subtract(Duration(days: 22)),
//       ),
//     ];
//   }
// }