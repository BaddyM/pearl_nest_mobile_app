import 'package:flutter/material.dart';
import 'package:pearlnest/apis/policy_service.dart';

class RefundPolicyNotice extends StatefulWidget {
  const RefundPolicyNotice({super.key, this.bookingStatus});

  final String? bookingStatus;

  @override
  State<RefundPolicyNotice> createState() => _RefundPolicyNoticeState();
}

class _RefundPolicyNoticeState extends State<RefundPolicyNotice> {
  List<RefundTier> _refundTiers = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRefundTiers();
  }

  Future<void> _loadRefundTiers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final policies = await PolicyService.fetchPolicies();
      if (!mounted) return;
      setState(() => _refundTiers = policies.refundTiers);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestedStatus = _normalizeStatus(widget.bookingStatus);
    final tiers = requestedStatus == null
        ? _refundTiers
        : _refundTiers
            .where((tier) => _normalizeStatus(tier.bookingStatus) == requestedStatus)
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blueGrey[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Refund Policy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueGrey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_loadError != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Could not load current refund terms. Retry before proceeding.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _loadRefundTiers,
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (tiers.isNotEmpty)
            ...tiers.map(
              (tier) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_displayStatus(tier.bookingStatus)}: ${_formatPercent(tier.refundPercent)}% refund',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.blueGrey[700],
                  ),
                ),
              ),
            )
          else
            Text(
              'Current refund terms are unavailable right now. Please try again later or check Legal Information before proceeding.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.blueGrey[700],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'By proceeding with the payment, you agree to these terms.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return null;
    return status.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  String _displayStatus(String status) => status
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');

  String _formatPercent(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}
