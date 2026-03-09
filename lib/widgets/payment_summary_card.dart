import 'package:flutter/material.dart';
import 'package:pearlnest/services/profile_service.dart';

class PaymentSummaryCard extends StatelessWidget {
  final double subtotal;
  final double vatRate; // e.g., 0.18 for 18%
  final double transactionFee;

  const PaymentSummaryCard({
    super.key,
    required this.subtotal,
    required this.vatRate, // Default VAT for Uganda is 18%
    required this.transactionFee, // Example flat fee
  });

  @override
  Widget build(BuildContext context) {
    double vatAmount = (subtotal * (vatRate / 100));
    double transactionFeeAmount = ((transactionFee / 100) * subtotal);
    double total = subtotal + vatAmount + transactionFeeAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Property Price", subtotal),
          _buildSummaryRow("VAT (${(vatRate)}%)", vatAmount),
          _buildSummaryRow("Transaction Fee (${(transactionFee)}%)", transactionFeeAmount),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                ProfileService().currencyConverter(price: total.toInt()),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            ProfileService().currencyConverter(price: amount.toInt()),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
