import 'package:flutter/material.dart';
import 'package:pearlnest/apis/refund_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class RefundRequestScreen extends StatefulWidget {
  const RefundRequestScreen({
    super.key,
    required this.propertyName,
    required this.payments,
  });

  final String propertyName;
  final List<Map<String, dynamic>> payments;

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
  String _destinationMethod = 'MOBILE_MONEY';
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Map<String, dynamic>> get _eligiblePayments => widget.payments.where((payment) {
        final status = payment['paymentStatus']?.toString().toUpperCase();
        return status == 'BOOKED' || status == 'APPROVED';
      }).toList();

  @override
  void initState() {
    super.initState();
    final eligible = _eligiblePayments;
    if (eligible.isNotEmpty) {
      _paymentId = eligible.first['id']?.toString();
      _amountController.text = (eligible.first['amount'] as num? ?? 0).toInt().toString();
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
    Map<String, dynamic>? payment;
    for (final item in _eligiblePayments) {
      if (item['id']?.toString() == id) {
        payment = item;
        break;
      }
    }
    setState(() {
      _paymentId = id;
      _amountController.text = ((payment?['amount'] as num?) ?? 0).toInt().toString();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _paymentId == null) return;
    setState(() => _submitting = true);
    try {
      await RefundService.requestRefund(
        paymentId: _paymentId!,
        amount: int.parse(_amountController.text.trim()),
        reason: _reasonController.text.trim(),
        destinationMethod: _destinationMethod,
        destinationName: _nameController.text.trim(),
        destinationAccount: _accountController.text.trim(),
        destinationProvider: _providerController.text.trim(),
      );
      if (!mounted) return;
      _reasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request sent to the landlord for review.')),
      );
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
              'The landlord reviews your request first, then an administrator makes the final decision. Approved refunds are paid manually to the destination you provide.',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context), height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_eligiblePayments.isEmpty)
              _messageCard('No completed payments are available to request a refund for.')
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _paymentId,
                      decoration: const InputDecoration(labelText: 'Completed payment'),
                      items: _eligiblePayments.map((payment) {
                        final amount = (payment['amount'] as num? ?? 0).toInt();
                        final date = payment['createdAt']?.toString().split('T').first ?? '';
                        return DropdownMenuItem(
                          value: payment['id']?.toString(),
                          child: Text('UGX $amount · $date', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _selectPayment,
                      validator: (value) => value == null ? 'Choose a completed payment.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Requested refund amount (UGX)'),
                      validator: (value) {
                        final amount = int.tryParse(value ?? '');
                        if (amount == null || amount <= 0) return 'Enter a whole amount greater than zero.';
                        final selected = _eligiblePayments.where((payment) => payment['id']?.toString() == _paymentId);
                        if (selected.isNotEmpty && amount > (selected.first['amount'] as num? ?? 0)) {
                          return 'Refund cannot exceed this payment.';
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
                      onPressed: _submitting ? null : _submit,
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
        title: Text('UGX ${request['amount'] ?? 0} · $status', style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600)),
        subtitle: Text('$destination\n${request['reason'] ?? ''}', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        isThreeLine: true,
      ),
    );
  }

  Widget _messageCard(String message) => Card(
        color: AppTheme.getCardColor(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(message, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        ),
      );
}
