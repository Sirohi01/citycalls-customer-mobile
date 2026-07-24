import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_models.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Reschedule/Cancel" —
// Reschedule screen. Mirrors booking/slot_selection_screen.dart's date+slot
// picker UI, now backed by a real PATCH /service-requests/:id/reschedule
// endpoint (serviceRequests.routes.ts) that persists scheduledDate/
// scheduledSlot — not just a reason-only status flip.
class RescheduleScreen extends ConsumerStatefulWidget {
  final String requestId;
  const RescheduleScreen({super.key, required this.requestId});

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedSlot == null) {
      setState(() => _error = 'Please pick a new date and time slot.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(serviceRequestRepositoryProvider).requestReschedule(
            widget.requestId,
            scheduledDate: _selectedDate!,
            scheduledSlot: _selectedSlot!,
            reason: _reasonController.text.trim(),
          );
      ref.invalidate(myServiceRequestsProvider);
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(10, (i) => DateTime(today.year, today.month, today.day + i));
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Reschedule'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_repeat, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pick a new date and time — we\'ll update your appointment right away.',
                    style: TextStyle(color: AppColors.neutral900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('New date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = days[i];
                final selected = _selectedDate != null && _selectedDate!.year == day.year && _selectedDate!.month == day.month && _selectedDate!.day == day.day;
                final primary = Theme.of(context).colorScheme.primary;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedDate = day),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: selected ? primary : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(weekdayLabels[day.weekday - 1], style: TextStyle(color: selected ? Colors.white70 : AppColors.neutral500, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${day.day}', style: TextStyle(color: selected ? Colors.white : AppColors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('New time slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          ...kTimeSlots.map((slot) {
            final primary = Theme.of(context).colorScheme.primary;
            final selected = _selectedSlot == slot;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: selected ? primary.withValues(alpha: 0.05) : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: selected ? 0 : 1,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: selected ? primary : Colors.transparent, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: selected ? primary : AppColors.neutral500, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(slot)),
                        if (selected) Icon(Icons.check_circle, color: primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text('Reason (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(controller: _reasonController, maxLines: 3, decoration: const InputDecoration(hintText: 'e.g. I won\'t be home at the original time')),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm Reschedule'),
          ),
        ],
      ),
    );
  }
}
