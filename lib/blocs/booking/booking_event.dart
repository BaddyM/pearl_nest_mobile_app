import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class BookingCreateRequested extends BookingEvent {
  final String propertyId;
  final String? checkInDate;
  final String? checkOutDate;
  final int deposit;
  final int total;

  const BookingCreateRequested({
    required this.propertyId,
    this.checkInDate,
    this.checkOutDate,
    required this.deposit,
    this.total = 0,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate];
}

class BookingReset extends BookingEvent {
  const BookingReset();
}

class FetchBookings extends BookingEvent {
  const FetchBookings();
}

class FetchLandlordBookings extends BookingEvent {
  const FetchLandlordBookings();
}

class BookingStatusUpdateRequested extends BookingEvent {
  final String bookingId;
  final String status;

  const BookingStatusUpdateRequested({
    required this.bookingId,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status];
}

class CreatePayment extends BookingEvent {
  final String propertyId;
  final String bookingId;
  final int amount;
  final int paid;

  const CreatePayment({required this.propertyId, this.paid = 0, required this.bookingId, required this.amount});
}

class CancelBooking extends BookingEvent {
  final String bookingId;

  const CancelBooking({required this.bookingId});
}
