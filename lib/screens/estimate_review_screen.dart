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
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Review Estimate'), centerTitle: false),
      body: estimate.when(
        data: (e) {
          if (e == null) return const Center(child: Text('No estimate found for this request yet.', style: TextStyle(color: AppColors.neutral500)));
          final canRespond = e.status == 'SHARED';
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    StatusBadge(status: e.status),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
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
                const Divider(color: AppColors.neutral200),
                _totalRow('Subtotal', e.subtotal),
                if (e.discount > 0) _totalRow('Discount', -e.discount),
                _totalRow('Total', e.total, bold: true),
                const SizedBox(height: 20),
                if (canRespond)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          onPressed: _submitting ? null : () => _respond(false),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting ? null : () => _respond(true),
                          child: _submitting
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Approve'),
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
