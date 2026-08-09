import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_providers.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class ProformaReviewScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ProformaReviewScreen({super.key, required this.requestId});

  @override
  ConsumerState<ProformaReviewScreen> createState() =>
      _ProformaReviewScreenState();
}

class _ProformaReviewScreenState extends ConsumerState<ProformaReviewScreen> {
  bool _submitting = false;

  Future<void> _accept() async {
    setState(() => _submitting = true);
    try {
      final proforma = (await ref
          .read(proformaForRequestProvider(widget.requestId).future))!;
      await ref.read(financeRepositoryProvider).acceptProforma(proforma.id);
      ref.invalidate(proformaForRequestProvider(widget.requestId));
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      ref.invalidate(myServiceRequestsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proforma = ref.watch(proformaForRequestProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
          title: const Text('Review Bill'),
          centerTitle: false,
          backgroundColor: AppColors.neutral100,
          surfaceTintColor: AppColors.neutral100),
      body: proforma.when(
        data: (p) {
          if (p == null)
            return const Center(
                child: Text('No bill found for this request yet.',
                    style: TextStyle(color: AppColors.neutral500)));
          final canAccept = p.status == 'SHARED';
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
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
                        child: Icon(Icons.request_quote_outlined,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(p.number,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold))),
                      StatusBadge(status: p.status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This matches the estimate you already approved — one last confirmation before it becomes your final bill.',
                  style: TextStyle(color: AppColors.neutral500, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: p.items.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 20, color: AppColors.neutral200),
                      itemBuilder: (context, i) {
                        final item = p.items[i];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '${item.qty.toStringAsFixed(0)} x ₹${item.unitPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.neutral500,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('₹${item.lineTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      _totalRow('Subtotal', p.subtotal),
                      if (p.discount > 0) _totalRow('Discount', -p.discount),
                      const Divider(color: AppColors.neutral200),
                      _totalRow('Total', p.total, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (canAccept)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _accept,
                      icon: _submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 18),
                      label:
                          Text(_submitting ? 'Submitting...' : 'Accept Bill'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load bill: $err')),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? AppColors.black : AppColors.neutral500,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: bold ? 17 : 14,
                color: bold ? AppColors.black : AppColors.neutral900),
          ),
        ],
      ),
    );
  }
}
