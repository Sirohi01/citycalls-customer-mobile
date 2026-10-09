import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reopen_models.dart';
import '../models/service_request_models.dart';
import '../models/realtime_models.dart';
import '../providers/service_request_providers.dart';
import '../providers/realtime_providers.dart';
import '../providers/finance_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/live_map_section.dart';
import '../widgets/state_views.dart';
import '../widgets/ui_kit.dart';
import 'service_visits_screen.dart';
import 'reschedule_screen.dart';
import 'cancel_request_screen.dart';
import 'estimate_review_screen.dart';
import 'proforma_review_screen.dart';
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
    // Drives the "Work Details" entry point below — the button only appears
    // once a technician has actually opened a visit, so it never leads to an
    // empty screen.
    final hasVisits = ref.watch(serviceVisitsProvider(requestId)).valueOrNull?.isNotEmpty ?? false;
    final reopenHistory = ref.watch(reopenHistoryProvider(requestId)).valueOrNull ?? const <ReopenRecord>[];
    final proformaAwaitingAcceptance = ref.watch(proformaForRequestProvider(requestId)).valueOrNull?.status == 'SHARED';

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
        ref.invalidate(serviceVisitsProvider(requestId));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: detail.when(
        data: (sr) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRequestDetailProvider(requestId));
            ref.invalidate(activityLogProvider(requestId));
            ref.invalidate(serviceVisitsProvider(requestId));
            ref.invalidate(reopenHistoryProvider(requestId));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _headerCard(context, sr),
              const SizedBox(height: 16),
              if (sr.assignee != null) _technicianCard(context, sr.assignee!),
              if (sr.assignee != null && sr.isActive) LiveMapSection(requestId: requestId),
              const UiSectionLabel('Booking details'),
              UiCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    _infoCard(context, Icons.location_on_outlined, 'Address', sr.addressLine),
                    if (sr.symptoms.isNotEmpty) ...[
                      const Divider(height: 1),
                      _infoCard(context, Icons.report_gmailerrorred_outlined, 'Issue', sr.symptoms.join(', ')),
                    ],
                    if (sr.notes != null && sr.notes!.isNotEmpty) ...[
                      const Divider(height: 1),
                      _infoCard(context, Icons.notes_outlined, 'Notes', sr.notes!),
                    ],
                    if (sr.status == 'CANCELLED' && sr.cancelReason != null) ...[
                      const Divider(height: 1),
                      _infoCard(context, Icons.cancel_outlined, 'Cancellation reason', sr.cancelReason!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (reopenHistory.isNotEmpty) ...[
                _reopenHistoryCard(reopenHistory),
                const SizedBox(height: 18),
              ],
              const UiSectionLabel('Booking timeline'),
              UiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    activityLog.when(
                      data: (entries) => entries.isEmpty
                          ? const Text('No updates yet.', style: TextStyle(color: kMuted))
                          : Column(children: [for (var i = 0; i < entries.length; i++) _timelineEntry(entries[i], isLast: i == entries.length - 1, isFirst: i == 0)]),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, __) => AppErrorView(
                        error: err,
                        compact: true,
                        onRetry: () => ref.invalidate(activityLogProvider(requestId)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // The technician's own record of the job — diagnosis, parts
              // fitted, work notes and before/after photos. Previously none
              // of this reached the customer at all, even though they get
              // billed for the parts listed in it.
              if (hasVisits)
                _actionButton(
                  context,
                  Icons.assignment_outlined,
                  'View Work Details',
                  () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ServiceVisitsScreen(requestId: requestId, requestNumber: sr.number),
                  )),
                ),
              if (sr.status == 'ESTIMATE_SHARED' || sr.status == 'AWAITING_CUSTOMER_APPROVAL')
                _actionButton(context, Icons.receipt_long_outlined, 'Review Estimate', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EstimateReviewScreen(requestId: requestId)))),
              // The actual "move this request forward" action for this
              // status — previously the only thing offered here was "Rate
              // Your Experience", which submits feedback but never confirms
              // completion, so the request could sit stuck on this status
              // forever with no way for the customer to advance it.
              if (sr.status == 'CUSTOMER_CONFIRMATION_PENDING')
                _actionButton(context, Icons.check_circle_outline, _confirming ? 'Confirming...' : 'Confirm Completion', _confirming ? () {} : _confirmCompletion),
              // The bill is auto-generated from the already-approved Estimate
              // (no re-typed amounts) but still needs this one explicit tap —
              // same reasoning as Confirm Completion above: a financial
              // commitment shouldn't advance silently without the customer
              // seeing it.
              if (sr.status == 'PAYMENT_PENDING' && proformaAwaitingAcceptance)
                _actionButton(context, Icons.request_quote_outlined, 'Review Bill', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProformaReviewScreen(requestId: requestId)))),
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
        error: (err, _) => Center(
          child: AppErrorView(
            error: err,
            onRetry: () => ref.invalidate(serviceRequestDetailProvider(requestId)),
          ),
        ),
      ),
    );
  }

  // Status hero: service, booking number and the current status in its colour.
  Widget _headerCard(BuildContext context, ServiceRequestDetail sr) {
    final color = StatusBadge.colorFor(sr.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiIconTile(icon: Icons.home_repair_service_rounded, color: color, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sr.serviceName ?? 'Service request',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 3),
                    Text('Booking #${sr.number}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.radio_button_checked_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                const Text('Status: ', style: TextStyle(fontSize: 13, color: kMuted)),
                Expanded(
                  child: Text(customerStatusLabel(sr.status),
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _technicianCard(BuildContext context, ServiceRequestAssignee assignee) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UiCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: kInk, shape: BoxShape.circle),
              child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your professional', style: TextStyle(fontSize: 11.5, color: kMuted)),
                  const SizedBox(height: 2),
                  Text(assignee.name ?? 'Technician assigned',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                ],
              ),
            ),
            const UiPill(text: 'Assigned', color: kGreen, icon: Icons.verified_rounded),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: kInk, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // "SERVICE_COMPLETED" → "Service completed".
  static String _humanize(String action) {
    final words = action.replaceAll('_', ' ').toLowerCase();
    return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
  }

  Widget _timelineEntry(ActivityLogEntry entry, {required bool isLast, bool isFirst = false}) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? kGreen : Colors.white,
                    border: Border.all(color: isFirst ? kGreen : const Color(0xFFCBD5E1), width: 2),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_humanize(entry.action),
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isFirst ? kInk : const Color(0xFF334155))),
                    if (entry.reason != null && entry.reason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(entry.reason!, style: const TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      formatDisplayDateTime(entry.timestamp),
                      style: const TextStyle(color: kFaint, fontSize: 11.5),
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

  // A customer-initiated reopen starts PENDING and needs staff approval
  // (reopenRecords.model.ts), so without this the customer tapped "Reopen",
  // got a success toast, and then had no way to learn whether it was ever
  // approved. The /reopen-requests list endpoint is happyCalls-gated, but
  // this per-request history is serviceRequests:view at OWN scope.
  Widget _reopenHistoryCard(List<ReopenRecord> records) {
    return UiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reopen requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
          const SizedBox(height: 12),
          for (final record in records) _reopenRow(record),
        ],
      ),
    );
  }

  Widget _reopenRow(ReopenRecord record) {
    final color = switch (record.status) {
      'APPROVED' => const Color(0xFF16A34A),
      'REJECTED' => Colors.red,
      _ => const Color(0xFFF59E0B),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reopen #${record.reopenCount}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                Text(
                  reopenStatusLabel(record.status),
                  style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(record.reason, style: const TextStyle(fontSize: 12.5, height: 1.4)),
            if (record.status == 'REJECTED' && record.rejectionReason != null) ...[
              const SizedBox(height: 5),
              Text(
                'Reason: ${record.rejectionReason}',
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500, height: 1.4),
              ),
            ],
            if (!record.withinPolicyWindow) ...[
              const SizedBox(height: 5),
              const Text(
                'Raised outside the standard reopen window',
                style: TextStyle(fontSize: 11.5, color: AppColors.neutral500),
              ),
            ],
            if (record.reopenedAt != null) ...[
              const SizedBox(height: 5),
              Text(
                '${record.reopenedAt!.day.toString().padLeft(2, '0')}/${record.reopenedAt!.month.toString().padLeft(2, '0')}/${record.reopenedAt!.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
              ),
            ],
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  backgroundColor: const Color(0xFFFEF2F2),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  minimumSize: const Size.fromHeight(50),
                ),
              )
            : FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label)),
      ),
    );
  }
}
