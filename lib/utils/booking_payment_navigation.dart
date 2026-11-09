import 'package:flutter/material.dart';
import 'package:pearlnest/apis/payment_service.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/tenant/payment_screen.dart';

Future<bool?> openBookingPayment({
  required BuildContext context,
  required User user,
  required Booking booking,
  required Property property,
  required double amount,
}) async {
  if (amount <= 0) {
    throw const PaymentException('There is no outstanding balance to pay.');
  }

  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaymentScreen.preparing(
        preparePayment: () => PaymentService.createPayment(
          propertyId: booking.propertyId,
          bookingId: booking.id,
          amount: amount,
        ),
        amount: amount,
        propertyTitle: property.title,
        user: user,
        bookingStatus: booking.status == BookingStatus.confirmed
            ? 'APPROVED'
            : booking.status.name.toUpperCase(),
      ),
    ),
  );
}
