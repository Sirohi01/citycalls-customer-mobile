import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/complaint_providers.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Support" — Raise Complaint,
// now a real ticket (citycalls-api's src/modules/complaints) instead of just
// static contact info. Linking to a specific service request is optional —
// some complaints (billing across requests, app issues) aren't about one visit.
class RaiseComplaintScreen extends ConsumerStatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  ConsumerState<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends ConsumerState<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _serviceRequestId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(complaintRepositoryProvider).createComplaint(
            subject: _subjectController.text.trim(),
            description: _descriptionController.text.trim(),
            serviceRequestId: _serviceRequestId,
          );
      ref.invalidate(myComplaintsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted — our team will get back to you.')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myServiceRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Raise a Complaint'), centerTitle: false),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: 'Briefly describe the issue'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
            ),
            const SizedBox(height: 20),
            const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Tell us what happened'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add some detail' : null,
            ),
            const SizedBox(height: 20),
            const Text('Related service request (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            requests.when(
              data: (items) => DropdownButtonFormField<String?>(
                value: _serviceRequestId,
                decoration: const InputDecoration(hintText: 'None'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  ...items.map((r) => DropdownMenuItem<String?>(value: r.id, child: Text('${r.number} — ${r.serviceName ?? "Service"}'))),
                ],
                onChanged: (v) => setState(() => _serviceRequestId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Complaint'),
            ),
          ],
        ),
      ),
    );
  }
}
