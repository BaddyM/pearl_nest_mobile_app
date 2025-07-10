import 'package:equatable/equatable.dart';

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
