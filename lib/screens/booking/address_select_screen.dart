import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/booking_models.dart';
import '../../models/customer_models.dart';
import '../../providers/booking_providers.dart';
import '../../providers/customer_providers.dart';
import '../../providers/geo_providers.dart';
import 'issue_description_screen.dart';
import '../../widgets/state_views.dart';

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
      backgroundColor: const Color(0xFFF6F7F9),
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
                    Color(0xFFE8F6EC),
                    Color(0xFFF2F8F3),
                    Color(0xFFF6F7F9),
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
                        if (_selectedAddressId != null)
                          _SelectedAddressSummary(
                            address: customer.addresses.firstWhere(
                              (a) => a.id == _selectedAddressId,
                              orElse: () => customer.addresses.first,
                            ),
                          ),
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
                    error: (err, _) => Center(
                      child: AppErrorView(error: err, onRetry: () => ref.invalidate(myProfileProvider)),
                    ),
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
  final _labelController = TextEditingController(text: 'Home');
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  bool _saving = false;
  bool _lookingUpPin = false;
  bool _detectingLocation = false;
  String? _error;
  String? _pinNotice;
  String _lastLookedUpPin = '';

  @override
  void initState() {
    super.initState();
    _pinCodeController.addListener(_onPinChanged);
  }

  // GET /geo/pincode/:pincode resolves city/state (and whether we even cover
  // the area) from the PIN — the user used to have to type both by hand, and
  // a typo there is exactly what makes a request land on the wrong branch.
  void _onPinChanged() {
    final pin = _pinCodeController.text.trim();
    if (pin.length != 6 || pin == _lastLookedUpPin) return;
    _lastLookedUpPin = pin;
    _lookupPin(pin);
  }

  Future<void> _lookupPin(String pin) async {
    setState(() {
      _lookingUpPin = true;
      _pinNotice = null;
    });
    final area = await ref.read(geoRepositoryProvider).lookupPincode(pin);
    if (!mounted || _pinCodeController.text.trim() != pin) return;
    setState(() {
      _lookingUpPin = false;
      if (area == null) {
        _pinNotice = null;
        return;
      }
      // Only fill blanks — never overwrite something the user typed
      // themselves, since the lookup is a convenience, not an authority.
      if (area.resolvedCity != null) {
        _cityController.text = area.resolvedCity!;
      }
      if (area.state != null) {
        _stateController.text = area.state!;
      }
      _pinNotice = area.serviceable
          ? 'We serve this area${area.branchName != null ? ' · ${area.branchName}' : ''}'
          : "We don't cover this PIN code yet — you can still save the address.";
    });
  }

  @override
  void dispose() {
    _pinCodeController.removeListener(_onPinChanged);
    _labelController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _detectingLocation = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _error = 'Turn on location services, then try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission is needed to use current location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (!mounted) return;
      if (placemarks.isEmpty) {
        setState(() => _error = 'Could not read this location. Please enter it manually.');
        return;
      }

      final p = placemarks.first;
      final lineParts = [
        p.name,
        p.street,
      ].where((s) => s != null && s.trim().isNotEmpty).cast<String>().toSet();
      final areaParts = [
        p.subLocality,
        p.locality,
      ].where((s) => s != null && s.trim().isNotEmpty).cast<String>().toSet();

      setState(() {
        if (_line1Controller.text.trim().isEmpty) {
          _line1Controller.text = lineParts.isEmpty
              ? 'Current location'
              : lineParts.join(', ');
        }
        if (_line2Controller.text.trim().isEmpty && areaParts.isNotEmpty) {
          _line2Controller.text = areaParts.join(', ');
        }
        if (_cityController.text.trim().isEmpty) {
          _cityController.text = p.locality?.trim().isNotEmpty == true
              ? p.locality!.trim()
              : (p.subAdministrativeArea ?? '').trim();
        }
        if (_stateController.text.trim().isEmpty) {
          _stateController.text = (p.administrativeArea ?? '').trim();
        }
        if (_pinCodeController.text.trim().isEmpty &&
            (p.postalCode ?? '').trim().length >= 6) {
          _pinCodeController.text = p.postalCode!.trim().substring(0, 6);
        }
        if (_landmarkController.text.trim().isEmpty) {
          _landmarkController.text =
              'Map: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not fetch current location. Please enter it manually.');
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final address = AddressDraft(
      label: _labelController.text.trim(),
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
              const Text('Add New Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Save this service location and continue booking.',
                style: TextStyle(color: Colors.black54, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _detectingLocation ? null : _useCurrentLocation,
                icon: _detectingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(_detectingLocation
                    ? 'Detecting location...'
                    : 'Use current location'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFF16A34A)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Address label'),
              ),
              const SizedBox(height: 10),
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
              TextFormField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN Code',
                  counterText: '',
                  helperText: 'City and state fill in automatically',
                  suffixIcon: _lookingUpPin
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid 6-digit PIN code' : null,
              ),
              if (_pinNotice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    _pinNotice!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _pinNotice!.startsWith('We serve') ? const Color(0xFF16A34A) : Colors.orange.shade800,
                    ),
                  ),
                ),
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
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Address & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedAddressSummary extends StatelessWidget {
  final CustomerAddress address;
  const _SelectedAddressSummary({required this.address});

  @override
  Widget build(BuildContext context) {
    final title = address.label?.trim().isNotEmpty == true
        ? address.label!.trim()
        : 'Selected address';
    final line = [
      address.line1,
      address.line2,
      address.landmark,
      address.city,
      address.state,
      address.pinCode,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>().join(', ');

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Using $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
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
                        [address!.line1, address!.city, address!.pinCode].where((s) => s != null && s.isNotEmpty).join(', '),
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

