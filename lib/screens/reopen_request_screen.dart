import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "History" — Reopen Request.
class ReopenRequestScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ReopenRequestScreen({super.key, required this.requestId});

  @override
  ConsumerState<ReopenRequestScreen> createState() => _ReopenRequestScreenState();
}

class _ReopenRequestScreenState extends ConsumerState<ReopenRequestScreen> {
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
      setState(() => _error = 'Please tell us what\'s still wrong.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(serviceRequestRepositoryProvider).reopenServiceRequest(widget.requestId, _reasonController.text.trim());
      ref.invalidate(myServiceRequestsProvider);
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to reopen: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Reopen Request'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Still facing the same issue? Reopening lets our team follow up without booking a fresh request.',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            const SizedBox(height: 20),
            const Text('What\'s still wrong?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _reasonController, maxLines: 3, decoration: const InputDecoration(hintText: 'Describe the issue...')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reopen Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
