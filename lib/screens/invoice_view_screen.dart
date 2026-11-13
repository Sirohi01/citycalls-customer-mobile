import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../providers/finance_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Estimates & Payments" —
// Invoice View, Payment screen (manual methods), Payment History — combined
// into one screen since they all revolve around the same Invoice document.
// Gateway-based in-app payment is stubbed per docs/manish/08 §6 — only manual
// methods are wired.
class InvoiceViewScreen extends ConsumerStatefulWidget {
  final String requestId;
  const InvoiceViewScreen({super.key, required this.requestId});

  @override
  ConsumerState<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends ConsumerState<InvoiceViewScreen> with WidgetsBindingObserver {
  String get requestId => widget.requestId;
  Razorpay? _checkout;
  String? _payingInvoiceId;
  bool _busy = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _checkout?.clear(); super.dispose(); }
  void _reload(String id) { ref.invalidate(invoiceForRequestProvider(requestId)); ref.invalidate(paymentsForInvoiceProvider(id)); }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed && _payingInvoiceId != null) { _refreshPayment(_payingInvoiceId!); } }
  Future<void> _refreshPayment(String id) async {
    try { await ref.read(financeRepositoryProvider).refreshCheckout(id); if (mounted) _reload(id); }
    catch (e) { _message('Could not refresh payment status. $e'); }
  }
  Future<void> _pay(Invoice invoice) async {
    setState(() => _busy = true);
    _payingInvoiceId = invoice.id;
    try {
      final order = await ref.read(financeRepositoryProvider).createCheckout(invoice.id);
      if (!mounted) return;
      _checkout?.clear();
      _checkout = Razorpay();
      _checkout!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        try {
          final result = await ref.read(financeRepositoryProvider).confirmCheckout(invoice.id, orderId: response.orderId ?? '', paymentId: response.paymentId ?? '', signature: response.signature ?? '');
          if (!mounted) return;
          _reload(invoice.id);
          _message(result['status'] == 'PAID' ? 'Payment verified. Your receipt is ready.' : result['message'] as String? ?? 'Payment is being confirmed. Please refresh; do not pay again.');
        } catch (e) { _message('Payment confirmation is pending. Refresh payment status before trying again. $e'); }
        finally { if (mounted) setState(() => _busy = false); }
      });
      _checkout!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) { if (mounted) setState(() => _busy = false); _message(response.message ?? 'Payment cancelled or unsuccessful.'); });
      _checkout!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) { if (mounted) setState(() => _busy = false); _message('Complete payment in the selected wallet, then refresh payment status.'); });
      _checkout!.open({'key': order['keyId'], 'order_id': order['orderId'], 'amount': order['amount'], 'currency': 'INR', 'name': 'CityCalls', 'description': order['description']});
    } catch (e) { if (mounted) setState(() => _busy = false); _message('Could not open online payment. $e'); }
  }
  Future<void> _download(String type, String id) async {
    try { final url = await ref.read(financeRepositoryProvider).documentUrl(type, id); if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) _message('Could not open the document.'); }
    catch (e) { _message('Could not download the document. $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(invoiceForRequestProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: invoice.when(
        data: (inv) {
          if (inv == null) {
            return const AppEmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No invoice yet',
              subtitle:
                  'Your bill appears here once the work is done and the invoice is raised.',
            );
          }
          final payments = ref.watch(paymentsForInvoiceProvider(inv.id));
          final notes = ref.watch(invoiceNotesProvider(inv.id)).valueOrNull ??
              const <InvoiceNote>[];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoiceForRequestProvider(requestId));
              ref.invalidate(paymentsForInvoiceProvider(inv.id));
              ref.invalidate(invoiceNotesProvider(inv.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.receipt_outlined,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(inv.number,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold))),
                      StatusBadge(status: inv.status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _row('Total Amount', '₹${inv.total.toStringAsFixed(0)}'),
                      _row('Amount Paid',
                          '₹${inv.amountPaid.toStringAsFixed(0)}'),
                      const Divider(color: AppColors.neutral200),
                      _row('Outstanding',
                          '₹${inv.outstanding.toStringAsFixed(0)}',
                          bold: true),
                    ],
                  ),
                ),
                // Credit/debit notes adjust an already-issued bill. They were
                // only ever visible in the admin panel, so a customer could
                // see their outstanding amount change with no explanation.
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adjustments',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        for (final note in notes) _noteRow(note),
                      ],
                    ),
                  ),
                ],
                if (inv.outstanding > 0 && inv.status != 'CANCELLED') ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _busy ? null : () => _pay(inv), icon: const Icon(Icons.payment), label: Text(_busy ? 'Confirming payment…' : 'Pay Online')),
                  TextButton(onPressed: () => _refreshPayment(inv.id), child: const Text('Refresh Online Payment Status')),
                  const Text('You can also pay the assigned service professional. Do not pay twice while an online payment is being confirmed.'),
                ],
                OutlinedButton.icon(onPressed: () => _download('INVOICE', inv.id), icon: const Icon(Icons.download_outlined), label: const Text('Download Invoice PDF')),
                const SizedBox(height: 24),
                const Text('Payment History',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                payments.when(
                  data: (items) => items.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14)),
                          child: const Column(
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  color: AppColors.neutral200, size: 32),
                              SizedBox(height: 8),
                              Text('No payments recorded yet.',
                                  style:
                                      TextStyle(color: AppColors.neutral500)),
                            ],
                          ),
                        )
                      : Column(
                          children: items
                              .map((p) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green,
                                              size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(p.number,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                '${p.method.replaceAll('_', ' ')}${p.reference != null ? ' · ${p.reference}' : ''}',
                                                style: const TextStyle(
                                                    color: AppColors.neutral500,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(tooltip: 'Download receipt PDF', onPressed: () => _download('PAYMENT_RECEIPT', p.id), icon: const Icon(Icons.download_outlined)),
                                        Text('₹${p.amount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, __) => AppErrorView(
                    error: err,
                    compact: true,
                    onRetry: () =>
                        ref.invalidate(paymentsForInvoiceProvider(inv.id)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: AppErrorView(
              error: err,
              onRetry: () =>
                  ref.invalidate(invoiceForRequestProvider(requestId))),
        ),
      ),
    );
  }

  // A credit note reduces what the customer owes, a debit note increases it —
  // signed and coloured accordingly so the direction is unmistakable.
  Widget _noteRow(InvoiceNote note) {
    final color =
        note.isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            note.isCredit
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.isCredit
                      ? 'Credit note ${note.number}'
                      : 'Debit note ${note.number}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (note.reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      note.reason,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                          height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${note.isCredit ? '-' : '+'}₹${note.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
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
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: bold ? 17 : 14)),
        ],
      ),
    );
  }
}
