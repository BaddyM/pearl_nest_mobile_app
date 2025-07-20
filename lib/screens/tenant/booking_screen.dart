import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_event.dart';
import 'package:pearlnest/blocs/booking/booking_state.dart';

class BookingScreen extends StatefulWidget {
  final Property property;
  final User user;

  const BookingScreen({
    super.key,
    required this.property,
    required this.user,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Book Property',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccess) {
            _showSuccessDialog(state.message);
          } else if (state is BookingFailure) {
            _showErrorSnackBar(state.error);
          } else if (state is BookingValidationError) {
            _showValidationErrors(state.fieldErrors);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, 
                             color: AppTheme.primaryblue, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.property.address,
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UGX ${widget.property.price.toStringAsFixed(0)} ${widget.property.priceType}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Select Your Dates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Check-in date
              _buildDateSelector(
                context,
                title: 'Check-in Date',
                date: _checkInDate,
                onTap: () => _selectCheckInDate(context),
              ),
              
              const SizedBox(height: 12),
              
              // Check-out date
              _buildDateSelector(
                context,
                title: 'Check-out Date',
                date: _checkOutDate,
                onTap: () => _selectCheckOutDate(context),
              ),
              
              if (_checkInDate != null && _checkOutDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        '${_checkOutDate!.difference(_checkInDate!).inDays} nights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryblue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Book button
              BlocBuilder<BookingBloc, BookingState>(
                builder: (context, state) {
                  final isLoading = state is BookingLoading;
                  final canBook = _checkInDate != null && 
                                  _checkOutDate != null && 
                                  !isLoading;
                  
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canBook ? _submitBooking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryblue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Book Now',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context, {
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.lightGreyColor),
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.getCardColor(context),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, 
                 color: AppTheme.primaryblue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null 
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: date != null 
                        ? AppTheme.getTextColor(context)
                        : AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, 
                 color: AppTheme.getSecondaryTextColor(context), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryblue,
              onPrimary: AppTheme.whiteColor,
              surface: AppTheme.getCardColor(context),
              onSurface: AppTheme.getTextColor(context),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        // Reset checkout date if it's before the new checkin date
        if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime minDate = _checkInDate?.add(const Duration(days: 1)) ?? 
                            DateTime.now().add(const Duration(days: 2));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryblue,
              onPrimary: AppTheme.whiteColor,
              surface: AppTheme.getCardColor(context),
              onSurface: AppTheme.getTextColor(context),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  void _submitBooking() {
    if (_checkInDate == null || _checkOutDate == null) {
      return;
    }

    // Format dates as ISO 8601 strings for API
    final checkInFormatted = DateFormat('yyyy-MM-dd').format(_checkInDate!);
    final checkOutFormatted = DateFormat('yyyy-MM-dd').format(_checkOutDate!);

    context.read<BookingBloc>().add(BookingCreateRequested(
      propertyId: widget.property.id,
      checkInDate: checkInFormatted,
      checkOutDate: checkOutFormatted,
    ));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.orange, // Changed from green to orange
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pending_actions, // Changed from check to pending icon
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking Created!', // Changed from "Booking Successful!"
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking has been created and is pending payment. Please complete the payment to secure your reservation.',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Add payment reminder container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payment,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment required to complete booking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (_checkInDate != null && _checkOutDate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Check-in:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_checkInDate!),
                          style: const TextStyle(
                            color: AppTheme.primaryblue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Check-out:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_checkOutDate!),
                          style: const TextStyle(
                            color: AppTheme.primaryblue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Go back to previous screen with success result
                context.read<BookingBloc>().add(const BookingReset());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Changed to orange to indicate next action is payment
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Proceed to Payment', // Changed button text to be more actionable
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showValidationErrors(Map<String, String> errors) {
    final errorMessage = errors.values.join('\n');
    _showErrorSnackBar(errorMessage);
  }
}
