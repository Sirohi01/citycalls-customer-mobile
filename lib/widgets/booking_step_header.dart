import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Shared across the 5-step booking wizard (product -> address -> issue ->
// slot -> review) so progress feels continuous rather than each screen
// looking like an unrelated form. Step count/position is a plain constant
// per screen rather than threaded through BookingDraft — the wizard's shape
// is fixed, no need for that to be dynamic state.
class BookingStepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  const BookingStepHeader({super.key, required this.step, required this.totalSteps, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              Text('Step $step of $totalSteps', style: const TextStyle(color: AppColors.neutral500, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / totalSteps,
              minHeight: 5,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
