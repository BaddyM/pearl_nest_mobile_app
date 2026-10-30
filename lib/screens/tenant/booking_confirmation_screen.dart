// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Property property;
  final User user;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final double? estimatedAmount;
  final String? paymentOption;

  const BookingConfirmationScreen({
    super.key,
    required this.property,
    required this.user,
    this.checkInDate,
    this.checkOutDate,
    this.estimatedAmount,
    this.paymentOption,
  });

  @override
  Widget build(BuildContext context) {
    final pricePeriod = property.pricePeriodLabel;
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          'Booking Confirmation',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryblue.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.72, end: 1),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryblue.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: AppTheme.primaryblue,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking request sent',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your request is waiting for the landlord. There is no payment due yet; if approved, you can pay securely from My Bookings.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Property', property.title),
            _buildDetailRow('Location', property.address),
            if (checkInDate != null)
              _buildDetailRow(
                'Start date',
                DateFormat('EEE, d MMM yyyy').format(checkInDate!),
              ),
            if (checkOutDate != null)
              _buildDetailRow(
                'End date',
                DateFormat('EEE, d MMM yyyy').format(checkOutDate!),
              ),
            _buildDetailRow(
              'Price',
              '${ProfileService().currencyConverter(price: property.price.toInt())}${pricePeriod.isEmpty ? '' : ' $pricePeriod'}',
            ),
            if (estimatedAmount != null)
              _buildDetailRow(
                'Estimated payment after approval',
                ProfileService().currencyConverter(price: estimatedAmount!.toInt()),
              ),
            if (paymentOption != null)
              _buildDetailRow(
                'Payment option',
                paymentOption == 'DEPOSIT'
                    ? 'Deposit'
                    : paymentOption == 'HALF'
                        ? 'Half'
                        : 'Full',
              ),
            _buildDetailRow('Landlord', property.landlordName),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryblue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    color: AppTheme.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Builder(builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              ': ',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
