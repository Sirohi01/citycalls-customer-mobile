import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../providers/finance_providers.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Estimates & Payments" —
// Invoice View, Payment screen (manual methods), Payment History — combined
// into one screen since they all revolve around the same Invoice document.
// Gateway-based in-app payment is stubbed per docs/manish/08 §6 — only manual
// methods are wired.
class InvoiceViewScreen extends ConsumerWidget {
  final String requestId;
  const InvoiceViewScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceForRequestProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Invoice'), centerTitle: false),
      body: invoice.when(
        data: (inv) {
          if (inv == null) return const Center(child: Text('No invoice found for this request yet.', style: TextStyle(color: AppColors.neutral500)));
          final payments = ref.watch(paymentsForInvoiceProvider(inv.id));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoiceForRequestProvider(requestId));
              ref.invalidate(paymentsForInvoiceProvider(inv.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(inv.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    StatusBadge(status: inv.status),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.neutral200), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _row('Total Amount', '₹${inv.total.toStringAsFixed(0)}'),
                      _row('Amount Paid', '₹${inv.amountPaid.toStringAsFixed(0)}'),
                      _row('Outstanding', '₹${inv.outstanding.toStringAsFixed(0)}', bold: true),
                    ],
                  ),
                ),
                if (inv.outstanding > 0 && inv.status != 'CANCELLED') ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showPaymentSheet(context, ref, inv),
                    icon: const Icon(Icons.payment),
                    label: const Text('Make a Payment'),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                payments.when(
                  data: (items) => items.isEmpty
                      ? const Text('No payments recorded yet.', style: TextStyle(color: AppColors.neutral500))
                      : Column(
                          children: items
                              .map((p) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.number, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text(
                                                '${p.method.replaceAll('_', ' ')}${p.reference != null ? ' · ${p.reference}' : ''}',
                                                style: const TextStyle(color: AppColors.neutral500, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Failed to load payment history', style: TextStyle(color: AppColors.neutral500)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load invoice: $err')),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: bold ? 17 : 14)),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PaymentSheet(invoice: invoice, requestId: requestId),
    );
  }
}

class _PaymentSheet extends ConsumerStatefulWidget {
  final Invoice invoice;
  final String requestId;
  const _PaymentSheet({required this.invoice, required this.requestId});

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _method = kPaymentMethods.first;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.outstanding.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(financeRepositoryProvider).recordPayment(
            widget.invoice.id,
            amount: amount,
            method: _method,
            reference: _referenceController.text.trim(),
          );
      ref.invalidate(invoiceForRequestProvider(widget.requestId));
      ref.invalidate(paymentsForInvoiceProvider(widget.invoice.id));
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to record payment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Make a Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (₹)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _method,
            decoration: const InputDecoration(labelText: 'Payment Method'),
            items: kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m.replaceAll('_', ' ')))).toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
          ),
          const SizedBox(height: 12),
          TextField(controller: _referenceController, decoration: const InputDecoration(labelText: 'Reference / Transaction ID (optional)')),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: _saving ? null : _submit,
            child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Payment'),
          ),
        ],
      ),
    );
  }
}
