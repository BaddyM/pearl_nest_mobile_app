import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/screens/tenant/bookings_list_screen.dart';
import 'package:pearlnest/services/profile_service.dart';
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
  String _paymentOption = 'DEPOSIT';
  Map<String, dynamic>? _bookingQuote;
  bool _quoteLoading = false;

  bool get _isSale => widget.property.isSale || widget.property.priceType.toLowerCase() == 'for_sale';

  @override
  void initState() {
    super.initState();
    if (_isSale) _loadBookingQuote();
  }

  Future<void> _loadBookingQuote() async {
    if (!_isSale && (_checkInDate == null || _checkOutDate == null)) return;
    setState(() {
      _quoteLoading = true;
      _bookingQuote = null;
    });
    try {
      final quote = await BookingService.getBookingQuote(
        propertyId: widget.property.id,
        checkInDate: _checkInDate == null ? null : DateFormat('yyyy-MM-dd').format(_checkInDate!),
        checkOutDate: _isSale
            ? null
            : _checkOutDate == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_checkOutDate!),
        paymentOption: _paymentOption,
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
          _isSale ? 'Request a Viewing' : 'Request Booking',
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
        child: SafeArea(
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
                          _isSale ? Icons.visibility_outlined : Icons.home_work_outlined,
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
                              '${ProfileService().currencyConverter(price: widget.property.price.toInt())} ${widget.property.priceType}',
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
                  _isSale ? 'Plan your property viewing' : 'Choose your stay',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isSale
                      ? 'Choose a convenient date to visit this property.'
                      : 'Select arrival and departure dates to see your price.',
                  style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                ),
                const SizedBox(height: 18),
                _buildDateSelector(
                  context,
                  title: _isSale ? 'Preferred viewing date' : 'Check-in',
                  date: _checkInDate,
                  onTap: () => _selectCheckInDate(context),
                ),
                if (!_isSale) ...[
                  const SizedBox(height: 10),
                  _buildDateSelector(
                    context,
                    title: 'Check-out',
                    date: _checkOutDate,
                    onTap: () => _selectCheckOutDate(context),
                  ),
                ],
                if (_checkInDate != null && _checkOutDate != null && !_isSale) ...[
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
      ),
      bottomNavigationBar: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          final isLoading = state is BookingLoading;
          final canBook = _checkInDate != null &&
              (_isSale || _checkOutDate != null) &&
              _bookingQuote != null &&
              !isLoading &&
              !_quoteLoading;
          return SafeArea(
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
                  onPressed: canBook ? _submitBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryblue,
                    disabledBackgroundColor: AppTheme.primaryblue.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isSale ? 'Request a viewing' : 'Send booking request',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
              _isSale ? 'Your viewing fee will appear here.' : 'Choose your dates to see the booking total.',
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
    final totalAmount = (quote['totalAmount'] as num? ?? amountDueNow).toInt();
    final bookingFee = (quote['bookingFeeAmount'] as num? ?? 0).toInt();
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
            _isSale ? 'Viewing fee estimate' : 'Your booking estimate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
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
          if (!_isSale) ...[
            _buildQuoteRow(
              context,
              widget.property.priceType.toLowerCase().contains('night')
                  ? 'Rent for selected dates'
                  : 'Property deposit',
              ProfileService().currencyConverter(price: baseAmount),
            ),
            const SizedBox(height: 7),
          ],
          _buildQuoteRow(
            context,
            _isSale ? 'Viewing fee' : 'Booking fee',
            ProfileService().currencyConverter(price: bookingFee),
          ),
          const SizedBox(height: 7),
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
                      'Due after landlord approval',
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
      if (_isSale) {
        _checkOutDate = picked;
      }
      _loadBookingQuote();
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

  void _submitBooking() {
    if (_checkInDate == null || (!_isSale && _checkOutDate == null)) {
      return;
    }

    // Format dates as ISO 8601 strings for API
    final checkInFormatted = DateFormat('yyyy-MM-dd').format(_checkInDate!);
    final checkOutFormatted = DateFormat('yyyy-MM-dd').format(_isSale ? _checkInDate! : _checkOutDate!);

    context.read<BookingBloc>().add(BookingCreateRequested(
          propertyId: widget.property.id,
          checkInDate: checkInFormatted,
          checkOutDate: checkOutFormatted,
          deposit: widget.property.deposit.toInt(),
          paymentOption: _paymentOption,
        ));
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
                  _isSale ? 'Viewing request sent' : 'Booking request sent',
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
                      : _isSale
                          ? "Your viewing request is waiting for the landlord's response. Review its status in My Bookings."
                          : "Your request is waiting for the landlord's response. You can review its status in My Bookings. If it is approved, complete payment there to confirm your reservation.",
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
                          _isSale
                              ? 'Any viewing fee is only due after the landlord approves your request.'
                              : 'No payment is due until the landlord approves your request.',
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
                if (_checkInDate != null && (_isSale || _checkOutDate != null)) ...[
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
                          _isSale ? 'Preferred date' : 'Check-in',
                          _checkInDate!,
                        ),
                        if (!_isSale) ...[
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
