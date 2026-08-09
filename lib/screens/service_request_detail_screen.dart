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
class ServiceRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ServiceRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<ServiceRequestDetailScreen> createState() => _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState extends ConsumerState<ServiceRequestDetailScreen> {
  String get requestId => widget.requestId;
  bool _confirming = false;

  Future<void> _confirmCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: const Text('Confirm that the technician has completed this service? This moves your request forward to payment.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not Yet')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _confirming = true);
    try {
      await ref.read(serviceRequestRepositoryProvider).confirmCompletion(requestId);
      ref.invalidate(serviceRequestDetailProvider(requestId));
      ref.invalidate(activityLogProvider(requestId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not confirm: $e')));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(serviceRequestDetailProvider(requestId));
    final activityLog = ref.watch(activityLogProvider(requestId));

    // Status/assignment changes arrive over the same socket room the Live
    // Map section listens on (serviceRequestRealtimeProvider) — refetching
    // the REST detail/history here instead of trying to patch the socket
    // payload directly into state keeps a single source of truth for what's
    // actually shown (the full ServiceRequestDetail/ActivityLogEntry
    // shapes), rather than juggling two representations of the same data.
    ref.listen(serviceRequestRealtimeProvider(requestId), (previous, next) {
      final event = next.valueOrNull;
      if (event != null && event.type != RealtimeEventType.locationUpdated) {
        ref.invalidate(serviceRequestDetailProvider(requestId));
        ref.invalidate(activityLogProvider(requestId));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Service Request'), centerTitle: false),
      body: detail.when(
        data: (sr) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRequestDetailProvider(requestId));
            ref.invalidate(activityLogProvider(requestId));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _headerCard(context, sr),
              const SizedBox(height: 16),
              if (sr.assignee != null) _technicianCard(context, sr.assignee!),
              if (sr.assignee != null && sr.isActive) LiveMapSection(requestId: requestId),
              _infoCard(context, Icons.location_on_outlined, 'Address', sr.addressLine),
              if (sr.symptoms.isNotEmpty) _infoCard(context, Icons.report_gmailerrorred_outlined, 'Symptoms', sr.symptoms.join(', ')),
              if (sr.notes != null && sr.notes!.isNotEmpty) _infoCard(context, Icons.notes_outlined, 'Notes', sr.notes!),
              if (sr.status == 'CANCELLED' && sr.cancelReason != null) _infoCard(context, Icons.cancel_outlined, 'Cancellation Reason', sr.cancelReason!),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Activity Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 14),
                    activityLog.when(
                      data: (entries) => entries.isEmpty
                          ? const Text('No activity yet.', style: TextStyle(color: AppColors.neutral500))
                          : Column(children: [for (var i = 0; i < entries.length; i++) _timelineEntry(entries[i], isLast: i == entries.length - 1)]),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Failed to load activity', style: TextStyle(color: AppColors.neutral500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (sr.status == 'ESTIMATE_SHARED' || sr.status == 'AWAITING_CUSTOMER_APPROVAL')
                _actionButton(context, Icons.receipt_long_outlined, 'Review Estimate', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EstimateReviewScreen(requestId: requestId)))),
              // The actual "move this request forward" action for this
              // status — previously the only thing offered here was "Rate
              // Your Experience", which submits feedback but never confirms
              // completion, so the request could sit stuck on this status
              // forever with no way for the customer to advance it.
              if (sr.status == 'CUSTOMER_CONFIRMATION_PENDING')
                _actionButton(context, Icons.check_circle_outline, _confirming ? 'Confirming...' : 'Confirm Completion', _confirming ? () {} : _confirmCompletion),
              if (sr.status == 'PAYMENT_PENDING' || sr.status == 'PARTIALLY_PAID' || sr.status == 'PAID')
                _actionButton(context, Icons.receipt_outlined, 'View Invoice', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceViewScreen(requestId: requestId)))),
              if (sr.status == 'SERVICE_COMPLETED' || sr.status == 'CUSTOMER_CONFIRMATION_PENDING')
                _actionButton(context, Icons.star_outline, 'Rate Your Experience', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeedbackScreen(requestId: requestId)))),
              if (sr.status == 'APPOINTMENT_SCHEDULED')
                _actionButton(context, Icons.event_repeat, 'Reschedule', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RescheduleScreen(requestId: requestId)))),
              if (isCancellableStatus(sr.status))
                _actionButton(
                  context,
                  Icons.close,
                  'Cancel Request',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CancelRequestScreen(requestId: requestId))),
                  destructive: true,
                ),
              if (sr.status == 'CLOSED' || sr.status == 'PAID')
                _actionButton(context, Icons.replay, 'Reopen Request', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReopenRequestScreen(requestId: requestId)))),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load service request: $err')),
      ),
    );
  }

  Widget _headerCard(BuildContext context, ServiceRequestDetail sr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.build_circle_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sr.number, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                if (sr.serviceName != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sr.serviceName!, style: const TextStyle(color: AppColors.neutral500, fontSize: 12.5))),
              ],
            ),
          ),
          StatusBadge(status: sr.status),
        ],
      ),
    );
  }

  Widget _technicianCard(BuildContext context, ServiceRequestAssignee assignee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.engineering, color: Colors.white, size: 20)),
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

  Widget _infoCard(BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.neutral500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineEntry(ActivityLogEntry entry, {required bool isLast}) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.black),
                ),
                if (!isLast) Expanded(child: Container(width: 1.5, color: AppColors.neutral200)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.action.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (entry.reason != null && entry.reason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(entry.reason!, style: const TextStyle(fontSize: 12)),
                      ),
                    Text(
                      DateTime.tryParse(entry.timestamp)?.toLocal().toString().split('.').first ?? '',
                      style: const TextStyle(color: AppColors.neutral500, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool destructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: destructive
            ? OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, size: 18),
                label: Text(label),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size.fromHeight(48)),
              )
            : FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label)),
      ),
    );
  }
}
