import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_providers.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Estimates & Payments" —
// Estimate Review & Approve/Reject.
class EstimateReviewScreen extends ConsumerStatefulWidget {
  final String requestId;
  const EstimateReviewScreen({super.key, required this.requestId});

  @override
  ConsumerState<EstimateReviewScreen> createState() => _EstimateReviewScreenState();
}

class _EstimateReviewScreenState extends ConsumerState<EstimateReviewScreen> {
  bool _submitting = false;

  Future<void> _respond(bool approve) async {
    setState(() => _submitting = true);
    try {
      final estimate = (await ref.read(estimateForRequestProvider(widget.requestId).future))!;
      if (approve) {
        await ref.read(financeRepositoryProvider).approveEstimate(estimate.id);
      } else {
        await ref.read(financeRepositoryProvider).rejectEstimate(estimate.id);
      }
      ref.invalidate(estimateForRequestProvider(widget.requestId));
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      ref.invalidate(myServiceRequestsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimate = ref.watch(estimateForRequestProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Review Estimate'), centerTitle: false, backgroundColor: AppColors.neutral100, surfaceTintColor: AppColors.neutral100),
      body: estimate.when(
        data: (e) {
          if (e == null) return const Center(child: Text('No estimate found for this request yet.', style: TextStyle(color: AppColors.neutral500)));
          final canRespond = e.status == 'SHARED';
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      StatusBadge(status: e.status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: ListView.separated(
                      itemCount: e.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 20, color: AppColors.neutral200),
                      itemBuilder: (context, i) {
                        final item = e.items[i];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${item.qty.toStringAsFixed(0)} x ₹${item.unitPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('₹${item.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _totalRow('Subtotal', e.subtotal),
                      if (e.discount > 0) _totalRow('Discount', -e.discount),
                      const Divider(color: AppColors.neutral200),
                      _totalRow('Total', e.total, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (canRespond)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size.fromHeight(48)),
                          onPressed: _submitting ? null : () => _respond(false),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : () => _respond(true),
                          icon: _submitting
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check, size: 18),
                          label: Text(_submitting ? 'Submitting...' : 'Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load estimate: $err')),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.black : AppColors.neutral500, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: bold ? 17 : 14, color: bold ? AppColors.black : AppColors.neutral900),
          ),
        ],
      ),
    );
  }
}
