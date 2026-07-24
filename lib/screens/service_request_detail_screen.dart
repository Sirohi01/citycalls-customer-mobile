import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_models.dart';
import '../models/realtime_models.dart';
import '../providers/service_request_providers.dart';
import '../providers/realtime_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/live_map_section.dart';
import 'reschedule_screen.dart';
import 'cancel_request_screen.dart';
import 'estimate_review_screen.dart';
import 'invoice_view_screen.dart';
import 'reopen_request_screen.dart';
import 'feedback_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Tracking" — Service Request
// Detail (status timeline, technician info, live map).
class ServiceRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const ServiceRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(serviceRequestDetailProvider(requestId));
    final history = ref.watch(assignmentHistoryProvider(requestId));

    // Status/assignment changes arrive over the same socket room the Live
    // Map section listens on (serviceRequestRealtimeProvider) — refetching
    // the REST detail/history here instead of trying to patch the socket
    // payload directly into state keeps a single source of truth for what's
    // actually shown (the full ServiceRequestDetail/AssignmentHistoryEntry
    // shapes), rather than juggling two representations of the same data.
    ref.listen(serviceRequestRealtimeProvider(requestId), (previous, next) {
      final event = next.valueOrNull;
      if (event != null && event.type != RealtimeEventType.locationUpdated) {
        ref.invalidate(serviceRequestDetailProvider(requestId));
        ref.invalidate(assignmentHistoryProvider(requestId));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Service Request'), centerTitle: false),
      body: detail.when(
        data: (sr) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRequestDetailProvider(requestId));
            ref.invalidate(assignmentHistoryProvider(requestId));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sr.number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  StatusBadge(status: sr.status),
                ],
              ),
              if (sr.serviceName != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(sr.serviceName!, style: const TextStyle(color: AppColors.neutral500))),
              const SizedBox(height: 20),
              if (sr.assignee != null) _technicianCard(sr.assignee!),
              if (sr.assignee != null && sr.isActive) LiveMapSection(requestId: requestId),
              _infoCard('Address', sr.addressLine),
              if (sr.symptoms.isNotEmpty) _infoCard('Symptoms', sr.symptoms.join(', ')),
              if (sr.notes != null && sr.notes!.isNotEmpty) _infoCard('Notes', sr.notes!),
              if (sr.status == 'CANCELLED' && sr.cancelReason != null) _infoCard('Cancellation Reason', sr.cancelReason!),
              const SizedBox(height: 8),
              const Text('Activity Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              history.when(
                data: (entries) => entries.isEmpty
                    ? const Text('No activity yet.', style: TextStyle(color: AppColors.neutral500))
                    : Column(children: entries.map((e) => _timelineEntry(e)).toList()),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load activity', style: TextStyle(color: AppColors.neutral500)),
              ),
              const SizedBox(height: 24),
              if (sr.status == 'ESTIMATE_SHARED' || sr.status == 'AWAITING_CUSTOMER_APPROVAL')
                _actionButton(context, 'Review Estimate', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EstimateReviewScreen(requestId: requestId)))),
              if (sr.status == 'PAYMENT_PENDING' || sr.status == 'PARTIALLY_PAID' || sr.status == 'PAID')
                _actionButton(context, 'View Invoice', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceViewScreen(requestId: requestId)))),
              if (sr.status == 'SERVICE_COMPLETED' || sr.status == 'CUSTOMER_CONFIRMATION_PENDING')
                _actionButton(context, 'Rate Your Experience', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeedbackScreen(requestId: requestId)))),
              if (sr.status == 'APPOINTMENT_SCHEDULED')
                _actionButton(context, 'Reschedule', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RescheduleScreen(requestId: requestId)))),
              if (isCancellableStatus(sr.status))
                _actionButton(
                  context,
                  'Cancel Request',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CancelRequestScreen(requestId: requestId))),
                  destructive: true,
                ),
              if (sr.status == 'CLOSED' || sr.status == 'PAID')
                _actionButton(context, 'Reopen Request', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReopenRequestScreen(requestId: requestId)))),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load service request: $err')),
      ),
    );
  }

  Widget _technicianCard(ServiceRequestAssignee assignee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.black, child: Icon(Icons.engineering, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignee.name ?? 'Technician assigned', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(assignee.type.replaceAll('_', ' '), style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.neutral200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _timelineEntry(AssignmentHistoryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 4), child: CircleAvatar(radius: 4, backgroundColor: AppColors.black)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.action.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  DateTime.tryParse(entry.timestamp)?.toLocal().toString().split('.').first ?? '',
                  style: const TextStyle(color: AppColors.neutral500, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, VoidCallback onTap, {bool destructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: destructive
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                child: Text(label),
              )
            : FilledButton(onPressed: onTap, child: Text(label)),
      ),
    );
  }
}
