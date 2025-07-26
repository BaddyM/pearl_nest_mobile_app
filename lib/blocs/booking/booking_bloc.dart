import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingService bookingService;

  BookingBloc({required this.bookingService}) : super(const BookingInitial()) {
    on<BookingCreateRequested>(_onBookingCreateRequested);
    on<BookingReset>(_onBookingReset);
    on<FetchBookings>(_onFetchBookings);
    on<FetchLandlordBookings>(_onFetchLandlordBookings);
    on<BookingStatusUpdateRequested>(_onBookingStatusUpdateRequested);
  }

  void _logState(String operation, BookingState newState) {
    if (kDebugMode) {
      ///debugPrint('🏨 BOOKING BLOC [$operation]: $newState');
    }
  }

  Future<void> _onBookingCreateRequested(
    BookingCreateRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    _logState('CREATE_REQUESTED', state);

    try {
      // Validate input data
      final validationErrors = _validateBookingData(
        event.propertyId,
        event.checkInDate,
        event.checkOutDate,
      );

      if (validationErrors.isNotEmpty) {
        emit(BookingValidationError(fieldErrors: validationErrors));
        _logState('VALIDATION_ERROR', state);
        return;
      }

      // Call the booking service
      final result = await BookingService.createBooking(
        propertyId: event.propertyId,
        checkInDate: event.checkInDate,
        checkOutDate: event.checkOutDate,
      );

      emit(BookingSuccess(
        bookingData: result['data'] ?? {},
        message: result['message'] ?? 'Booking created successfully',
      ));
      _logState('SUCCESS', state);
    } on BookingException catch (e) {
      if (e.statusCode == 400) {
        // Handle validation errors from backend
        emit(BookingFailure(error: e.message, errorCode: 'VALIDATION_ERROR'));
      } else if (e.statusCode == 401) {
        emit(BookingFailure(error: e.message, errorCode: 'UNAUTHORIZED'));
      } else if (e.statusCode == 404) {
        emit(BookingFailure(error: e.message, errorCode: 'PROPERTY_NOT_FOUND'));
      } else if (e.statusCode == 409) {
        emit(BookingFailure(error: e.message, errorCode: 'DATES_UNAVAILABLE'));
      } else {
        emit(BookingFailure(error: e.message, errorCode: 'API_ERROR'));
      }
      _logState('ERROR', state);
    } catch (e) {
      emit(BookingFailure(
        error: 'An unexpected error occurred: $e',
        errorCode: 'UNKNOWN_ERROR',
      ));
      _logState('UNEXPECTED_ERROR', state);
    }
  }

  void _onBookingReset(
    BookingReset event,
    Emitter<BookingState> emit,
  ) {
    emit(const BookingInitial());
    _logState('RESET', state);
  }

  Future<void> _onFetchBookings(
    FetchBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    _logState('FETCH_BOOKINGS', state);
    try {
      final bookings = await BookingService.fetchBookings();
      emit(BookingLoaded(bookings: bookings));
      _logState('LOADED', state);
    } catch (e) {
      emit(BookingError(message: 'Failed to fetch bookings: $e'));
      _logState('ERROR', state);
    }
  }

  Future<void> _onBookingStatusUpdateRequested(
    BookingStatusUpdateRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    _logState('STATUS_UPDATE_REQUESTED', state);

    try {
      // Call the booking service to update status
      final result = await BookingService.updateBookingStatus(
        bookingId: event.bookingId,
        status: event.status,
      );

      emit(BookingSuccess(
        bookingData: result['data'] ?? {},
        message: result['message'] ?? 'Booking status updated successfully',
      ));
      _logState('STATUS_UPDATE_SUCCESS', state);
    } on BookingException catch (e) {
      if (e.statusCode == 400) {
        emit(BookingFailure(error: e.message, errorCode: 'INVALID_REQUEST'));
      } else if (e.statusCode == 401) {
        emit(BookingFailure(error: e.message, errorCode: 'UNAUTHORIZED'));
      } else if (e.statusCode == 403) {
        emit(BookingFailure(error: e.message, errorCode: 'FORBIDDEN'));
      } else if (e.statusCode == 404) {
        emit(BookingFailure(error: e.message, errorCode: 'BOOKING_NOT_FOUND'));
      } else {
        emit(BookingFailure(error: e.message, errorCode: 'API_ERROR'));
      }
      _logState('STATUS_UPDATE_ERROR', state);
    } catch (e) {
      emit(BookingFailure(
        error: 'An unexpected error occurred: $e',
        errorCode: 'UNKNOWN_ERROR',
      ));
      _logState('STATUS_UPDATE_UNEXPECTED_ERROR', state);
    }
  }

  /// Validate booking data before sending to API
  Map<String, String> _validateBookingData(
    String propertyId,
    String checkInDate,
    String checkOutDate,
  ) {
    final errors = <String, String>{};

    // Validate property ID
    if (propertyId.trim().isEmpty) {
      errors['propertyId'] = 'Property ID is required';
    }

    // Validate check-in date
    if (checkInDate.trim().isEmpty) {
      errors['checkInDate'] = 'Check-in date is required';
    } else {
      try {
        final checkIn = DateTime.parse(checkInDate);
        final now = DateTime.now();
        if (checkIn.isBefore(DateTime(now.year, now.month, now.day))) {
          errors['checkInDate'] = 'Check-in date cannot be in the past';
        }
      } catch (e) {
        errors['checkInDate'] = 'Invalid check-in date format';
      }
    }

    // Validate check-out date
    if (checkOutDate.trim().isEmpty) {
      errors['checkOutDate'] = 'Check-out date is required';
    } else {
      try {
        final checkOut = DateTime.parse(checkOutDate);

        // If check-in date is valid, compare with check-out
        if (!errors.containsKey('checkInDate')) {
          final checkIn = DateTime.parse(checkInDate);
          if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
            errors['checkOutDate'] = 'Check-out date must be after check-in date';
          }
        }
      } catch (e) {
        errors['checkOutDate'] = 'Invalid check-out date format';
      }
    }

    return errors;
  }

  Future<void> _onFetchLandlordBookings(
    FetchLandlordBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    _logState('FETCH_LANDLORD_BOOKINGS', state);

    try {
      final bookings = await BookingService.fetchLandlordBookings();

      emit(BookingLoaded(bookings: bookings));
      _logState('FETCH_LANDLORD_BOOKINGS_SUCCESS', state);

      ///debugPrint('✅ Successfully loaded ${bookings.length} landlord bookings');
    } catch (e) {
      emit(BookingError(message: e.toString()));
      _logState('FETCH_LANDLORD_BOOKINGS_ERROR', state);

      ///debugPrint('❌ Failed to fetch landlord bookings: $e');
    }
  }
}
