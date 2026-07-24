import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_product_sheet.dart';
import 'address_select_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Product Select/Add,
// Stage 1 of docs/manish/06-complete-workflow-document.md.
class ProductSelectScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const ProductSelectScreen({super.key, required this.draft});

  @override
  ConsumerState<ProductSelectScreen> createState() => _ProductSelectScreenState();
}

class _ProductSelectScreenState extends ConsumerState<ProductSelectScreen> {
  String? _selectedProductId;

  void _proceed(String? productId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddressSelectScreen(draft: widget.draft.copyWith(customerProductId: productId)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(customerProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Select Appliance'), centerTitle: false),
      body: products.when(
        data: (items) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Which appliance needs ${widget.draft.serviceName}?', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ...items.map((p) => _ProductTile(
                          title: '${p.brandLabel} ${p.productTypeLabel}',
                          subtitle: p.modelNumber,
                          selected: _selectedProductId == p.id,
                          onTap: () => setState(() => _selectedProductId = p.id),
                        )),
                    _ProductTile(
                      title: 'Add a new appliance',
                      icon: Icons.add,
                      selected: false,
                      onTap: () => _showAddProductSheet(context),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _proceed(null),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selectedProductId == null ? null : () => _proceed(_selectedProductId),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load your appliances: $err')),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AddProductSheet(
        onAdded: () {
          Navigator.of(sheetContext).pop();
          ref.invalidate(customerProductsProvider);
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _ProductTile({required this.title, this.subtitle, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.black : AppColors.neutral200, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon ?? Icons.build_outlined, color: AppColors.neutral500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty) Text(subtitle!, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.black, size: 20),
          ],
        ),
      ),
    );
  }
}
