import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../models/customer_models.dart';
import '../../providers/booking_providers.dart';
import '../../providers/customer_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_step_header.dart';
import 'issue_description_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Address Select/Add.
class AddressSelectScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const AddressSelectScreen({super.key, required this.draft});

  @override
  ConsumerState<AddressSelectScreen> createState() => _AddressSelectScreenState();
}

class _AddressSelectScreenState extends ConsumerState<AddressSelectScreen> {
  String? _selectedAddressId;

  void _proceed(AddressDraft address) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => IssueDescriptionScreen(draft: widget.draft.copyWith(address: address)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Select Address'), centerTitle: false),
      body: profile.when(
        data: (customer) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookingStepHeader(step: 2, totalSteps: 5, title: 'Where should the technician visit?'),
              Expanded(
                child: ListView(
                  children: [
                    ...customer.addresses.map((a) => _AddressTile(
                          address: a,
                          selected: _selectedAddressId == a.id,
                          onTap: () => setState(() => _selectedAddressId = a.id),
                        )),
                    Material(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.04),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showAddAddressSheet(context, customer.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Add a new address', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _selectedAddressId == null
                    ? null
                    : () {
                        final a = customer.addresses.firstWhere((a) => a.id == _selectedAddressId);
                        _proceed(AddressDraft(label: a.label, line1: a.line1 ?? '', line2: a.line2, landmark: a.landmark, city: a.city, state: a.state, pinCode: a.pinCode));
                      },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load your addresses: $err')),
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, String customerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddAddressSheet(
        onSaved: (address) {
          Navigator.of(sheetContext).pop();
          ref.invalidate(myProfileProvider);
          _proceed(address);
        },
        customerId: customerId,
      ),
    );
  }
}

class _AddAddressSheet extends ConsumerStatefulWidget {
  final String customerId;
  final void Function(AddressDraft) onSaved;
  const _AddAddressSheet({required this.customerId, required this.onSaved});

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final address = AddressDraft(
      line1: _line1Controller.text.trim(),
      line2: _line2Controller.text.trim(),
      landmark: _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
    );
    try {
      await ref.read(bookingRepositoryProvider).addAddress(widget.customerId, address);
      widget.onSaved(address);
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _line1Controller,
              decoration: const InputDecoration(labelText: 'House / Flat / Street'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _line2Controller, decoration: const InputDecoration(labelText: 'Area (optional)')),
            const SizedBox(height: 10),
            TextFormField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Landmark (optional)')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pinCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN Code'),
              validator: (v) => (v == null || v.trim().length < 4) ? 'Enter a valid PIN code' : null,
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final CustomerAddress address;
  final bool selected;
  final VoidCallback onTap;
  const _AddressTile({required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary.withValues(alpha: 0.05) : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? primary : Colors.transparent, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_outlined, color: AppColors.neutral500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  [address.label, address.line1, address.city, address.state, address.pinCode].where((s) => s != null && s.isNotEmpty).join(', '),
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
