import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/add_product_sheet.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Profile" — Saved Products.
class SavedProductsScreen extends ConsumerWidget {
  const SavedProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(customerProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Saved Appliances'), centerTitle: false),
      body: products.when(
        data: (items) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (sheetContext) => AddProductSheet(
                    onAdded: () {
                      Navigator.of(sheetContext).pop();
                      ref.invalidate(customerProductsProvider);
                    },
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Appliance'),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const Text('No saved appliances yet.', style: TextStyle(color: AppColors.neutral500))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.neutral200), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.build_outlined, color: AppColors.neutral500),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${p.brandLabel} ${p.productTypeLabel}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (p.modelNumber != null && p.modelNumber!.isNotEmpty)
                                    Text(p.modelNumber!, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load your appliances: $err')),
      ),
    );
  }
}
