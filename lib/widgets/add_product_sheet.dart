import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_providers.dart';
import '../providers/customer_providers.dart';

// Shared "Add Appliance" bottom sheet — used by both the Booking flow's
// Product Select screen and the standalone Saved Products screen (Profile),
// so the form can't drift between the two entry points.
class AddProductSheet extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const AddProductSheet({super.key, required this.onAdded});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  String? _brandId;
  String? _productTypeId;
  final _modelController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_brandId == null || _productTypeId == null) {
      setState(() => _error = 'Select a brand and product type.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final customerId = (await ref.read(myProfileProvider.future)).id;
      await ref.read(bookingRepositoryProvider).addProduct(
            customerId,
            brandId: _brandId!,
            productTypeId: _productTypeId!,
            modelNumber: _modelController.text.trim(),
          );
      widget.onAdded();
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final productTypes = ref.watch(productTypesProvider);

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Appliance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          brands.when(
            data: (items) => DropdownButtonFormField<String>(
              value: _brandId,
              decoration: const InputDecoration(labelText: 'Brand'),
              items: items.map((b) => DropdownMenuItem(value: b.id, child: Text(b.label))).toList(),
              onChanged: (v) => setState(() => _brandId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load brands'),
          ),
          const SizedBox(height: 12),
          productTypes.when(
            data: (items) => DropdownButtonFormField<String>(
              value: _productTypeId,
              decoration: const InputDecoration(labelText: 'Product Type'),
              items: items.map((p) => DropdownMenuItem(value: p.id, child: Text(p.label))).toList(),
              onChanged: (v) => setState(() => _productTypeId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load product types'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model Number (optional)')),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
