import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_step_header.dart';
import 'booking_review_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Slot Selection.
// Real GET /appointment-slots?branchId=&date= availability check per
// docs/manish/08-customer-app-functional-plan.md §2 — branch is re-resolved
// from the address actually chosen in this booking (draft.address), not the
// earlier Service Detail screen's PIN, via bookingBranchProvider. Full slots
// are shown but disabled rather than hidden, so the customer understands why
// an option isn't tappable instead of it silently not being there.
class SlotSelectionScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const SlotSelectionScreen({super.key, required this.draft});

  @override
  ConsumerState<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends ConsumerState<SlotSelectionScreen> {
  DateTime? _selectedDate;
  AppointmentSlot? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day + i));
    final pinCode = widget.draft.address?.pinCode ?? widget.draft.pinCode;
    final branch = ref.watch(bookingBranchProvider((serviceId: widget.draft.serviceId, pinCode: pinCode)));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Select a Time'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BookingStepHeader(step: 4, totalSteps: 5, title: 'Select a time'),
            const Text('Preferred date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = days[i];
                  final selected = _selectedDate != null &&
                      _selectedDate!.year == day.year &&
                      _selectedDate!.month == day.month &&
                      _selectedDate!.day == day.day;
                  final primary = Theme.of(context).colorScheme.primary;
                  const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _selectedDate = day;
                      _selectedSlot = null;
                    }),
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
            const Text('Preferred time slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedDate == null
                  ? const Center(child: Text('Pick a date to see available time slots.', style: TextStyle(color: AppColors.neutral500)))
                  : branch.when(
                      data: (coverage) {
                        if (coverage.branchId == null) {
                          return const Center(
                            child: Text('We couldn\'t match this address to a service branch. Please go back and check your address.', style: TextStyle(color: AppColors.neutral500)),
                          );
                        }
                        return _SlotList(
                          branchId: coverage.branchId!,
                          date: _selectedDate!,
                          selectedSlot: _selectedSlot,
                          onSelect: (slot) => setState(() => _selectedSlot = slot),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Could not check slot availability. Please try again.', style: TextStyle(color: AppColors.neutral500))),
                    ),
            ),
            FilledButton(
              onPressed: (_selectedDate == null || _selectedSlot == null)
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BookingReviewScreen(
                          draft: widget.draft.copyWith(scheduledDate: _selectedDate, scheduledSlot: _selectedSlot!.label),
                        ),
                      )),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotList extends ConsumerWidget {
  final String branchId;
  final DateTime date;
  final AppointmentSlot? selectedSlot;
  final ValueChanged<AppointmentSlot> onSelect;
  const _SlotList({required this.branchId, required this.date, required this.selectedSlot, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(appointmentSlotsProvider((branchId: branchId, date: date)));
    return result.when(
      data: (r) {
        if (r.dayClosed) {
          return const Center(child: Text('This branch is closed on the selected date. Please pick another day.', style: TextStyle(color: AppColors.neutral500)));
        }
        if (r.slots.isEmpty) {
          return const Center(child: Text('No time slots are configured yet. Please pick another day.', style: TextStyle(color: AppColors.neutral500)));
        }
        return ListView(
          children: r.slots.map((slot) {
            final primary = Theme.of(context).colorScheme.primary;
            final selected = selectedSlot?.key == slot.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: !slot.available ? AppColors.neutral100 : (selected ? primary.withValues(alpha: 0.05) : AppColors.white),
                borderRadius: BorderRadius.circular(14),
                elevation: selected ? 0 : 1,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: slot.available ? () => onSelect(slot) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: selected ? primary : Colors.transparent, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: !slot.available ? AppColors.neutral500 : (selected ? primary : AppColors.neutral500), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(slot.label, style: TextStyle(color: slot.available ? AppColors.black : AppColors.neutral500)),
                        ),
                        if (!slot.available)
                          const Text('Full', style: TextStyle(color: AppColors.neutral500, fontSize: 12, fontWeight: FontWeight.w600))
                        else if (selected)
                          Icon(Icons.check_circle, color: primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not check slot availability. Please try again.', style: TextStyle(color: AppColors.neutral500))),
    );
  }
}
