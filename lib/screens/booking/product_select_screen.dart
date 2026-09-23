import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import '../../widgets/add_product_sheet.dart';
import 'address_select_screen.dart';
import '../../widgets/state_views.dart';

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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Gradient matching the UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6EAF6),
                    Color(0xFFECF1FD),
                    Color(0xFFFAFAFA),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header (Back Button & Title) ---
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, color: Color(0xFF16A34A), size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('Select Appliance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Step 1 ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                            TextSpan(text: 'of 5', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
                          ]
                        )
                      ),
                    ],
                  ),
                ),

                // --- Progress ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1 / 5,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Question Card ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.devices_other_rounded, color: Color(0xFF16A34A), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Which appliance needs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
                            Text('${widget.draft.serviceName}?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), height: 1.2)),
                            const SizedBox(height: 6),
                            const Text('Choose your appliance from the list below', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // --- Product List ---
                Expanded(
                  child: products.when(
                    data: (items) => ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: AppErrorView(error: err, onRetry: () => ref.invalidate(customerProductsProvider)),
                    ),
                  ),
                ),

                // --- Sticky Bottom Action ---
                if (products.hasValue)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _proceed(null),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectedProductId == null ? null : () => _proceed(_selectedProductId),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedProductId != null ? const Color(0xFF16A34A) : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final isAddNew = icon == Icons.add;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF16A34A) : Colors.grey.shade200, 
          width: selected ? 1.5 : 1
        ),
        boxShadow: [
          if (!selected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image / Icon Box
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isAddNew ? const Color(0xFFFAFAFA) : const Color(0xFFF0FDF4).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: isAddNew ? Border.all(color: Colors.grey.shade300, style: BorderStyle.none) : null,
                    ),
                    alignment: Alignment.center,
                    // Note: Dashed border for Add New would require a custom painter or package.
                    // Using a light container instead for simplicity.
                    child: isAddNew
                        ? const Icon(Icons.add, color: Color(0xFF16A34A), size: 24)
                        : const Icon(Icons.ac_unit, color: Colors.black38, size: 28),
                  ),
                  if (selected)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    const SizedBox(height: 6),
                    if (!isAddNew) // "Saved Appliance" tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings_suggest_outlined, color: Color(0xFF16A34A), size: 14),
                            const SizedBox(width: 4),
                            const Text('Saved Appliance', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      const Text('Enter appliance details manually', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
