// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Property property;
  final User user;

  const BookingConfirmationScreen({
    super.key,
    required this.property,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryblue.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppTheme.whiteColor,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Booking Request Sent!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your booking request has been sent to the landlord. You will receive a confirmation shortly.',
                    style: TextStyle(
                      fontSize: 16,
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
            _buildDetailRow('Price', '${ProfileService().currencyConverter(price: property.price.toInt())} ${property.priceType}'),
            _buildDetailRow('Landlord', property.landlordName),
            _buildDetailRow('Contact', property.landlordPhone),
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
