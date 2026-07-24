import 'package:flutter/material.dart';
import '../../models/booking_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_step_header.dart';
import 'booking_review_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Slot Selection.
// docs/manish/08-customer-app-functional-plan.md §2 calls for a real
// GET /appointment-slots?branchId=&date= availability check, but that
// endpoint doesn't exist in the backend yet — createServiceRequestSchema's
// scheduledDate/scheduledSlot are plain optional fields with no capacity
// validation behind them either. This is a simple date + generic time-of-day
// picker, not real slot-capacity checking; flagged as a known gap, not
// silently faked.
class SlotSelectionScreen extends StatefulWidget {
  final BookingDraft draft;
  const SlotSelectionScreen({super.key, required this.draft});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day + i));

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
            const Text('Preferred time slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
            const Spacer(),
            FilledButton(
              onPressed: (_selectedDate == null || _selectedSlot == null)
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BookingReviewScreen(
                          draft: widget.draft.copyWith(scheduledDate: _selectedDate, scheduledSlot: _selectedSlot),
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
