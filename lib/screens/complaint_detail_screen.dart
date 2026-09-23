import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/complaint_models.dart';
import '../providers/complaint_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';

// GET /complaints/:id (complaints:view at OWN scope for a CUSTOMER role).
// The list screen truncates the description to two lines and is capped at 100
// rows, so this is the only place a customer can read their full complaint and
// the team's reply to it once it scrolls out of that page.
class ComplaintDetailScreen extends ConsumerWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

  static Color statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'RESOLVED':
      case 'CLOSED':
        return Colors.green;
      default:
        return AppColors.neutral500;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaint = ref.watch(complaintDetailProvider(complaintId));

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Complaint'), centerTitle: false),
      body: complaint.when(
        data: (c) => RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async => ref.invalidate(complaintDetailProvider(complaintId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            c.subject,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusChip(c.status),
                      ],
                    ),
                    if (c.serviceRequestNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 14, color: AppColors.neutral500),
                          const SizedBox(width: 5),
                          Text(
                            c.serviceRequestNumber!,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(c.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 14),
                    Text(
                      'Raised on ${_formatDate(c.createdAt)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (c.response != null && c.response!.isNotEmpty)
                _card(
                  background: const Color(0xFFF0FDF4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          const Text(
                            'Response from our team',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(c.response!, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                    ],
                  ),
                )
              else
                _card(
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, size: 18, color: AppColors.neutral500),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Our team is reviewing this. You'll be notified as soon as they respond.",
                          style: TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
        error: (err, _) => Center(
          child: AppErrorView(
            error: err,
            onRetry: () => ref.invalidate(complaintDetailProvider(complaintId)),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color background = AppColors.white}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _statusChip(String status) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        complaintStatusLabel(status),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
