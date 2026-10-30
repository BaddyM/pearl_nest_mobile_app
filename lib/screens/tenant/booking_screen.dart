import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/apis/payment_service.dart';
import 'package:pearlnest/screens/tenant/bookings_list_screen.dart';
import 'package:pearlnest/screens/tenant/booking_confirmation_screen.dart';
import 'package:pearlnest/screens/tenant/payment_screen.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final Property property;
  final User user;
  final bool isViewingRequest;

  const BookingScreen({
    super.key,
    required this.property,
    required this.user,
    this.isViewingRequest = false,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _noMoveOutDate = true;
  String _paymentOption = 'DEPOSIT';
  Map<String, dynamic>? _bookingQuote;
  bool _quoteLoading = false;
  bool _isSubmitting = false;
  late final TextEditingController _contactNumberController;

  bool get _isSale => widget.property.isSale || widget.property.priceType.toLowerCase() == 'for_sale';
  bool get _isViewingRequest => widget.isViewingRequest || _isSale;
  bool get _isShortStay =>
      widget.property.pricePeriodLabel == '/ night' ||
      widget.property.type.toLowerCase().contains('air');
  bool get _isLongTermRental =>
      !_isSale &&
      !_isShortStay &&
      widget.property.isRent &&
      (widget.property.pricePeriodLabel == '/ month' ||
          widget.property.type.toLowerCase() == 'rentals');

  @override
  void initState() {
    super.initState();
    _contactNumberController = TextEditingController(text: widget.user.phone);
    if (_isViewingRequest) _loadBookingQuote();
  }

  @override
  void dispose() {
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingQuote() async {
    if (!_isViewingRequest &&
        (_checkInDate == null ||
            (!_isLongTermRental || !_noMoveOutDate) && _checkOutDate == null)) return;
    setState(() {
      _quoteLoading = true;
      _bookingQuote = null;
    });
    try {
      final quote = await BookingService.getBookingQuote(
        propertyId: widget.property.id,
        checkInDate: _checkInDate == null ? null : DateFormat('yyyy-MM-dd').format(_checkInDate!),
        checkOutDate: _checkOutDate == null ? null : DateFormat('yyyy-MM-dd').format(_checkOutDate!),
        paymentOption: _paymentOption,
        isViewing: _isViewingRequest,
      );
      if (mounted) setState(() => _bookingQuote = quote);
    } catch (error) {
      if (mounted) _showErrorSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

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
          _isViewingRequest ? 'Request a Tour' : 'Request Booking',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryblue.withValues(alpha: 0.13),
                        AppTheme.getCardColor(context),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryblue.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryblue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _isViewingRequest ? Icons.visibility_outlined : Icons.home_work_outlined,
                          color: AppTheme.primaryblue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.property.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.primaryblue),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    widget.property.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${ProfileService().currencyConverter(price: widget.property.price.toInt())} ${widget.property.pricePeriodLabel}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryblue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  _isViewingRequest ? 'Plan your property tour' : 'Choose your stay',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isViewingRequest
                      ? 'Choose a convenient date. The admin-set visit fee is paid to Pearl Nest before your request is sent.'
                      : _isLongTermRental
                          ? 'Choose your move-in date. Your move-out date can be left open-ended.'
                          : 'Select arrival and departure dates to see your price.',
                  style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                ),
                const SizedBox(height: 18),
                _buildDateSelector(
                  context,
                  title: _isViewingRequest
                      ? 'Preferred tour date'
                      : _isLongTermRental ? 'Move-in date' : 'Check-in',
                  date: _checkInDate,
                  onTap: () => _selectCheckInDate(context),
                ),
                if (_isViewingRequest) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppTheme.getTextColor(context)),
                    decoration: InputDecoration(
                      labelText: 'Phone number for the callback',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryblue),
                      filled: true,
                      fillColor: AppTheme.getCardColor(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pay the property visit fee to submit this request. It does not reserve the property; the landlord will call to arrange a time.',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ],
                if (!_isViewingRequest) ...[
                  if (_isLongTermRental)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _noMoveOutDate,
                      title: const Text("I don't know my move-out date yet"),
                      subtitle: const Text(
                        'The landlord will confirm the lease duration and notice terms.',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _noMoveOutDate = value ?? false;
                          if (_noMoveOutDate) _checkOutDate = null;
                        });
                        _loadBookingQuote();
                      },
                    ),
                  if (!_isLongTermRental || !_noMoveOutDate) ...[
                    const SizedBox(height: 10),
                    _buildDateSelector(
                      context,
                      title: _isLongTermRental ? 'Estimated move-out date' : 'Check-out',
                      date: _checkOutDate,
                      onTap: () => _selectCheckOutDate(context),
                    ),
                  ],
                ],
                if (_checkInDate != null &&
                    _checkOutDate != null &&
                    !_isViewingRequest &&
                    _isShortStay) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.nights_stay_outlined, color: AppTheme.primaryblue),
                        const SizedBox(width: 10),
                        Text(
                          '${_checkOutDate!.difference(_checkInDate!).inDays} nights selected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (_bookingQuote != null)
                  _buildQuoteSummary(context)
                else if (_quoteLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildQuotePrompt(context),
              ],
            ),
          ),
        ),
      bottomNavigationBar:
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.getBackgroundColor(context),
                border: Border(
                  top: BorderSide(color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.15)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submitBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryblue,
                    disabledBackgroundColor: AppTheme.primaryblue.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isViewingRequest
                              ? 'Pay visit fee & request viewing'
                              : 'Send booking request',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
    );
  }

  bool get _canSubmit =>
      _checkInDate != null &&
      (_isViewingRequest ||
          (_isLongTermRental && _noMoveOutDate) ||
          _checkOutDate != null) &&
      _bookingQuote != null &&
      !_isSubmitting &&
      !_quoteLoading;

  Widget _buildQuotePrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryblue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isViewingRequest
                  ? 'The property visit fee is calculated from the admin-set rate.'
                  : 'Choose your dates to see the booking estimate. Payment is only due after the landlord approves your request.',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSummary(BuildContext context) {
    final quote = _bookingQuote!;
    final choices = (quote['paymentOptions'] as List<dynamic>? ?? []).cast<String>();
    final amountDueNow = (quote['amountDueNow'] as num? ?? 0).toInt();
    final baseAmount = (quote['baseAmount'] as num? ?? 0).toInt();
    final visitFee = (quote['visitFeeAmount'] as num? ?? baseAmount).toInt();
    final totalAmount = (quote['totalAmount'] as num? ?? amountDueNow).toInt();
    final bookingFee = (quote['bookingFeeAmount'] as num? ?? 0).toInt();
    final originalBaseAmount =
        (quote['originalBaseAmount'] as num? ?? baseAmount + (quote['propertyDiscountAmount'] as num? ?? 0)).toInt();
    final propertyDiscount =
        (quote['propertyDiscountAmount'] as num? ?? 0).toInt();
    final originalBookingFee =
        (quote['originalBookingFeeAmount'] as num? ?? bookingFee + (quote['bookingFeeDiscountAmount'] as num? ?? 0)).toInt();
    final bookingFeeDiscount =
        (quote['bookingFeeDiscountAmount'] as num? ?? 0).toInt();
    final transactionFee = (quote['transactionFeeAmount'] as num? ?? 0).toInt();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryblue.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryblue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isViewingRequest ? 'Property visit fee' : 'Your booking estimate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          if (!_isViewingRequest) ...[
            const SizedBox(height: 6),
            Text(
              'No payment is due while your request is waiting for approval.',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                height: 1.35,
              ),
            ),
          ],
          if (choices.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in const ['DEPOSIT', 'HALF', 'FULL'])
                  if (choices.contains(option))
                    ChoiceChip(
                      label: Text(option == 'DEPOSIT' ? '20% deposit' : option == 'HALF' ? 'Half' : 'Full'),
                      selected: _paymentOption == option,
                      selectedColor: AppTheme.primaryblue.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                        color: _paymentOption == option
                            ? AppTheme.primaryblue
                            : AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: _paymentOption == option
                            ? AppTheme.primaryblue
                            : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.2),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _paymentOption = option);
                          _loadBookingQuote();
                        }
                      },
                    ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (!_isViewingRequest) ...[
            if (_isLongTermRental && quote['advanceRentMonths'] != null) ...[
              _buildQuoteRow(
                context,
                'Advance rent (${quote['advanceRentMonths']} months)',
                ProfileService().currencyConverter(
                  price: (quote['advanceRentAmount'] as num? ?? 0).toInt(),
                ),
              ),
              const SizedBox(height: 7),
              _buildQuoteRow(
                context,
                'Refundable security deposit (${quote['securityDepositMonths'] ?? 0} months)',
                ProfileService().currencyConverter(
                  price: (quote['securityDepositAmount'] as num? ?? 0).toInt(),
                ),
              ),
              const SizedBox(height: 7),
            ] else ...[
              _buildQuoteRow(
                context,
                _isShortStay ? 'Rent for selected dates' : 'Property deposit',
                ProfileService().currencyConverter(price: originalBaseAmount),
              ),
              const SizedBox(height: 7),
            ],
            if (propertyDiscount > 0) ...[
              _buildQuoteRow(
                context,
                'Property promotion',
                '-${ProfileService().currencyConverter(price: propertyDiscount)}',
              ),
              const SizedBox(height: 7),
            ],
          ],
          _buildQuoteRow(
            context,
            _isViewingRequest ? 'Visit fee paid to Pearl Nest' : 'Booking fee',
            ProfileService().currencyConverter(
              price: _isViewingRequest ? visitFee : originalBookingFee,
            ),
          ),
          const SizedBox(height: 7),
          if (!_isViewingRequest && bookingFeeDiscount > 0) ...[
            _buildQuoteRow(
              context,
              'Booking-fee promotion',
              '-${ProfileService().currencyConverter(price: bookingFeeDiscount)}',
            ),
            const SizedBox(height: 7),
          ],
          _buildQuoteRow(
            context,
            'Transaction fee',
            ProfileService().currencyConverter(price: transactionFee),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isViewingRequest ? 'Pay now to request tour' : 'Due now at secure checkout',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ProfileService().currencyConverter(price: amountDueNow),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_user_outlined, color: AppTheme.primaryblue),
              const SizedBox(width: 6),
              Text(
                'Secure\ncheckout',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          if (totalAmount != amountDueNow) ...[
            const SizedBox(height: 10),
            _buildQuoteRow(
              context,
              'Estimated total for the full stay',
              ProfileService().currencyConverter(price: totalAmount),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuoteRow(BuildContext context, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        Text(
          amount,
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? AppTheme.primaryblue.withValues(alpha: 0.55)
                : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.getCardColor(context),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryblue.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryblue, size: 21),
            ),
            const SizedBox(width: 13),
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
                    date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: date != null ? AppTheme.getTextColor(context) : AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.getSecondaryTextColor(context), size: 22),
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
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
      if (!_isViewingRequest) _loadBookingQuote();
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime minDate = _checkInDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 2));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
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
      _loadBookingQuote();
    }
  }

  Future<void> _submitBooking() async {
    if (!_canSubmit || _checkInDate == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final checkInFormatted = DateFormat('yyyy-MM-dd').format(_checkInDate!);

    try {
      late final String bookingId;
      late final double paymentAmount;
      if (_isViewingRequest) {
        final phone = _contactNumberController.text.trim();
        if (phone.length < 7 || phone.length > 30) {
          throw BookingException('Enter a valid phone number for the viewing callback.');
        }
        final result = await BookingService.createViewingRequest(
          propertyId: widget.property.id,
          preferredDate: checkInFormatted,
          contactNumber: phone,
        );
        final booking = result;
        final createdId = booking['id']?.toString();
        if (createdId == null || createdId.isEmpty) {
          throw BookingException('The visit request reference was not returned. Please try again.');
        }
        bookingId = createdId;
        paymentAmount = (booking['amount'] as num?)?.toDouble() ??
            (_bookingQuote!['amountDueNow'] as num).toDouble();
        if (paymentAmount == 0 && mounted) {
          _showSuccessDialog(
            'Your visit request has been sent. The landlord or Pearl Nest team will call to arrange a time.',
          );
          return;
        }
      } else {
        final checkOutFormatted = _checkOutDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_checkOutDate!);
        final result = await BookingService.createBooking(
          propertyId: widget.property.id,
          checkInDate: checkInFormatted,
          checkOutDate: checkOutFormatted,
          deposit: widget.property.deposit.toInt(),
          paymentOption: _paymentOption,
        );
        final response = result['data'];
        final booking = response is Map && response['data'] is Map
            ? Map<String, dynamic>.from(response['data'] as Map)
            : <String, dynamic>{};
        final createdId = booking['id']?.toString();
        if (createdId == null || createdId.isEmpty) {
          throw BookingException('The booking reference was not returned. Please try again.');
        }
        bookingId = createdId;
        paymentAmount = (booking['amount'] as num?)?.toDouble() ??
            (_bookingQuote!['amountDueNow'] as num).toDouble();

        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              property: widget.property,
              user: widget.user,
              checkInDate: _checkInDate,
              checkOutDate: _checkOutDate,
              estimatedAmount: paymentAmount,
              paymentOption: _paymentOption,
            ),
          ),
        );
        return;
      }

      final payment = await PaymentService.createPayment(
        userId: widget.user.id,
        propertyId: widget.property.id,
        bookingId: bookingId,
        amount: paymentAmount,
      );
      final redirectUrl = payment['redirectUrl']?.toString();
      final orderTrackingId = payment['orderTrackingId']?.toString();
      final merchantReference = payment['merchantReference']?.toString();
      if (payment['success'] != true ||
          redirectUrl == null ||
          redirectUrl.isEmpty ||
          orderTrackingId == null ||
          merchantReference == null) {
        await BookingService.cancelBooking(bookingId);
        throw BookingException(
          '${payment['message']?.toString() ?? 'Secure checkout could not be started.'} '
          'The unpaid booking request was cancelled.',
        );
      }

      if (!mounted) return;
      final paymentResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            redirectUrl: redirectUrl,
            orderTrackingId: orderTrackingId,
            merchantReference: merchantReference,
            amount: paymentAmount,
            propertyTitle: widget.property.title,
            user: widget.user,
          ),
        ),
      );
      if (paymentResult != true && mounted) {
        await BookingService.cancelBooking(bookingId);
        _showErrorSnackBar(
          'Payment was not completed. Your unpaid booking request has been cancelled; you can try again.',
        );
      }
    } catch (error) {
      if (mounted) _showErrorSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pending_actions_rounded,
                      color: AppTheme.primaryblue,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isViewingRequest ? 'Tour request sent' : 'Booking request sent',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message.trim().isNotEmpty
                      ? message
                      : _isViewingRequest
                          ? "Your tour request is waiting for the landlord or Pearl Nest team to arrange a time. Review its status in My Bookings."
                          : "Your paid booking request is waiting for the landlord's response. Review its status in My Bookings.",
                  style: TextStyle(
                    height: 1.45,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryblue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryblue,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isViewingRequest
                            ? 'The admin-set visit fee is shown before checkout. Paying it submits a tour request; it does not reserve the property.'
                              : 'Your booking is only confirmed after secure payment succeeds.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppTheme.getTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_checkInDate != null && (_isViewingRequest || _checkOutDate != null)) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.getBackgroundColor(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildConfirmationDateRow(
                          context,
                          _isViewingRequest ? 'Preferred date' : 'Check-in',
                          _checkInDate!,
                        ),
                        if (!_isViewingRequest) ...[
                          const SizedBox(height: 10),
                          _buildConfirmationDateRow(
                            context,
                            'Check-out',
                            _checkOutDate!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (context) => BookingsListScreen(
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      foregroundColor: AppTheme.whiteColor,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'View my bookings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationDateRow(
    BuildContext context,
    String label,
    DateTime date,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
        Text(
          DateFormat('MMM d, yyyy').format(date),
          style: const TextStyle(
            color: AppTheme.primaryblue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
