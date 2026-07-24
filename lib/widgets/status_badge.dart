import 'package:flutter/material.dart';
import '../models/service_request_models.dart';

// Shared status-color mapping for Service Request cards — Home's "active
// requests" preview and My Services both use this so a status always reads
// the same color (and the same customer-friendly label, not the raw
// internal enum) everywhere in the app.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static const _completed = {'SERVICE_COMPLETED', 'FOLLOW_UP_PENDING', 'HAPPY_CALL_PENDING', 'PAID', 'CLOSED'};
  static const _cancelled = {'CANCELLED', 'ESTIMATE_REJECTED'};
  static const _attention = {'AWAITING_CUSTOMER_APPROVAL', 'ESTIMATE_SHARED', 'CUSTOMER_UNAVAILABLE', 'CUSTOMER_CONFIRMATION_PENDING', 'PAYMENT_PENDING'};

  static Color colorFor(String status) {
    if (_cancelled.contains(status)) return Colors.red;
    if (_completed.contains(status)) return Colors.green;
    if (_attention.contains(status)) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        customerStatusLabel(status),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
