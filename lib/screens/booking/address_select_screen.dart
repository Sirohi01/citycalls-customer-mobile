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
                          const Text('Select Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Step 2 ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
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
                          value: 2 / 5,
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
                        child: const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Where should the', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
                            const Text('technician visit?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), height: 1.2)),
                            const SizedBox(height: 6),
                            const Text('Choose an address from the list below', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // --- Address List ---
                Expanded(
                  child: profile.when(
                    data: (customer) => ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      children: [
                        ...customer.addresses.map((a) => _AddressTile(
                              address: a,
                              selected: _selectedAddressId == a.id,
                              onTap: () => setState(() => _selectedAddressId = a.id),
                            )),
                        _AddressTile(
                          address: null, // Add new address
                          selected: false,
                          onTap: () => _showAddAddressSheet(context, customer.id),
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Failed to load your addresses: $err')),
                  ),
                ),

                // --- Sticky Bottom Action ---
                if (profile.hasValue)
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
                            onTap: _selectedAddressId == null
                                ? null
                                : () {
                                    final customer = profile.value!;
                                    final a = customer.addresses.firstWhere((a) => a.id == _selectedAddressId);
                                    _proceed(AddressDraft(label: a.label, line1: a.line1 ?? '', line2: a.line2, landmark: a.landmark, city: a.city, state: a.state, pinCode: a.pinCode));
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedAddressId != null ? const Color(0xFF16A34A) : Colors.grey.shade400,
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

  void _showAddAddressSheet(BuildContext context, String customerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
      child: SingleChildScrollView(
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
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final CustomerAddress? address;
  final bool selected;
  final VoidCallback onTap;
  const _AddressTile({required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAddNew = address == null;

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
                    child: isAddNew
                        ? const Icon(Icons.add, color: Color(0xFF16A34A), size: 24)
                        : const Icon(Icons.location_on, color: Colors.black38, size: 28),
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
                    Text(
                      isAddNew ? 'Add a new address' : address!.label ?? 'Home',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                    ),
                    const SizedBox(height: 6),
                    if (!isAddNew)
                      Text(
                        [address!.line1, address!.city, address!.pinCode].where((s) => s != null && s!.isNotEmpty).join(', '),
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text('Enter address details manually', style: TextStyle(color: Colors.black54, fontSize: 12)),
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
