import 'package:flutter/material.dart';

class RefundPolicyNotice extends StatelessWidget {
  const RefundPolicyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50], // Professional, neutral tone
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
                "Refund Policy",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueGrey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "• Payments for bookings are refundable within 7-14 days .\n"
            "• A 5% processing fee applies to all cancellations.\n"
            "• Refunds take 3–5 business days to reflect in your account.",
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "By proceeding with the payment, you agree to these terms.",
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
}
