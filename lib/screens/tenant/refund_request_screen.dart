import 'package:flutter/material.dart';
import 'package:pearlnest/apis/refund_service.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class RefundRequestScreen extends StatefulWidget {
  const RefundRequestScreen({
    super.key,
    required this.propertyName,
    required this.payments,
    this.landlordRejected = false,
    this.administratorReview = false,
  });

  final String propertyName;
  final List<Map<String, dynamic>> payments;
  final bool landlordRejected;
  final bool administratorReview;

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _providerController = TextEditingController();
  String? _paymentId;
  RefundEligibility? _eligibility;
  String? _eligibilityError;
  bool _eligibilityLoading = false;
  int _eligibilityRequestId = 0;
  String _destinationMethod = 'MOBILE_MONEY';
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Map<String, dynamic>> get _payments => widget.payments.where((payment) {
        final id = payment['id']?.toString().trim();
        return id != null && id.isNotEmpty && id != 'null';
      }).toList();

  @override
  void initState() {
    super.initState();
    if (widget.landlordRejected) {
      _reasonController.text = 'Landlord rejected this booking.';
    }
    final payments = _payments;
    if (payments.isNotEmpty) {
      _paymentId = payments.first['id']?.toString();
      if (_paymentId != null) _loadEligibility(_paymentId!);
    }
    _loadRequests();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _nameController.dispose();
    _accountController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await RefundService.getTenantRequests();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectPayment(String? id) {
    setState(() {
      _paymentId = id;
      _eligibility = null;
      _eligibilityError = null;
      _amountController.clear();
    });
    if (id != null && id.isNotEmpty) _loadEligibility(id);
  }

  Future<void> _loadEligibility(String paymentId) async {
    final requestId = ++_eligibilityRequestId;
    if (mounted) {
      setState(() {
        _eligibilityLoading = true;
        _eligibilityError = null;
        _eligibility = null;
      });
    }
    try {
      final eligibility = await RefundService.getEligibility(paymentId);
      if (!mounted || requestId != _eligibilityRequestId) return;
      final requestLimit = eligibility.requestLimit.clamp(0, double.infinity);
      setState(() {
        _eligibility = eligibility;
        _amountController.text =
            requestLimit > 0
                ? ProfileService().fromBaseCurrency(requestLimit).toString()
                : '';
      });
    } catch (error) {
      if (!mounted || requestId != _eligibilityRequestId) return;
      setState(() {
        _eligibilityError = error.toString();
      });
    } finally {
      if (mounted && requestId == _eligibilityRequestId) {
        setState(() => _eligibilityLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _paymentId == null ||
        _eligibility == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await RefundService.requestRefund(
        paymentId: _paymentId!,
        amount: ProfileService().toBaseCurrency(
          int.parse(_amountController.text.trim()),
        ),
        reason: _reasonController.text.trim(),
        destinationMethod: _destinationMethod,
        destinationName: _nameController.text.trim(),
        destinationAccount: _accountController.text.trim(),
        destinationProvider: _providerController.text.trim(),
      );
      if (!mounted) return;
      if (!widget.landlordRejected) _reasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.landlordRejected
                ? 'Your guaranteed full refund is approved and queued for manual payout.'
                : 'Refund request sent to the landlord for review.',
          ),
        ),
      );
      if (_paymentId != null) {
        await _loadEligibility(_paymentId!);
      }
      await _loadRequests();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit refund request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Refund request'),
        backgroundColor: AppTheme.primaryblue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Request a refund for ${widget.propertyName}',
              style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.landlordRejected
                  ? 'Because the landlord rejected this booking, your full remaining payment is guaranteed and approved automatically. Pearl Nest will manually transfer it to the destination you provide.'
                  : widget.administratorReview
                      ? 'This visit fee was paid to Pearl Nest. Administrators review visit-fee refund requests, and approved refunds are paid manually.'
                  : 'The landlord reviews your request first, then an administrator makes the final decision. Approved refunds are paid manually to the destination you provide.',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context), height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_payments.isEmpty)
            _messageCard('No payments are available to request a refund for.')
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _paymentId,
                      decoration: const InputDecoration(labelText: 'Payment'),
                      items: _payments.map((payment) {
                        final amount = _number(payment['amount']).toInt();
                        final date = payment['createdAt']?.toString().split('T').first ?? '';
                        return DropdownMenuItem(
                          value: payment['id']?.toString(),
                          child: Text(
                            '${ProfileService().currencyConverter(price: amount)} · $date',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectPayment,
                      validator: (value) => value == null ? 'Choose a payment.' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_eligibilityLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_eligibilityError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _messageCard(_eligibilityError!),
                          TextButton(
                            onPressed: _paymentId == null
                                ? null
                                : () => _loadEligibility(_paymentId!),
                            child: const Text('Retry eligibility check'),
                          ),
                        ],
                      )
                    else if (_eligibility != null)
                      _eligibilityCard(_eligibility!),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      enabled: _eligibility != null &&
                          !_eligibilityLoading &&
                          _eligibility!.requestLimit > 0,
                      decoration: InputDecoration(
                        labelText: widget.landlordRejected
                            ? 'Guaranteed refund amount (${ProfileService().currencyCode})'
                            : 'Requested refund amount (${ProfileService().currencyCode})',
                        helperText: _eligibility == null
                            ? 'Check payment eligibility to continue.'
                            : widget.landlordRejected
                                ? 'Full remaining balance of this payment.'
                                : 'Available refund: ${ProfileService().currencyConverter(price: _eligibility!.requestLimit.round())}',
                      ),
                      readOnly: widget.landlordRejected,
                      validator: (value) {
                        final displayAmount = int.tryParse(value ?? '');
                        if (displayAmount == null || displayAmount <= 0) return 'Enter a whole amount greater than zero.';
                        final eligibility = _eligibility;
                        if (eligibility == null) {
                          return 'Refund eligibility has not been checked.';
                        }
                        if (ProfileService().toBaseCurrency(displayAmount) > eligibility.requestLimit) {
                          return 'Refund cannot exceed the remaining eligible amount of ${ProfileService().currencyConverter(price: eligibility.requestLimit.round())}.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Why are you requesting a refund?'),
                      validator: (value) => (value?.trim().length ?? 0) < 5 ? 'Please explain your request.' : null,
                    ),
                    const SizedBox(height: 18),
                    Text('Refund destination', style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _destinationMethod,
                      decoration: const InputDecoration(labelText: 'How should the refund be sent?'),
                      items: const [
                        DropdownMenuItem(value: 'MOBILE_MONEY', child: Text('Mobile money')),
                        DropdownMenuItem(value: 'BANK', child: Text('Bank account')),
                      ],
                      onChanged: (value) => setState(() => _destinationMethod = value ?? 'MOBILE_MONEY'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Account holder name'),
                      validator: (value) => value?.trim().isEmpty == true ? 'Enter the account holder name.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(labelText: _destinationMethod == 'BANK' ? 'Bank account number' : 'Mobile money phone number'),
                      validator: (value) => value?.trim().isEmpty == true ? 'Enter the destination account or phone number.' : null,
                    ),
                    if (_destinationMethod == 'BANK') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _providerController,
                        decoration: const InputDecoration(labelText: 'Bank name'),
                        validator: (value) => value?.trim().isEmpty == true ? 'Enter the bank name.' : null,
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _providerController,
                        decoration: const InputDecoration(labelText: 'Mobile money provider (optional)'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: _submitting ||
                              _eligibilityLoading ||
                              _eligibility == null ||
                              _eligibility!.requestLimit <= 0
                          ? null
                          : _submit,
                      child: _submitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit refund request'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            Text('Your refund requests', style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_loading && _requests.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_requests.isEmpty)
              _messageCard(_error ?? 'No refund requests yet.')
            else
              ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final destination = '${request['destinationMethod'] == 'BANK' ? 'Bank' : 'Mobile money'} · ${request['destinationAccount']}';
    final status = request['status']?.toString().replaceAll('_', ' ') ?? 'Unknown';
    return Card(
      color: AppTheme.getCardColor(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${ProfileService().currencyConverter(price: _number(request['amount']).round())} · $status',
          style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$destination\n${request['reason'] ?? ''}', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        isThreeLine: true,
      ),
    );
  }

  Widget _eligibilityCard(RefundEligibility eligibility) {
    final bookingStatus = eligibility.bookingStatus
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .toUpperCase();
    return Card(
      color: AppTheme.primaryblue.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refund eligibility',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _eligibilityRow('Booking status', bookingStatus),
            _eligibilityRow(
              'Refund percentage',
              '${_formatAmount(eligibility.refundPercent)}%',
            ),
            _eligibilityRow(
              'Payment amount',
              ProfileService().currencyConverter(price: eligibility.paymentAmount.round()),
            ),
            _eligibilityRow(
              'Maximum refundable',
              ProfileService().currencyConverter(price: eligibility.maximumRefund.round()),
            ),
            _eligibilityRow(
              'Already requested',
              ProfileService().currencyConverter(price: eligibility.requestedAmount.round()),
            ),
            _eligibilityRow(
              'Remaining available',
              ProfileService().currencyConverter(price: eligibility.remainingRefund.round()),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _eligibilityRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize
                  ? AppTheme.primaryblue
                  : AppTheme.getTextColor(context),
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();

  Widget _messageCard(String message) => Card(
        color: AppTheme.getCardColor(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(message, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        ),
      );
}
