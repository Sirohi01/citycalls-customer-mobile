import 'package:flutter/material.dart';
import '../../models/booking_models.dart';
import '../../theme/app_theme.dart';
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
                  const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedDate = day),
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.black : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(12),
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
            ...kTimeSlots.map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: _selectedSlot == slot ? AppColors.black : AppColors.neutral200, width: _selectedSlot == slot ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: AppColors.neutral500, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(slot)),
                          if (_selectedSlot == slot) const Icon(Icons.check_circle, color: AppColors.black, size: 20),
                        ],
                      ),
                    ),
                  ),
                )),
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
