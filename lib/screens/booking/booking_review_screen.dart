import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import '../../providers/customer_providers.dart';
import '../../providers/service_request_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_step_header.dart';
import 'booking_success_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Booking Review & Confirm.
class BookingReviewScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const BookingReviewScreen({super.key, required this.draft});

  @override
  ConsumerState<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  bool _submitting = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final customerId = (await ref.read(myProfileProvider.future)).id;
      final result = await ref.read(bookingRepositoryProvider).createServiceRequest(widget.draft, customerId);
      ref.invalidate(myServiceRequestsProvider);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BookingSuccessScreen(requestNumber: result['number'] as String)),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = 'Failed to submit your request: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final address = draft.address!;

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Review & Confirm'), centerTitle: false, backgroundColor: AppColors.neutral100, surfaceTintColor: AppColors.neutral100),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BookingStepHeader(step: 5, totalSteps: 5, title: 'Review your booking'),
            Expanded(
              child: ListView(
                children: [
                  _section(context, Icons.build_outlined, 'Service', draft.serviceName),
                  _section(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    [address.label, address.line1, address.line2, address.landmark, address.city, address.state, address.pinCode]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(', '),
                  ),
                  if (draft.symptoms.isNotEmpty) _section(context, Icons.report_gmailerrorred_outlined, 'Symptoms', draft.symptoms.join(', ')),
                  if (draft.notes != null && draft.notes!.isNotEmpty) _section(context, Icons.notes_outlined, 'Notes', draft.notes!),
                  if (draft.imageUrls.isNotEmpty) _section(context, Icons.photo_library_outlined, 'Photos attached', '${draft.imageUrls.length} photo(s)'),
                  _section(context, Icons.calendar_today_outlined, 'Preferred date', draft.scheduledDate == null ? '—' : '${draft.scheduledDate!.day}/${draft.scheduledDate!.month}/${draft.scheduledDate!.year}'),
                  _section(context, Icons.schedule, 'Preferred time', draft.scheduledSlot ?? '—'),
                ],
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            FilledButton.icon(
              onPressed: _submitting ? null : _confirm,
              icon: _submitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(_submitting ? 'Submitting...' : 'Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
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
}
