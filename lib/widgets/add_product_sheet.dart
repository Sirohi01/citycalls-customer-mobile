import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_providers.dart';
import '../providers/customer_providers.dart';

// Shared "Add Appliance" bottom sheet — used by both the Booking flow's
// Product Select screen and the standalone Saved Products screen (Profile),
// so the form can't drift between the two entry points. The sheet's white
// rounded surface and drag handle come from the app's bottomSheetTheme, so
// callers must not override the sheet background.
class AddProductSheet extends ConsumerStatefulWidget {
  // Called with the new appliance's id (null if the server didn't return one).
  final ValueChanged<String?> onAdded;
  const AddProductSheet({super.key, required this.onAdded});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  static const _green = Color(0xFF16A34A);

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
    if (_productTypeId == null || _brandId == null) {
      setState(() => _error = 'Select the appliance type and its brand.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final customerId = (await ref.read(myProfileProvider.future)).id;
      final newId = await ref.read(bookingRepositoryProvider).addProduct(
            customerId,
            brandId: _brandId!,
            productTypeId: _productTypeId!,
            modelNumber: _modelController.text.trim(),
          );
      widget.onAdded(newId);
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't save the appliance. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Keeps the field's footprint while the list loads, instead of a bare
  // progress bar that makes the form jump when the dropdown appears.
  Widget _loadingField(String label, IconData icon) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: const SizedBox(
        height: 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items,
      onChanged: _saving ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final productTypes = ref.watch(productTypesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.devices_other_rounded,
                      color: _green, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Appliance',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Tell us which appliance needs service',
                          style: TextStyle(
                              fontSize: 12.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            productTypes.when(
              data: (items) => _dropdown(
                label: 'Appliance type',
                icon: Icons.category_outlined,
                value: _productTypeId,
                items: items
                    .map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.label)))
                    .toList(),
                onChanged: (v) => setState(() => _productTypeId = v),
              ),
              loading: () =>
                  _loadingField('Appliance type', Icons.category_outlined),
              error: (_, __) => _LoadFailed(
                what: 'appliance types',
                onRetry: () => ref.invalidate(productTypesProvider),
              ),
            ),
            const SizedBox(height: 14),
            brands.when(
              data: (items) => _dropdown(
                label: 'Brand',
                icon: Icons.sell_outlined,
                value: _brandId,
                items: items
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.label)))
                    .toList(),
                onChanged: (v) => setState(() => _brandId = v),
              ),
              loading: () => _loadingField('Brand', Icons.sell_outlined),
              error: (_, __) => _LoadFailed(
                what: 'brands',
                onRetry: () => ref.invalidate(brandsProvider),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _modelController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Model number (optional)',
                helperText: 'Printed on the label at the back or side',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFB91C1C), fontSize: 12.5)),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save appliance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final String what;
  final VoidCallback onRetry;
  const _LoadFailed({required this.what, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text("Couldn't load $what.",
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
