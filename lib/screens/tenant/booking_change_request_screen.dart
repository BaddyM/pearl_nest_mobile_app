import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class BookingChangeRequestScreen extends StatefulWidget {
  const BookingChangeRequestScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingChangeRequestScreen> createState() =>
      _BookingChangeRequestScreenState();
}

class _BookingChangeRequestScreenState
    extends State<BookingChangeRequestScreen> {
  DateTimeRange? _dates;
  String _paymentOption = 'FULL';
  bool _submitting = false;

  bool get _isShortStay =>
      widget.booking.bookingPurpose?.toUpperCase() == 'SHORT_STAY';

  @override
  void initState() {
    super.initState();
    final existingOption = widget.booking.paymentOption?.toUpperCase();
    if (['DEPOSIT', 'HALF', 'FULL'].contains(existingOption)) {
      _paymentOption = existingOption!;
    }
  }

  Future<void> _selectDates() async {
    final today = DateTime.now();
    final existingStart = widget.booking.startDate;
    final existingEnd = widget.booking.endDate;
    final initialStart = existingStart != null &&
            !existingStart.isBefore(DateTime(today.year, today.month, today.day))
        ? existingStart
        : null;
    final initialEnd = initialStart != null &&
            existingEnd != null &&
            existingEnd.isAfter(initialStart)
        ? existingEnd
        : null;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 3, today.month, today.day),
      initialDateRange: initialStart != null && initialEnd != null
          ? DateTimeRange(start: initialStart, end: initialEnd)
          : null,
      helpText: 'Choose your requested dates',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primaryblue,
              ),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _dates = selected);
    }
  }

  Future<void> _submit() async {
    final dates = _dates;
    if (dates == null || dates.end.isAtSameMomentAs(dates.start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the dates you are requesting.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await BookingService.requestBookingChange(
        bookingId: widget.booking.id,
        checkInDate: dates.start,
        checkOutDate: dates.end,
        paymentOption: _paymentOption,
      );
      if (!mounted) return;
      final indicativeTotal = result['indicativeTotalAmount'];
      final amountMessage = indicativeTotal is num
          ? ' An indicative total is UGX ${NumberFormat('#,##0').format(indicativeTotal)}; the final quote will be confirmed by the landlord.'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Change request sent.$amountMessage Your current booking remains unchanged until you accept an offer.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send the change request: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dates;
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Request a booking change'),
        backgroundColor: AppTheme.primaryblue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) => Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - progress)),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.propertyTitle,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the dates you would like instead. The landlord must approve your request, then you can review the new quote before anything changes.',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range, color: AppTheme.primaryblue),
              title: Text(
                dates == null
                    ? 'Select check-in and check-out'
                    : '${DateFormat.yMMMd().format(dates.start)} – ${DateFormat.yMMMd().format(dates.end)}',
              ),
              subtitle: dates == null
                  ? const Text('Your current booking will stay in place.')
                  : Text('${dates.end.difference(dates.start).inDays} nights'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _submitting ? null : _selectDates,
            ),
          ),
          if (_isShortStay) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentOption,
              decoration: const InputDecoration(
                labelText: 'Payment option for the updated quote',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'DEPOSIT', child: Text('20% deposit')),
                DropdownMenuItem(value: 'HALF', child: Text('Half payment')),
                DropdownMenuItem(value: 'FULL', child: Text('Full payment')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _paymentOption = value);
                      }
                    },
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'A higher total will leave an additional balance to pay. If the total goes down and you have already paid more than the new total, you can submit a separate refund request under the applicable refund policy. Pearl Nest does not arrange travel insurance.',
              style: TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_submitting ? 'Sending request…' : 'Send change request'),
          ),
        ],
      ),
    );
  }
}
