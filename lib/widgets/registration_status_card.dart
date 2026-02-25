import 'package:flutter/material.dart';

enum RegistrationStatus {
  pending,
  approved,
  rejected,
  processing;

  // Add this static method to handle the conversion
  static RegistrationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return RegistrationStatus.approved;
      case 'rejected':
        return RegistrationStatus.rejected;
      case 'processing':
        return RegistrationStatus.processing;
      case 'pending':
      default:
        return RegistrationStatus.pending;
    }
  }
}

class RegistrationStatusCard extends StatelessWidget {
  final RegistrationStatus status;
  final String registrationId;
  final String dateSubmitted;

  const RegistrationStatusCard({
    super.key,
    required this.status,
    required this.registrationId,
    required this.dateSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors and icons based on status
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Registration Status",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 16,
                ),
              ),
              _buildStatusBadge(statusConfig),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.fingerprint, "ID", registrationId),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today, "Submitted", dateSubmitted),
        ],
      ),
    );
  }

  // Helper to build the small colorful badge
  Widget _buildStatusBadge(_StatusConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  _StatusConfig _getStatusConfig(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return _StatusConfig(Icons.check_circle, Colors.green, "Approved");
      case RegistrationStatus.rejected:
        return _StatusConfig(Icons.cancel, Colors.red, "Rejected");
      case RegistrationStatus.processing:
        return _StatusConfig(Icons.sync, Colors.blue, "Processing");
      case RegistrationStatus.pending:
      default:
        return _StatusConfig(Icons.hourglass_empty, Colors.orange, "Pending");
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  _StatusConfig(this.icon, this.color, this.label);
}
