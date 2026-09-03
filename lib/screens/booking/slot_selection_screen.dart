import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import 'booking_review_screen.dart';

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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Gradient matching the UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6EAF6),
                    Color(0xFFECF1FD),
                    Color(0xFFFAFAFA),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header (Back Button & Title) ---
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, color: Color(0xFF16A34A), size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('Select a Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Step 4 ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                            TextSpan(text: 'of 5', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
                          ]
                        )
                      ),
                    ],
                  ),
                ),

                // --- Progress ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 4 / 5,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Scrollable Content ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Section 1: Date ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0FDF4),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('1', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Preferred date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  SizedBox(height: 2),
                                  Text('Choose the date you prefer', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 76,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: days.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final day = days[i];
                              final selected = _selectedDate != null && _selectedDate!.day == day.day && _selectedDate!.month == day.month;
                              const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              
                              return InkWell(
                                onTap: () => setState(() {
                                  _selectedDate = day;
                                  _selectedSlot = null;
                                }),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFF16A34A) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: selected ? const Color(0xFF16A34A) : Colors.grey.shade300),
                                    boxShadow: [
                                      if (selected)
                                        BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                                      else
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(monthLabels[day.month - 1].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? Colors.white70 : Colors.black54)),
                                      const SizedBox(height: 2),
                                      Text('${day.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.black87)),
                                      const SizedBox(height: 2),
                                      Text(weekdayLabels[day.weekday - 1], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? Colors.white : Colors.black54)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // --- Section 2: Time Slot ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0FDF4),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('2', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Preferred time slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  SizedBox(height: 2),
                                  Text('Select a convenient time', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (_selectedDate == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_available, size: 64, color: Colors.green.shade200),
                                  const SizedBox(height: 16),
                                  const Text('Pick a date to see available time slots.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                  const SizedBox(height: 8),
                                  const Text('We\'ll show you the best available slots for\nyour selected date.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                        else
                          branch.when(
                            data: (coverage) {
                              if (coverage.branchId == null) {
                                return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Address not serviceable.', style: TextStyle(color: Colors.black54))));
                              }
                              return _SlotList(
                                branchId: coverage.branchId!,
                                date: _selectedDate!,
                                selectedSlot: _selectedSlot,
                                onSelect: (slot) => setState(() => _selectedSlot = slot),
                              );
                            },
                            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                            error: (_, __) => const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Could not check slot availability.', style: TextStyle(color: Colors.black54)))),
                          ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // --- Sticky Bottom Action ---
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: (_selectedDate == null || _selectedSlot == null)
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => BookingReviewScreen(
                                draft: widget.draft.copyWith(scheduledDate: _selectedDate, scheduledSlot: _selectedSlot!.label),
                              ),
                            )),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: (_selectedDate != null && _selectedSlot != null) ? const Color(0xFF16A34A) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: (_selectedDate != null && _selectedSlot != null) ? Colors.white : Colors.black38,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('This branch is closed on the selected date.', style: TextStyle(color: Colors.black54))));
        }
        if (r.slots.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No slots available.', style: TextStyle(color: Colors.black54))));
        }
        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: r.slots.map((slot) {
                final isSelected = selectedSlot?.key == slot.key;
                return InkWell(
                  onTap: slot.available ? () => onSelect(slot) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 52) / 2, // 2 columns (20 padding * 2 + 12 spacing)
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF16A34A) : (slot.available ? Colors.grey.shade200 : Colors.grey.shade100), width: isSelected ? 1.5 : 1),
                      boxShadow: [
                        if (!isSelected && slot.available)
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: isSelected ? const Color(0xFF16A34A) : (slot.available ? const Color(0xFF16A34A).withValues(alpha: 0.6) : Colors.black26)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            slot.label,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: slot.available ? (isSelected ? const Color(0xFF16A34A) : Colors.black87) : Colors.black26),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                          )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.event_note, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Why choose a time?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        SizedBox(height: 4),
                        Text('Choosing a time helps us assign a technician and serve you better.', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (_, __) => const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Could not load slots.', style: TextStyle(color: Colors.black54)))),
    );
  }
}
