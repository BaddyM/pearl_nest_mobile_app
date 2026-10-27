import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/apis/booking_service.dart';

abstract class BookingEvent {}

class FetchBookings extends BookingEvent {}

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<Booking> bookings;
  BookingLoaded(this.bookings);
}

class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(BookingInitial()) {
    on<FetchBookings>((event, emit) async {
      emit(BookingLoading());
      try {
        final bookings = await BookingService.fetchBookings();
        emit(BookingLoaded(bookings));
      } catch (e) {
        emit(BookingError('Failed to load bookings'));
      }
    });
  }
}
