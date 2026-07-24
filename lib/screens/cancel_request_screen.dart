import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Reschedule/Cancel" — Cancel
// confirmation (policy-aware messaging). No cancellation-policy endpoint
// exists to fetch fee/notice-period text from, so this only surfaces what
// the backend itself enforces (a required reason) rather than fabricating
// policy copy that isn't backed by real data.
class CancelRequestScreen extends ConsumerStatefulWidget {
  final String requestId;
  const CancelRequestScreen({super.key, required this.requestId});

  @override
  ConsumerState<CancelRequestScreen> createState() => _CancelRequestScreenState();
}

class _CancelRequestScreenState extends ConsumerState<CancelRequestScreen> {
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Please tell us why you\'re cancelling.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(serviceRequestRepositoryProvider).cancelServiceRequest(widget.requestId, _reasonController.text.trim());
      ref.invalidate(myServiceRequestsProvider);
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to cancel: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Cancel Request'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Are you sure you want to cancel this service request? This action can\'t be undone.',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Reason for cancellation', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _reasonController, maxLines: 3, decoration: const InputDecoration(hintText: 'e.g. Found another service provider')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Cancellation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
