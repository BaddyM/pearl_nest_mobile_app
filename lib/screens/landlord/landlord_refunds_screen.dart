import 'package:flutter/material.dart';
import 'package:pearlnest/apis/refund_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/services/profile_service.dart';

class LandlordRefundsScreen extends StatefulWidget {
  const LandlordRefundsScreen({super.key});

  @override
  State<LandlordRefundsScreen> createState() => _LandlordRefundsScreenState();
}

class _LandlordRefundsScreenState extends State<LandlordRefundsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await RefundService.getLandlordRequests();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(Map<String, dynamic> request, String decision) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(decision == 'APPROVE' ? 'Recommend approval' : 'Recommend rejection'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: decision == 'REJECT' ? 'Reason (required)' : 'Note for the administrator (optional)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (decision == 'REJECT' && controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Send recommendation'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || (decision == 'REJECT' && note.isEmpty)) return;

    final id = request['id']?.toString();
    if (id == null) return;
    setState(() => _busyId = id);
    try {
      await RefundService.reviewAsLandlord(
        requestId: id,
        decision: decision,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recommendation sent to the administrator for the final decision.')),
      );
      await _loadRequests();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send recommendation: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Refund requests'),
        backgroundColor: AppTheme.primaryblue,
        foregroundColor: Colors.white,
      ),
      body: _loading && _requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _requests.isEmpty
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: _requests.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Center(child: Text('No refund requests for your properties.', style: TextStyle(color: AppTheme.getSecondaryTextColor(context)))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) => _requestCard(_requests[index]),
                        ),
                ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final tenant = request['user'] is Map ? Map<String, dynamic>.from(request['user'] as Map) : <String, dynamic>{};
    final property = request['property'] is Map ? Map<String, dynamic>.from(request['property'] as Map) : <String, dynamic>{};
    final status = request['status']?.toString() ?? 'UNKNOWN';
    final canReview = status == 'PENDING_LANDLORD';
    final destinationType = request['destinationMethod'] == 'BANK' ? 'Bank account' : 'Mobile money';
    final busy = _busyId == request['id']?.toString();
    return Card(
      color: AppTheme.getCardColor(context),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(property['propertyName']?.toString() ?? 'Property', style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16))),
                Chip(
                  label: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                  backgroundColor: status == 'COMPLETED' ? Colors.green.withValues(alpha: 0.12) : AppTheme.primaryblue.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tenant: ${tenant['name'] ?? 'Unknown'} · ${tenant['email'] ?? ''}', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            Text(
              'Request: ${ProfileService().currencyConverter(price: ((request['amount'] as num?) ?? 0).toInt())}',
              style: TextStyle(color: AppTheme.primaryblue, fontWeight: FontWeight.bold),
            ),
            Text('Destination: $destinationType · ${request['destinationName'] ?? ''} · ${request['destinationProvider'] ?? ''} ${request['destinationAccount'] ?? ''}', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            const SizedBox(height: 8),
            Text('Reason', style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600)),
            Text(request['reason']?.toString() ?? '', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            if (request['adminNote'] != null) ...[
              const SizedBox(height: 8),
              Text('Admin decision: ${request['adminNote']}', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            ],
            if (canReview) ...[
              const SizedBox(height: 14),
              Text('Your response is a recommendation. The administrator makes the final decision and can decide before your review.', style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _review(request, 'REJECT'),
                      child: const Text('Recommend rejection'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _review(request, 'APPROVE'),
                      child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Recommend approval'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Refund requests could not be loaded.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextColor(context))),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadRequests, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
