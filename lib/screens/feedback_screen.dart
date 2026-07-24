import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Feedback" — Rating & Feedback
// screen (post-completion). Backed by the new, narrowly-scoped
// POST /service-requests/:id/feedback (see happyCalls.service.ts's
// submitCustomerFeedback) — writes only the rating/remarks, never touches
// the separate staff-driven Happy Call outcome/escalation workflow.
class FeedbackScreen extends ConsumerStatefulWidget {
  final String requestId;
  const FeedbackScreen({super.key, required this.requestId});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  final _remarksController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(serviceRequestRepositoryProvider).submitFeedback(widget.requestId, _rating, _remarksController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your feedback!')));
      }
    } catch (e) {
      setState(() => _error = 'Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static const _ratingLabels = {1: 'Poor', 2: 'Fair', 3: 'Good', 4: 'Great', 5: 'Excellent!'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Rate Your Experience'), centerTitle: false, backgroundColor: AppColors.neutral100, surfaceTintColor: AppColors.neutral100),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('How was your service?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return IconButton(
                        iconSize: 40,
                        onPressed: () => setState(() => _rating = starIndex),
                        icon: Icon(
                          starIndex <= _rating ? Icons.star : Icons.star_border,
                          color: starIndex <= _rating ? Colors.amber : AppColors.neutral200,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 4),
                    Text(_ratingLabels[_rating]!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Additional comments (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _remarksController, maxLines: 3, decoration: const InputDecoration(hintText: 'Tell us more...')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(_submitting ? 'Submitting...' : 'Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
