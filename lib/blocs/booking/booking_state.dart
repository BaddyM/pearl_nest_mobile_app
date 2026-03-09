import 'package:equatable/equatable.dart';
import 'package:pearlnest/models/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingSuccess extends BookingState {
  final Map<String, dynamic> bookingData;
  final String message;

  const BookingSuccess({
    required this.bookingData,
    required this.message,
  });

  @override
  List<Object?> get props => [bookingData, message];
}

class BookingFailure extends BookingState {
  final String error;
  final String? errorCode;

  const BookingFailure({
    required this.error,
    this.errorCode,
  });

  @override
  List<Object?> get props => [error, errorCode];
}

class BookingValidationError extends BookingState {
  final Map<String, String> fieldErrors;

  const BookingValidationError({
    required this.fieldErrors,
  });

  @override
  List<Object?> get props => [fieldErrors];
}

class BookingLoaded extends BookingState {
  final List<Booking> bookings;
  const BookingLoaded({required this.bookings});

  @override
  List<Object?> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;
  const BookingError({required this.message});

  @override
  List<Object?> get props => [message];
}

class BookingEmpty extends BookingState {}

class BookingCancelled extends BookingState {}

class PaymentLink extends BookingState {
  final String paymentLink;
  const PaymentLink({required this.paymentLink});
}
