import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class BookingCreateRequested extends BookingEvent {
  final String propertyId;
  final String checkInDate;
  final String checkOutDate;

  const BookingCreateRequested({
    required this.propertyId,
    required this.checkInDate,
    required this.checkOutDate,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate];
}

class BookingReset extends BookingEvent {
  const BookingReset();
}
