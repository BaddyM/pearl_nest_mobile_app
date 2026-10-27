import 'package:flutter/material.dart';
import 'package:pearlnest/apis/payment_service.dart';
import 'package:pearlnest/apis/withdrawal_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class LandlordWalletScreen extends StatefulWidget {
  const LandlordWalletScreen({super.key});

  @override
  State<LandlordWalletScreen> createState() => _LandlordWalletScreenState();
}

class _LandlordWalletScreenState extends State<LandlordWalletScreen> {
  Map<String, dynamic>? _wallet;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await PaymentService.getLandlordWallet();
      if (mounted) setState(() => _wallet = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _amount(dynamic value) => value is num ? value.toInt() : 0;

  String _formatAmount(dynamic amount) =>
      'UGX ${_amount(amount).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

  String _formatMonth(String? value) {
    if (value == null) return 'Month unavailable';
    final date = DateTime.tryParse('$value-01');
    if (date == null) return value;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showWithdrawalRequest(int availableAmount) async {
    final amountController = TextEditingController();
    final nameController = TextEditingController();
    final accountController = TextEditingController();
    final providerController = TextEditingController();
    var method = 'MOBILE_MONEY';
    var isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    final requested = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Request withdrawal',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Available: ${_formatAmount(availableAmount)}. Requests reserve funds until the administrator approves or rejects them. Approved transfers are paid manually.',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (UGX)'),
                    validator: (value) {
                      final amount = int.tryParse(value ?? '');
                      if (amount == null || amount <= 0) return 'Enter a whole amount greater than zero.';
                      if (amount > availableAmount) return 'Amount exceeds your available balance.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Payout method'),
                    items: const [
                      DropdownMenuItem(value: 'MOBILE_MONEY', child: Text('Mobile money')),
                      DropdownMenuItem(value: 'BANK', child: Text('Bank transfer')),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => method = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Account holder name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter the account holder name.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: method == 'BANK' ? 'Bank account number' : 'Mobile money number',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter the account details.' : null,
                  ),
                  if (method == 'BANK') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: providerController,
                      decoration: const InputDecoration(labelText: 'Bank name'),
                      validator: (value) => method == 'BANK' && (value == null || value.trim().isEmpty)
                          ? 'Enter the bank name.'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final amount = int.parse(amountController.text.trim());
                            setSheetState(() => isSubmitting = true);
                            try {
                              await WithdrawalService.requestWithdrawal(
                                amount: amount,
                                destinationMethod: method,
                                destinationName: nameController.text.trim(),
                                destinationAccount: accountController.text.trim(),
                                destinationProvider: method == 'BANK'
                                    ? providerController.text.trim()
                                    : null,
                              );
                              if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                            } catch (error) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              }
                            } finally {
                              if (sheetContext.mounted) {
                                setSheetState(() => isSubmitting = false);
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit withdrawal request'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    amountController.dispose();
    nameController.dispose();
    accountController.dispose();
    providerController.dispose();
    if (requested == true) await _loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    final data = _wallet ?? {};
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    final monthly = (data['monthly'] as List<dynamic>? ?? []).whereType<Map>().toList();
    final activity = (data['activity'] as List<dynamic>? ?? []).whereType<Map>().toList();
    final withdrawals = (data['withdrawals'] as List<dynamic>? ?? []).whereType<Map>().toList();
    final availableToWithdraw = _amount(summary['availableForWithdrawal']);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Wallet & earnings'),
        backgroundColor: AppTheme.primaryblue,
        foregroundColor: Colors.white,
      ),
      body: _loading && _wallet == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _wallet == null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _loadWallet,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryblue, Color(0xFF208B73)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available to withdraw', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(
                              _formatAmount(availableToWithdraw),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_formatAmount(summary['grossPayments'])} paid  ·  ${_formatAmount(summary['commission'])} platform commission',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              '${_formatAmount(summary['refunds'])} refunds completed',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'After commission and completed refunds. Pending and approved requests reserve funds; paid withdrawals are deducted.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: availableToWithdraw > 0
                            ? () => _showWithdrawalRequest(availableToWithdraw)
                            : null,
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Request withdrawal'),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Withdrawal requests'),
                      const SizedBox(height: 10),
                      if (withdrawals.isEmpty)
                        _emptyCard('Your withdrawal requests will appear here.')
                      else
                        ...withdrawals.map((entry) {
                          final item = Map<String, dynamic>.from(entry);
                          final status = item['status']?.toString() ?? 'PENDING';
                          final method = item['destinationMethod'] == 'BANK' ? 'Bank transfer' : 'Mobile money';
                          return Card(
                            color: AppTheme.getCardColor(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                status == 'PAID'
                                    ? Icons.check_circle_outline
                                    : status == 'REJECTED'
                                        ? Icons.cancel_outlined
                                        : Icons.hourglass_top,
                                color: status == 'PAID'
                                    ? AppTheme.primaryblue
                                    : status == 'REJECTED'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                              title: Text(
                                '${_formatAmount(item['amount'])} · $status',
                                style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '$method · ${item['destinationName'] ?? ''} · ${item['destinationAccount'] ?? ''}${item['transferReference'] == null ? '' : ' · Ref ${item['transferReference']}'}${item['adminNote'] == null ? '' : ' · ${item['adminNote']}'}',
                                style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      _sectionTitle('Monthly earnings'),
                      const SizedBox(height: 10),
                      if (monthly.isEmpty)
                        _emptyCard('No confirmed payments have been recorded yet.')
                      else
                        ...monthly.map((item) {
                          final month = Map<String, dynamic>.from(item);
                          return Card(
                            color: AppTheme.getCardColor(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatMonth(month['month']?.toString()),
                                          style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text(
                                        _formatAmount(month['netEarnings']),
                                        style: const TextStyle(color: AppTheme.primaryblue, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Paid ${_formatAmount(month['grossPayments'])}  ·  Net commission ${_formatAmount(_amount(month['commission']) - _amount(month['commissionReversed']))}  ·  Refunded ${_formatAmount(month['refunds'])}',
                                      style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      _sectionTitle('Recent wallet activity'),
                      const SizedBox(height: 10),
                      if (activity.isEmpty)
                        _emptyCard('Payments and completed refunds will appear here.')
                      else
                        ...activity.take(30).map((entry) {
                          final item = Map<String, dynamic>.from(entry);
                          final isRefund = item['type'] == 'REFUND';
                          final isWithdrawal = item['type'] == 'WITHDRAWAL';
                          final withdrawalStatus = item['status']?.toString() ?? 'PENDING';
                          var activityDescription = '';
                          if (isWithdrawal) {
                            activityDescription = item['destinationMethod'] == 'BANK'
                                ? 'Bank transfer'
                                : 'Mobile money';
                            if (item['transferReference'] != null) {
                              activityDescription += ' · Ref ${item['transferReference']}';
                            }
                          } else if (isRefund) {
                            activityDescription =
                                'Refund paid ${_formatAmount(item['amount'])}; commission returned ${_formatAmount(item['commissionReversed'])}';
                          } else {
                            activityDescription =
                                'Payment confirmed · Commission ${_formatAmount(item['commissionAmount'])}';
                          }
                          final activityColor = isRefund
                              ? Colors.orange
                              : isWithdrawal
                                  ? withdrawalStatus == 'REJECTED'
                                      ? Colors.red
                                      : withdrawalStatus == 'PAID'
                                          ? AppTheme.primaryblue
                                          : Colors.orange
                                  : AppTheme.primaryblue;
                          final date = DateTime.tryParse(item['date']?.toString() ?? '');
                          return Card(
                            color: AppTheme.getCardColor(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: activityColor.withValues(alpha: 0.12),
                                child: Icon(
                                  isRefund
                                      ? Icons.currency_exchange
                                      : isWithdrawal
                                          ? Icons.account_balance_wallet_outlined
                                          : Icons.payments_outlined,
                                  color: activityColor,
                                ),
                              ),
                              title: Text(
                                isWithdrawal
                                    ? 'Withdrawal $withdrawalStatus'
                                    : item['propertyName']?.toString() ?? 'Property payment',
                                style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '$activityDescription${date == null ? '' : ' · ${date.day}/${date.month}/${date.year}'}',
                                style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                              ),
                              trailing: Text(
                                isWithdrawal
                                    ? withdrawalStatus == 'PAID'
                                        ? '-${_formatAmount(item['amount'])}'
                                        : withdrawalStatus == 'REJECTED'
                                            ? _formatAmount(item['amount'])
                                            : 'Reserved\n${_formatAmount(item['amount'])}'
                                    : '${isRefund ? '-' : '+'}${_formatAmount(isRefund ? item['walletImpact'] : item['amount'])}',
                                textAlign: TextAlign.end,
                                style: TextStyle(color: activityColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold),
      );

  Widget _emptyCard(String message) => Card(
        color: AppTheme.getCardColor(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Wallet could not be loaded.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextColor(context))),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadWallet, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
